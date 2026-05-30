"use client"

import React, { useEffect, useState } from "react"
import { motion, AnimatePresence } from "framer-motion"
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query"
import { useBreadcrumbStore } from "@/store/useBreadcrumbStore"
import { useSiteStore } from "@/store/useSiteStore"
import { Icons8 } from "@/components/ui/icons8"
import { CameraPlayer } from "@/components/camera/CameraPlayer"
import { AddCameraModal } from "@/components/camera/AddCameraModal"
import { useDetectionSocket, DetectionEvent } from "@/hooks/useDetectionSocket"
import { apiClient } from "@/lib/apiClient"
import { toast } from "sonner"
import { cn } from "@/lib/utils"

export default function SurveillancePage() {
  const { setBreadcrumbs } = useBreadcrumbStore()
  const { activeSiteId } = useSiteStore()
  const queryClient = useQueryClient()

  const [modalOpen, setModalOpen] = useState(false)
  const [editingCamera, setEditingCamera] = useState<any | null>(null)
  const [fullscreenCamera, setFullscreenCamera] = useState<any | null>(null)
  const [gridCols, setGridCols] = useState<2 | 3>(2)

  // Real-time detection socket
  const { isConnected, recentDetections } = useDetectionSocket()

  // Find the latest blacklisted detection for full-screen alert
  const latestAlert = recentDetections.find(
    (d) => d.status === 'BLACKLISTED' && new Date().getTime() - new Date(d.detectedAt).getTime() < 10000
  )

  useEffect(() => {
    setBreadcrumbs([
      { label: "Dashboard", href: "/" },
      { label: "Surveillance", href: "/surveillance" },
    ])
  }, [setBreadcrumbs])

  const { data: cameras, isLoading } = useQuery({
    queryKey: ["cameras", activeSiteId],
    queryFn: async () => {
      const res = await apiClient.get(`/api/cameras?siteId=${activeSiteId}`)
      return res.data
    },
    refetchInterval: 30000,
  })

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => apiClient.delete(`/api/cameras/${id}`),
    onSuccess: () => {
      toast.success("Camera removed")
      queryClient.invalidateQueries({ queryKey: ["cameras"] })
    },
    onError: () => toast.error("Failed to remove camera"),
  })

  const handleAdd = () => { setEditingCamera(null); setModalOpen(true) }
  const handleEdit = (cam: any) => { setEditingCamera(cam); setModalOpen(true) }
  const handleDelete = (id: string) => {
    if (confirm("Remove this camera from the system?")) deleteMutation.mutate(id)
  }

  // Start stream processing in AI service
  const toggleAiStream = async (cam: any) => {
    try {
      const aiUrl = process.env.NEXT_PUBLIC_AI_URL || 'http://localhost:8000'
      await apiClient.post(`${aiUrl}/streams/start`, {
        cameraId: cam.id,
        streamUrl: cam.streamUrl,
        cameraName: cam.name
      })
      toast.success(`AI Detection started for ${cam.name}`)
    } catch (e) {
      toast.error('Could not start AI detection. Is Python service running?')
    }
  }

  return (
    <div className="w-full h-full flex flex-col xl:flex-row gap-5">

      {/* Main Camera Grid Area */}
      <div className="flex-1 flex flex-col gap-5 min-w-0">
        {/* Toolbar */}
        <div className="flex items-center gap-3 flex-wrap">
          <div className="flex items-center gap-1.5 bg-secondary/60 rounded-xl p-1 border border-border">
            {[2, 3].map(cols => (
              <button key={cols} onClick={() => setGridCols(cols as 2 | 3)}
                className={cn("w-8 h-7 rounded-lg text-[10px] font-black transition-all",
                  gridCols === cols ? "bg-primary text-white" : "text-muted-foreground hover:text-foreground"
                )}>
                {cols}×
              </button>
            ))}
          </div>

          <div className="flex items-center gap-2 px-3 py-1.5 rounded-xl bg-emerald-500/10 border border-emerald-500/20">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
            <span className="text-[10px] font-black uppercase tracking-widest text-emerald-500">Live</span>
            <span className="text-[10px] font-bold text-emerald-500/70">· {cameras?.length ?? 0} cameras</span>
          </div>

          <div className="flex items-center gap-2 px-3 py-1.5 rounded-xl bg-blue-500/10 border border-blue-500/20">
            <span className={cn("w-1.5 h-1.5 rounded-full", isConnected ? "bg-blue-500 animate-pulse" : "bg-red-500")} />
            <span className="text-[10px] font-black uppercase tracking-widest text-blue-500">
              AI {isConnected ? 'Connected' : 'Offline'}
            </span>
          </div>

          <div className="flex-1" />

          <button onClick={handleAdd}
            className="h-9 px-6 rounded-xl font-black text-[10px] uppercase tracking-widest flex items-center gap-2 bg-primary hover:bg-primary/90 text-white shadow-lg shadow-primary/20 transition-all active:scale-95">
            <Icons8 icon="plus" className="w-3.5 h-3.5 invert" />
            Add Camera
          </button>
        </div>

        {/* Camera Grid */}
        {isLoading ? (
          <div className="flex-1 flex items-center justify-center opacity-40">
            <div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full animate-spin" />
          </div>
        ) : !cameras || cameras.length === 0 ? (
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}
            className="flex-1 flex flex-col items-center justify-center gap-5 opacity-50">
            <div className="w-20 h-20 rounded-3xl bg-secondary flex items-center justify-center">
              <Icons8 icon="security-camera" className="w-10 h-10 grayscale" />
            </div>
            <div className="text-center">
              <p className="text-[13px] font-black uppercase tracking-widest text-foreground">No cameras configured</p>
              <p className="text-[11px] font-bold text-muted-foreground mt-1">Add a camera to start monitoring</p>
            </div>
            <button onClick={handleAdd}
              className="h-10 px-8 rounded-xl font-black text-[11px] uppercase tracking-widest bg-primary text-white hover:bg-primary/90 transition-all">
              Add First Camera
            </button>
          </motion.div>
        ) : (
          <div className={cn(
            "grid gap-4",
            gridCols === 2 ? "grid-cols-1 md:grid-cols-2" : "grid-cols-1 md:grid-cols-2 lg:grid-cols-3"
          )}>
            {cameras.map((cam: any, idx: number) => (
              <motion.div key={cam.id} initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: idx * 0.08 }} className="relative group">
                <CameraPlayer
                  streamUrl={cam.streamUrl}
                  name={cam.name}
                  siteName={cam.site?.name}
                  onFullscreen={() => setFullscreenCamera(cam)}
                />
                {/* Camera action buttons */}
                <div className="absolute top-9 right-2 flex flex-col gap-1 opacity-0 group-hover:opacity-100 transition-opacity z-10">
                  <button onClick={(e) => { e.stopPropagation(); handleEdit(cam) }} title="Edit Camera"
                    className="w-7 h-7 rounded-lg bg-black/70 hover:bg-primary text-white flex items-center justify-center backdrop-blur-sm transition-colors">
                    <Icons8 icon="edit" className="w-3.5 h-3.5 invert" />
                  </button>
                  <button onClick={(e) => { e.stopPropagation(); toggleAiStream(cam) }} title="Start AI Detection"
                    className="w-7 h-7 rounded-lg bg-black/70 hover:bg-blue-500 text-white flex items-center justify-center backdrop-blur-sm transition-colors">
                    <Icons8 icon="artificial-intelligence" className="w-3.5 h-3.5 invert" />
                  </button>
                  <button onClick={(e) => { e.stopPropagation(); handleDelete(cam.id) }} title="Delete Camera"
                    className="w-7 h-7 rounded-lg bg-black/70 hover:bg-red-500 text-white flex items-center justify-center backdrop-blur-sm transition-colors">
                    <Icons8 icon="trash" className="w-3.5 h-3.5 invert" />
                  </button>
                </div>
              </motion.div>
            ))}
          </div>
        )}
      </div>

      {/* Live Detections Sidebar */}
      <div className="w-full xl:w-[320px] flex flex-col gap-4 border-l border-border pl-0 xl:pl-5">
        <div className="flex items-center gap-2">
          <Icons8 icon="artificial-intelligence" className="w-5 h-5 text-primary" />
          <h2 className="text-[12px] font-black uppercase tracking-widest">Live Detections</h2>
        </div>
        
        <div className="flex-1 flex flex-col gap-3 overflow-y-auto pr-2 pb-4">
          <AnimatePresence initial={false}>
            {recentDetections.map((det) => (
              <motion.div
                key={det.detectedAt}
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, scale: 0.9 }}
                className={cn(
                  "p-3 rounded-2xl border bg-card shadow-sm flex flex-col gap-2 relative overflow-hidden",
                  det.status === 'BLACKLISTED' ? "border-red-500/50 bg-red-500/10" :
                  det.status === 'UNKNOWN' ? "border-yellow-500/50" : "border-border"
                )}
              >
                {/* Snapshot image */}
                {det.snapshot && (
                  <div className="w-full h-[100px] rounded-xl overflow-hidden bg-black mb-1">
                    <img src={`data:image/jpeg;base64,${det.snapshot}`} alt="Plate snapshot" className="w-full h-full object-cover" />
                  </div>
                )}
                
                <div className="flex items-center justify-between">
                  <span className="font-mono text-lg font-black text-foreground tracking-wider">{det.plate}</span>
                  <span className={cn("text-[9px] font-black uppercase tracking-widest px-2 py-0.5 rounded-full",
                    det.status === 'BLACKLISTED' ? "bg-red-500/20 text-red-500" :
                    det.status === 'UNKNOWN' ? "bg-yellow-500/20 text-yellow-600 dark:text-yellow-400" :
                    det.status === 'NOT_CHECKED_IN' ? "bg-orange-500/20 text-orange-500" :
                    "bg-emerald-500/20 text-emerald-500"
                  )}>
                    {det.status.replace(/_/g, ' ')}
                  </span>
                </div>
                
                <div className="flex items-center justify-between text-[10px] text-muted-foreground font-bold">
                  <span>Camera: {det.cameraName}</span>
                  <span>{(det.confidence * 100).toFixed(0)}% conf</span>
                </div>
                
                {det.status === 'UNKNOWN' && (
                  <button className="mt-1 w-full py-1.5 rounded-lg bg-primary/10 text-primary hover:bg-primary hover:text-white transition-colors text-[10px] font-black uppercase tracking-widest">
                    Register Vehicle
                  </button>
                )}
                {det.status === 'NOT_CHECKED_IN' && (
                  <button className="mt-1 w-full py-1.5 rounded-lg bg-orange-500/10 text-orange-500 hover:bg-orange-500 hover:text-white transition-colors text-[10px] font-black uppercase tracking-widest">
                    Check In Now
                  </button>
                )}
              </motion.div>
            ))}
            
            {recentDetections.length === 0 && (
              <div className="py-10 text-center opacity-50">
                <span className="text-[11px] font-bold text-muted-foreground">Waiting for AI detections...</span>
              </div>
            )}
          </AnimatePresence>
        </div>
      </div>

      {/* Blacklist Full-screen Alert */}
      <AnimatePresence>
        {latestAlert && (
          <motion.div
            initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            className="fixed inset-0 z-[100] pointer-events-none flex items-center justify-center"
            style={{ background: 'radial-gradient(circle, transparent 20%, rgba(239,68,68,0.4) 100%)' }}
          >
            <motion.div
              initial={{ scale: 0.8, y: 50 }} animate={{ scale: 1, y: 0 }} exit={{ scale: 0.8, opacity: 0 }}
              className="bg-red-500 text-white p-8 rounded-[3rem] shadow-2xl flex flex-col items-center gap-4 border-4 border-red-400"
            >
              <div className="w-20 h-20 bg-white rounded-full flex items-center justify-center animate-pulse">
                <Icons8 icon="siren" className="w-12 h-12" />
              </div>
              <h1 className="text-4xl font-black uppercase tracking-tighter">Blacklisted Vehicle</h1>
              <p className="text-xl font-mono bg-black/20 px-6 py-2 rounded-2xl">{latestAlert.plate}</p>
              <p className="font-bold text-red-100">Detected at {latestAlert.cameraName}</p>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Fullscreen Modal */}
      <AnimatePresence>
        {fullscreenCamera && (
          <>
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
              className="fixed inset-0 bg-black/95 backdrop-blur-sm z-50"
              onClick={() => setFullscreenCamera(null)} />
            <motion.div initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="fixed inset-4 md:inset-8 z-50 flex flex-col gap-3">
              <div className="flex items-center justify-between">
                <span className="text-[12px] font-black uppercase tracking-widest text-white/80">
                  {fullscreenCamera.name}
                </span>
                <button onClick={() => setFullscreenCamera(null)}
                  className="w-8 h-8 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center text-white transition-colors">
                  <Icons8 icon="multiply" className="w-4 h-4 invert" />
                </button>
              </div>
              <div className="flex-1">
                <CameraPlayer
                  streamUrl={fullscreenCamera.streamUrl}
                  name={fullscreenCamera.name}
                  siteName={fullscreenCamera.site?.name}
                  isFullscreen
                />
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>

      <AddCameraModal isOpen={modalOpen} onClose={() => setModalOpen(false)} camera={editingCamera} />
    </div>
  )
}
