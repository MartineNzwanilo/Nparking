import React, { useEffect, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Icons8 } from "@/components/ui/icons8";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/apiClient";
import { toast } from "sonner";
import { ParkingSite } from "@/store/useSiteStore";

interface SiteModalProps {
  isOpen: boolean;
  onClose: () => void;
  site: ParkingSite | null;
}

export function SiteModal({ isOpen, onClose, site }: SiteModalProps) {
  const queryClient = useQueryClient();
  const [name, setName] = useState("");
  const [location, setLocation] = useState("");
  const [capacity, setCapacity] = useState("");

  useEffect(() => {
    if (isOpen) {
      setName(site?.name || "");
      setLocation(site?.location || "");
      setCapacity(site?.capacity ? String(site.capacity) : "");
    }
  }, [isOpen, site]);

  const mutation = useMutation({
    mutationFn: async (data: { name: string; location: string; capacity: number }) => {
      if (site && site.id !== "all") {
        await apiClient.patch(`/api/sites/${site.id}`, data);
      } else {
        await apiClient.post(`/api/sites`, data);
      }
    },
    onSuccess: () => {
      toast.success(`Parking Facility ${site ? "updated" : "created"} successfully`);
      queryClient.invalidateQueries({ queryKey: ["parking-sites"] });
      onClose();
    },
    onError: (err: any) => {
      toast.error(err.response?.data?.message || `Failed to ${site ? "update" : "create"} facility`);
    }
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return toast.error("Facility name is required");
    if (!location.trim()) return toast.error("Location is required");
    const parsedCapacity = parseInt(capacity, 10);
    if (isNaN(parsedCapacity) || parsedCapacity < 0) return toast.error("Invalid capacity");

    mutation.mutate({ name: name.trim(), location: location.trim(), capacity: parsedCapacity });
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-background/80 backdrop-blur-sm z-50"
            onClick={onClose}
          />
          <motion.div
            initial={{ opacity: 0, scale: 0.95, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: 20 }}
            className="fixed left-[50%] top-[50%] z-50 w-full max-w-md translate-x-[-50%] translate-y-[-50%] p-6"
          >
            <form onSubmit={handleSubmit} className="bg-card border border-border shadow-2xl rounded-3xl overflow-hidden flex flex-col">
              
              <div className="flex items-center justify-between px-8 py-6 border-b border-border/50 bg-secondary/10">
                <h2 className="text-xl font-black uppercase tracking-widest text-foreground">
                  {site ? "Edit Facility" : "New Facility"}
                </h2>
                <button
                  type="button"
                  onClick={onClose}
                  className="w-8 h-8 rounded-full hover:bg-secondary/80 flex items-center justify-center transition-colors text-muted-foreground"
                >
                  <Icons8 icon="multiply" className="w-4 h-4" />
                </button>
              </div>

              <div className="p-8 flex flex-col gap-6">
                <div>
                  <label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground block mb-2">Facility Name</label>
                  <input
                    type="text"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="e.g. Downtown Garage"
                    className="w-full h-12 px-4 bg-background border border-border rounded-xl text-[13px] font-bold text-foreground focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all"
                  />
                </div>

                <div>
                  <label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground block mb-2">Physical Location</label>
                  <input
                    type="text"
                    value={location}
                    onChange={(e) => setLocation(e.target.value)}
                    placeholder="e.g. City Center Avenue"
                    className="w-full h-12 px-4 bg-background border border-border rounded-xl text-[13px] font-bold text-foreground focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all"
                  />
                </div>

                <div>
                  <label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground block mb-2">Estimated Spaces (Soft Limit)</label>
                  <input
                    type="number"
                    value={capacity}
                    onChange={(e) => setCapacity(e.target.value)}
                    placeholder="e.g. 450"
                    className="w-full h-12 px-4 bg-background border border-border rounded-xl text-[13px] font-bold text-foreground focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all"
                  />
                </div>
              </div>

              <div className="p-6 border-t border-border/50 bg-secondary/10 flex justify-end gap-3">
                <button
                  type="button"
                  onClick={onClose}
                  className="px-6 py-2 rounded-xl text-[11px] font-bold uppercase tracking-widest bg-secondary text-muted-foreground hover:bg-secondary/80 hover:text-foreground transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={mutation.isPending}
                  className="px-6 py-2 rounded-xl text-[11px] font-black uppercase tracking-widest bg-primary text-white hover:bg-primary/90 transition-colors disabled:opacity-50"
                >
                  {mutation.isPending ? "Saving..." : "Save Facility"}
                </button>
              </div>

            </form>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}
