"""
detector.py — YOLOv8 vehicle detection + EasyOCR plate reading
Runs in a background thread per camera stream.
"""
import cv2
import time
import base64
import logging
import threading
import numpy as np
from datetime import datetime
from typing import Callable
import httpx

from config import (
    YOLO_MODEL, DETECTION_INTERVAL, MIN_CONFIDENCE,
    VEHICLE_CLASSES, NESTJS_DETECTION_ENDPOINT,
    NESTJS_API_TOKEN, extract_plate
)

logger = logging.getLogger(__name__)

# ── Lazy-load heavy models once ───────────────────────────────────────────────
_yolo_model = None
_ocr_reader = None
_model_lock = threading.Lock()


def get_yolo():
    global _yolo_model
    with _model_lock:
        if _yolo_model is None:
            logger.info("Loading YOLOv8n model (first time — may download ~6MB)...")
            from ultralytics import YOLO
            _yolo_model = YOLO(YOLO_MODEL)
            logger.info("YOLOv8n loaded ✓")
    return _yolo_model


def get_ocr():
    global _ocr_reader
    with _model_lock:
        if _ocr_reader is None:
            logger.info("Loading EasyOCR (first time — may download ~100MB)...")
            import easyocr
            _ocr_reader = easyocr.Reader(['en'], gpu=False, verbose=False)
            logger.info("EasyOCR loaded ✓")
    return _ocr_reader


