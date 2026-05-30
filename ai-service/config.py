import os

# ── NestJS Backend ────────────────────────────────────────────────────────────
NESTJS_BASE_URL = os.getenv("NESTJS_URL", "http://localhost:3000")
NESTJS_DETECTION_ENDPOINT = f"{NESTJS_BASE_URL}/api/detections"
NESTJS_API_TOKEN = os.getenv("AI_SERVICE_TOKEN", "ai-service-internal-token")

# ── AI Settings ───────────────────────────────────────────────────────────────
YOLO_MODEL = "yolov8n.pt"           # Nano model — fastest for CPU
DETECTION_INTERVAL = 0.5            # Seconds between detection runs (2 FPS)
MIN_CONFIDENCE = 0.45               # YOLO confidence threshold
PLATE_MIN_CONFIDENCE = 0.25         # OCR confidence threshold

# Vehicle classes in YOLO COCO dataset
VEHICLE_CLASSES = {2: "car", 3: "motorcycle", 5: "bus", 7: "truck"}

# ── Plate regex patterns (Tanzania format + generic) ─────────────────────────
import re

PLATE_PATTERNS = [
    re.compile(r'\b[A-Z]{1,3}\s?\d{3,4}\s?[A-Z]{0,3}\b'),   # T123ABC
    re.compile(r'\b[A-Z]{2,3}\s?\d{4}\s?[A-Z]{1,2}\b'),      # EE5435T6 style
    re.compile(r'\b\d{1,4}[\s-]?[A-Z]{1,4}[\s-]?\d{0,4}\b'),  # Mixed
]

def extract_plate(text: str) -> str | None:
    text = text.upper().replace(' ', '').replace('-', '')
    import re
    
    # Strict regex search for common plates (allows extracting the perfect plate even if OCR saw garbage on the edges)
    # Tanzanian: T123ABC (T + 3 digits + 3 letters)
    match_tz = re.search(r'T[0-9]{3}[A-Z]{3}', text)
    if match_tz:
        return match_tz.group(0)
        
    # UK: AB12CDE (2 letters + 2 digits + 3 letters)
    match_uk = re.search(r'[A-Z]{2}[0-9]{2}[A-Z]{3}', text)
    if match_uk:
        return match_uk.group(0)
        
    return None
