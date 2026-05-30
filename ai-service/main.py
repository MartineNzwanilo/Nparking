c"""
main.py — Locomotors AI Detection Service
FastAPI + WebSocket server for vehicle & plate detection.
Run with: python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
"""
import logging
import asyncio
from contextlib import asynccontextmanager
from typing import Any

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, Header
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from detector import CameraStream
from config import NESTJS_API_TOKEN

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

# ── WebSocket connection manager ──────────────────────────────────────────────
class ConnectionManager:
    def __init__(self):
        self.active: list[WebSocket] = []

    async def connect(self, ws: WebSocket):
        await ws.accept()
        self.active.append(ws)
        logger.info(f"WS client connected. Total: {len(self.active)}")

    def disconnect(self, ws: WebSocket):
        if ws in self.active:
            self.active.remove(ws)
        logger.info(f"WS client disconnected. Total: {len(self.active)}")

    async def broadcast(self, data: dict):
        import json
        dead = []
        for ws in self.active:
            try:
                await ws.send_text(json.dumps(data))
            except Exception:
                dead.append(ws)
        for ws in dead:
            self.disconnect(ws)


manager = ConnectionManager()
streams: dict[str, CameraStream] = {}   # cameraId → CameraStream
main_loop = None

def on_detection_event(event: dict):
    """Called from detector thread → schedule WS broadcast on event loop."""
    global main_loop
    if main_loop and main_loop.is_running():
        asyncio.run_coroutine_threadsafe(manager.broadcast(event), main_loop)


# ── FastAPI app ───────────────────────────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    global main_loop
    main_loop = asyncio.get_running_loop()
    logger.info("🚗 Locomotors AI Service starting up...")
    yield
    logger.info("Shutting down — stopping all streams...")
    for stream in streams.values():
        stream.stop()


app = FastAPI(title="Locomotors AI Detection Service", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Models ────────────────────────────────────────────────────────────────────
class StartStreamRequest(BaseModel):
    cameraId: str
    streamUrl: str
    cameraName: str = "Unknown Camera"


# ── Routes ────────────────────────────────────────────────────────────────────
@app.get("/")
def root():
    return {"service": "Locomotors AI Detection", "status": "running",
            "active_streams": len(streams)}


@app.get("/status")
def status():
    return {
        "status": "ok",
        "active_streams": [
            {"cameraId": cid, "url": s.stream_url, "running": s.running}
            for cid, s in streams.items()
        ]
    }


@app.post("/streams/start")
def start_stream(req: StartStreamRequest):
    if req.cameraId in streams and streams[req.cameraId].running:
        return {"message": f"Stream {req.cameraId} already running"}

    stream = CameraStream(
        camera_id=req.cameraId,
        stream_url=req.streamUrl,
        on_event=on_detection_event,
    )
    streams[req.cameraId] = stream
    stream.start()
    return {"message": f"Stream {req.cameraId} started", "url": req.streamUrl}


@app.post("/streams/stop")
def stop_stream(camera_id: str):
    if camera_id not in streams:
        raise HTTPException(status_code=404, detail="Stream not found")
    streams[camera_id].stop()
    del streams[camera_id]
    return {"message": f"Stream {camera_id} stopped"}


@app.delete("/streams")
def stop_all():
    for stream in streams.values():
        stream.stop()
    streams.clear()
    return {"message": "All streams stopped"}


# ── WebSocket endpoint ────────────────────────────────────────────────────────
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        # Send welcome + current stream status
        await websocket.send_json({
            "type": "connected",
            "message": "Locomotors AI Service connected",
            "active_streams": len(streams)
        })
        # Keep connection alive — listen for client messages (e.g. ping)
        while True:
            try:
                data = await asyncio.wait_for(websocket.receive_text(), timeout=30)
                if data == "ping":
                    await websocket.send_text("pong")
            except asyncio.TimeoutError:
                await websocket.send_text("pong")  # keepalive
    except WebSocketDisconnect:
        manager.disconnect(websocket)
