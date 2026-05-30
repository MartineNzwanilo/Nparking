"use client"

import React, { useEffect, useRef, useState } from "react"
import { cn } from "@/lib/utils"

interface CameraPlayerProps {
  streamUrl: string
  name: string
  siteName?: string
  onFullscreen?: () => void
  isFullscreen?: boolean
}

export function CameraPlayer({ streamUrl, name, siteName, onFullscreen, isFullscreen }: CameraPlayerProps) {
  const videoRef = useRef<HTMLVideoElement>(null)
  const imgRef = useRef<HTMLImageElement>(null)
  const [error, setError] = useState(false)
  const [isMjpeg, setIsMjpeg] = useState(false)
  
  // Real-time AI overlay state
  const [frameData, setFrameData] = useState<any>(null)

  useEffect(() => {
    if (!streamUrl) return
    setError(false)

    if (streamUrl.includes("/video") || streamUrl.endsWith(".mjpg")) {
      setIsMjpeg(true)
      return
    }

    let hls: any = null
    const initHls = async () => {
      const Hls = (await import("hls.js")).default
      if (Hls.isSupported() && videoRef.current) {
        hls = new Hls({ enableWorker: false })
        hls.loadSource(streamUrl)
        hls.attachMedia(videoRef.current)
        hls.on(Hls.Events.ERROR, () => setError(true))
      } else if (videoRef.current?.canPlayType("application/vnd.apple.mpegurl")) {
        videoRef.current.src = streamUrl
      }
    }
    initHls()

    return () => { if (hls) hls.destroy() }
  }, [streamUrl])

  useEffect(() => {
    const wsUrl = `ws://${window.location.hostname}:8000/ws`
    const ws = new WebSocket(wsUrl)
    ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data)
        if (data.type === "frame" && data.streamUrl === streamUrl) {
           if (data.frame) {
             setFrameData(data)
           }
        }
      } catch (e) {}
    }
    return () => ws.close()
  }, [streamUrl])

  return (
    <div 
      className={cn(
        "relative w-full rounded-2xl overflow-hidden bg-black group border border-border/50 cursor-pointer select-none",
        isFullscreen ? "h-full" : "aspect-video"
      )}
      onClick={onFullscreen}
    >
      <div className="absolute top-3 left-3 z-20 flex items-center gap-2">
        <div className="flex items-center gap-2 px-2.5 py-1 rounded-lg bg-black/60 backdrop-blur-md border border-white/10">
          <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
          <span className="text-[10px] font-black uppercase tracking-widest text-white">{name}</span>
        </div>
      </div>

      <div className="absolute top-3 right-3 z-20">
        <div className="flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-black/60 backdrop-blur-md border border-red-500/30">
          <span className="w-1.5 h-1.5 rounded-full bg-red-500 animate-pulse" />
          <span className="text-[9px] font-black uppercase tracking-widest text-red-500">REC</span>
        </div>
      </div>

      {error ? (
        <div className="absolute inset-0 flex flex-col items-center justify-center bg-black/90">
          <div className="w-10 h-10 rounded-full bg-red-500/20 flex items-center justify-center mb-3">
            <span className="text-red-500 text-xl font-black">X</span>
          </div>
          <span className="text-[11px] font-black uppercase tracking-widest text-red-500">No Signal</span>
        </div>
      ) : isMjpeg ? (
        <img
          ref={imgRef}
          src={frameData ? `data:image/jpeg;base64,${frameData.frame}` : streamUrl}
          alt={name}
          className="w-full h-full object-cover"
          onError={() => setError(true)}
        />
      ) : (
        <video
          ref={videoRef}
          className="w-full h-full object-cover"
          autoPlay muted playsInline
        />
      )}

      {/* AI Bounding Boxes Overlay */}
      {frameData?.detections?.map((det: any, i: number) => {
        const [x1, y1, x2, y2] = det.bbox
        const scaleX = 100 / 640 
        const scaleY = 100 / 480 
        
        return (
          <div key={i} className="absolute border-2 border-emerald-500 bg-emerald-500/10 transition-all duration-75 pointer-events-none z-30"
            style={{
              left: `${x1 * scaleX}%`, top: `${y1 * scaleY}%`,
              width: `${(x2 - x1) * scaleX}%`, height: `${(y2 - y1) * scaleY}%`
            }}>
            <div className="absolute -top-5 left-[-2px] bg-emerald-500 text-white text-[9px] font-black px-1.5 py-0.5 whitespace-nowrap">
              {det.vehicleType.toUpperCase()} {(det.confidence * 100).toFixed(0)}%
              {det.plate && ` • ${det.plate}`}
            </div>
          </div>
        )
      })}
    </div>
  )
}
