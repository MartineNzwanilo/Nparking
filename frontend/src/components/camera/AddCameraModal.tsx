"use client"

import React, { useEffect, useState } from "react"
import { motion, AnimatePresence } from "framer-motion"
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query"
import { apiClient } from "@/lib/apiClient"
import { toast } from "sonner"
import { Icons8 } from "@/components/ui/icons8"

interface AddCameraModalProps {
  isOpen: boolean
  onClose: () => void
  camera: any | null
}

export function AddCameraModal({ isOpen, onClose, camera }: AddCameraModalProps) {
  const queryClient = useQueryClient()
  const [name, setName] = useState("")
  const [streamUrl, setStreamUrl] = useState("")
  const [siteId, setSiteId] = useState("")

  const { data: sites } = useQuery({
    queryKey: ["parking-sites"],
    queryFn: async () => (await apiClient.get("/api/sites")).data,
    enabled: isOpen,
  })

  useEffect(() => {
    if (isOpen) {
      setName(camera?.name || "")
      setStreamUrl(camera?.streamUrl || "")
      setSiteId(camera?.siteId || "")
    }
  }, [isOpen, camera])

  const mutation = useMutation({
    mutationFn: async (data: any) => {
      if (camera?.id) {
        await apiClient.patch(`/api/cameras/${camera.id}`, data)
      } else {
        await apiClient.post("/api/cameras", data)
      }
    },
    onSuccess: () => {
      toast.success(`Camera ${camera ? "updated" : "added"} successfully`)
      queryClient.invalidateQueries({ queryKey: ["cameras"] })
      onClose()
    },
    onError: (err: any) => {
      toast.error(err.response?.data?.message || "Failed to save camera")
    },
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (!name.trim() || !streamUrl.trim()) {
      return toast.error("Camera name and stream URL are required")
    }
    mutation.mutate({ name: name.trim(), streamUrl: streamUrl.trim(), siteId: siteId || null })
  }

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            className="fixed inset-0 bg-background/80 backdrop-blur-sm z-50" onClick={onClose} />
          <motion.div initial={{ opacity: 0, scale: 0.95, y: 20 }} animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: 20 }}
            className="fixed left-[50%] top-[50%] z-50 w-full max-w-md translate-x-[-50%] translate-y-[-50%] p-6">
            <form onSubmit={handleSubmit} className="bg-card border border-border shadow-2xl rounded-3xl overflow-hidden flex flex-col">

              <div className="flex items-center justify-between px-8 py-6 border-b border-border/50 bg-secondary/10">
                <h2 className="text-xl font-black uppercase tracking-widest text-foreground">
                  {camera ? "Edit Camera" : "Add Camera"}
                </h2>
                <button type="button" onClick={onClose}
                  className="w-8 h-8 rounded-full hover:bg-secondary/80 flex items-center justify-center transition-colors text-muted-foreground">
                  <Icons8 icon="multiply" className="w-4 h-4" />
                </button>
              </div>

              <div className="p-8 flex flex-col gap-5">
                <div>
                  <label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground block mb-2">Camera Name</label>
                  <input type="text" value={name} onChange={e => setName(e.target.value)}
                    placeholder="e.g. Main Entrance"
                    className="w-full h-12 px-4 bg-background border border-border rounded-xl text-[13px] font-bold text-foreground focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all" />
                </div>

                <div>
                  <label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground block mb-2">Stream URL</label>
                  <input type="text" value={streamUrl} onChange={e => setStreamUrl(e.target.value)}
                    placeholder="http://192.168.1.x:8080/video"
                    className="w-full h-12 px-4 bg-background border border-border rounded-xl text-[12px] font-bold text-foreground focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all font-mono" />
                  <p className="text-[9px] text-muted-foreground/60 mt-1.5 font-bold">
                    IP Webcam: use <span className="text-primary font-mono">http://[phone-ip]:8080/video</span>
                  </p>
                </div>

                <div>
                  <label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground block mb-2">Assigned Site</label>
                  <select value={siteId} onChange={e => setSiteId(e.target.value)}
                    className="w-full h-12 px-4 bg-background border border-border rounded-xl text-[13px] font-bold text-foreground focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all appearance-none">
                    <option value="">No specific site (Global)</option>
                    {sites?.map((s: any) => (
                      <option key={s.id} value={s.id}>{s.name}</option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="p-6 border-t border-border/50 bg-secondary/10 flex justify-end gap-3">
                <button type="button" onClick={onClose}
                  className="px-6 py-2 rounded-xl text-[11px] font-bold uppercase tracking-widest bg-secondary text-muted-foreground hover:bg-secondary/80 hover:text-foreground transition-colors">
                  Cancel
                </button>
                <button type="submit" disabled={mutation.isPending}
                  className="px-6 py-2 rounded-xl text-[11px] font-black uppercase tracking-widest bg-primary text-white hover:bg-primary/90 transition-colors disabled:opacity-50">
                  {mutation.isPending ? "Saving..." : "Save Camera"}
                </button>
              </div>

            </form>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  )
}