# ── Per-camera stream processor ───────────────────────────────────────────────
class CameraStream:
    def __init__(self, camera_id: str, stream_url: str, on_event: Callable):
        self.camera_id = camera_id
        self.stream_url = stream_url
        self.on_event = on_event          # callback to broadcast via WebSocket
        self.running = False
        self.thread: threading.Thread | None = None
        self.last_plates: dict[str, float] = {}  # plate → last_reported_time
        self.cooldown = 30.0              # seconds between same-plate detections

    def start(self):
        self.running = True
        self.thread = threading.Thread(target=self._run, daemon=True)
        self.thread.start()
        logger.info(f"Stream started: {self.camera_id} @ {self.stream_url}")

    def stop(self):
        self.running = False
        if self.thread:
            self.thread.join(timeout=3)
        logger.info(f"Stream stopped: {self.camera_id}")

    def _run(self):
        yolo = get_yolo()
        ocr = get_ocr()

        cap = cv2.VideoCapture(self.stream_url)
        # Try to minimize internal buffer
        cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)

        if not cap.isOpened():
            logger.error(f"Cannot open stream: {self.stream_url}")
            self.on_event({"type": "stream_error", "cameraId": self.camera_id,
                           "message": "Cannot connect to stream"})
            return

        # Shared state for the latest frame
        self.latest_frame = None
        
        # Dedicated thread to constantly pull frames and clear the buffer
        def grab_frames():
            while self.running:
                ret, frame = cap.read()
                if ret:
                    self.latest_frame = frame
                else:
                    time.sleep(1)
                    # Reconnect if stream drops
                    cap.open(self.stream_url)

        grab_thread = threading.Thread(target=grab_frames, daemon=True)
        grab_thread.start()

        while self.running:
            start_time = time.time()
            
            frame = self.latest_frame
            if frame is not None:
                # Resize for speed (640px max)
                h, w = frame.shape[:2]
                if w > 640:
                    scale = 640 / w
                    frame = cv2.resize(frame, (640, int(h * scale)))

                detections = self._detect(yolo, ocr, frame, start_time)

                # Encode frame as base64 JPEG for WebSocket broadcast
                _, buf = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 70])
                frame_b64 = base64.b64encode(buf).decode('utf-8')

                self.on_event({
                    "type": "frame",
                    "cameraId": self.camera_id,
                    "streamUrl": self.stream_url,
                    "frame": frame_b64,
                    "detections": detections,
                    "ts": datetime.utcnow().isoformat()
                })

            # Wait exactly DETECTION_INTERVAL before processing the next frame
            elapsed = time.time() - start_time
            sleep_time = max(0.01, DETECTION_INTERVAL - elapsed)
            time.sleep(sleep_time)

        cap.release()

    def _detect(self, yolo, ocr, frame, now: float) -> list:
        results = yolo(frame, conf=MIN_CONFIDENCE, classes=list(VEHICLE_CLASSES.keys()),
                       verbose=False)[0]
        detections = []

        for box in results.boxes:
            cls_id = int(box.cls[0])
            conf = float(box.conf[0])
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            vehicle_type = VEHICLE_CLASSES.get(cls_id, "vehicle")

            detection = {
                "vehicleType": vehicle_type,
                "confidence": round(conf, 3),
                "bbox": [x1, y1, x2, y2],
                "plate": None
            }

            # ── Try to read plate from lower portion of vehicle bbox ──────────
            plate_region = self._get_plate_region(frame, x1, y1, x2, y2)
            if plate_region is not None:
                plate_text = self._read_plate(ocr, plate_region)
                if plate_text:
                    detection["plate"] = plate_text
                    # Report to NestJS if not in cooldown
                    last = self.last_plates.get(plate_text, 0)
                    if now - last > self.cooldown:
                        self.last_plates[plate_text] = now
                        self._report_plate(plate_text, vehicle_type, conf, frame, x1, y1, x2, y2)

            detections.append(detection)

        # ── TESTING FALLBACK: If no vehicles found, try reading the whole frame ──
        if len(detections) == 0:
            plate_text = self._read_plate(ocr, frame)
            if plate_text:
                last = self.last_plates.get(plate_text, 0)
                if now - last > self.cooldown:
                    self.last_plates[plate_text] = now
                    h, w = frame.shape[:2]
                    self._report_plate(plate_text, "test_plate", 1.0, frame, 0, 0, w, h)

        return detections

    def _get_plate_region(self, frame, x1, y1, x2, y2):
        """Crop the lower 35% of the vehicle bounding box (where the plate is)."""
        h = y2 - y1
        plate_y1 = y2 - int(h * 0.35)
        plate_region = frame[max(0, plate_y1):y2, max(0, x1):x2]
        if plate_region.size == 0:
            return None
        # Upscale for better OCR
        plate_region = cv2.resize(plate_region, None, fx=2, fy=2, interpolation=cv2.INTER_CUBIC)
        # Enhance contrast
        gray = cv2.cvtColor(plate_region, cv2.COLOR_BGR2GRAY)
        plate_region = cv2.equalizeHist(gray)
        return plate_region

    def _read_plate(self, ocr, region) -> str | None:
        """Run EasyOCR on the plate region and extract a valid plate string."""
        try:
            results = ocr.readtext(region, allowlist='ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ')
            best_plate = None
            best_conf = 0
            for (_, text, conf) in results:
                plate = extract_plate(text)
                if plate and conf > best_conf:
                    best_plate = plate
                    best_conf = conf
            return best_plate if best_conf > 0.25 else None
        except Exception as e:
            logger.debug(f"OCR error: {e}")
        return None

    def _report_plate(self, plate: str, vehicle_type: str, confidence: float,
                      frame, x1, y1, x2, y2):
        """POST detection result to NestJS backend."""
        # Crop vehicle for snapshot
        vehicle_crop = frame[max(0, y1):y2, max(0, x1):x2]
        _, buf = cv2.imencode('.jpg', vehicle_crop, [cv2.IMWRITE_JPEG_QUALITY, 85])
        snapshot_b64 = base64.b64encode(buf).decode('utf-8')

        payload = {
            "plate": plate,
            "cameraId": self.camera_id,
            "vehicleType": vehicle_type,
            "confidence": round(confidence, 3),
            "snapshot": snapshot_b64,
            "detectedAt": datetime.utcnow().isoformat(),
        }

        try:
            with httpx.Client(timeout=5) as client:
                resp = client.post(
                    NESTJS_DETECTION_ENDPOINT,
                    json=payload,
                    headers={"x-ai-token": NESTJS_API_TOKEN}
                )
                if resp.status_code == 200:
                    result = resp.json()
                    # Broadcast enriched event (with vehicle DB info) via WebSocket
                    self.on_event({
                        "type": "plate_detected",
                        "cameraId": self.camera_id,
                        "plate": plate,
                        "vehicleType": vehicle_type,
                        "confidence": round(confidence, 3),
                        "status": result.get("status"),          # CHECKED_IN | NOT_CHECKED_IN | BLACKLISTED | UNKNOWN
                        "vehicle": result.get("vehicle"),        # DB vehicle record
                        "snapshot": snapshot_b64,
                        "ts": datetime.utcnow().isoformat(),
                    })
        except Exception as e:
            logger.error(f"Failed to report plate {plate}: {e}")
