import React from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Icons8 } from "@/components/ui/icons8";
import { cn, formatCurrency } from "@/lib/utils";

interface Session {
  id: string;
  checkIn: string;
  checkOut: string | null;
  amount: number | null;
  site: { name: string };
}

interface Vehicle {
  id: string;
  plateNumber: string;
  isBlacklisted: boolean;
  ownerName?: string | null;
  phone?: string | null;
  company?: string | null;
  color?: string | null;
  makeModel?: string | null;
  category: { id: string; name: string; price: number };
  sessions: Session[];
}

interface VehicleDetailsModalProps {
  vehicle: Vehicle | null;
  isOpen: boolean;
  onClose: () => void;
}

export function VehicleDetailsModal({ vehicle, isOpen, onClose }: VehicleDetailsModalProps) {
  if (!vehicle) return null;

  const latestSession = vehicle.sessions?.[0];
  const isParked = latestSession && !latestSession.checkOut;

  const formatTime = (dateStr: string) => {
    return new Date(dateStr).toLocaleString([], { dateStyle: 'medium', timeStyle: 'short' });
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
            className="fixed left-[50%] top-[50%] z-50 w-full max-w-2xl translate-x-[-50%] translate-y-[-50%] p-6"
          >
            <div className="bg-card border border-border shadow-2xl rounded-3xl overflow-hidden flex flex-col max-h-[85vh]">
              
              {/* Header */}
              <div className="flex items-center justify-between px-8 py-6 border-b border-border/50 bg-secondary/10">
                <div className="flex items-center gap-4">
                  <div className={cn(
                    "w-12 h-12 rounded-2xl flex items-center justify-center shrink-0 shadow-inner",
                    vehicle.isBlacklisted ? "bg-destructive/10" : "bg-primary/10"
                  )}>
                    <Icons8 icon="car" className="w-8 h-8" />
                  </div>
                  <div>
                    <h2 className="text-2xl font-black uppercase tracking-widest flex items-center gap-3">
                        {vehicle.plateNumber}
                        {vehicle.isBlacklisted && (
                            <span className="px-2 py-0.5 rounded text-[10px] bg-destructive/20 text-destructive tracking-widest uppercase flex items-center gap-1">
                                <Icons8 icon="error" className="w-3 h-3" />
                                Blacklisted
                            </span>
                        )}
                    </h2>
                    <p className="text-[13px] font-bold text-muted-foreground uppercase tracking-widest">
                      {vehicle.category?.name || "Unknown Category"}
                    </p>
                  </div>
                </div>
                <button
                  onClick={onClose}
                  className="w-10 h-10 rounded-full hover:bg-secondary/80 flex items-center justify-center transition-colors text-muted-foreground hover:text-foreground"
                >
                  <Icons8 icon="multiply" className="w-5 h-5" />
                </button>
              </div>

              {/* Body */}
              <div className="p-8 overflow-y-auto custom-scrollbar flex flex-col gap-8">
                
                {/* Status Card */}
                <div className={cn(
                    "p-6 rounded-2xl border flex items-center justify-between",
                    isParked ? "bg-emerald-500/5 border-emerald-500/20" : "bg-secondary/30 border-border"
                )}>
                    <div>
                        <p className="text-[11px] font-black uppercase tracking-widest text-muted-foreground mb-1">Current Status</p>
                        <h3 className={cn(
                            "text-xl font-black uppercase tracking-widest",
                            isParked ? "text-emerald-500" : "text-foreground"
                        )}>
                            {isParked ? "Parked Inside" : "Exited / Offline"}
                        </h3>
                    </div>
                    {isParked && latestSession && (
                        <div className="text-right">
                            <p className="text-[11px] font-black uppercase tracking-widest text-muted-foreground mb-1">Parked At</p>
                            <p className="text-[14px] font-bold text-foreground">{latestSession.site?.name}</p>
                            <p className="text-[12px] font-semibold text-muted-foreground">{formatTime(latestSession.checkIn)}</p>
                        </div>
                    )}
                </div>

                {/* Owner Information */}
                <div>
                    <h4 className="text-[11px] font-black uppercase tracking-widest text-muted-foreground border-b border-border/50 pb-2 mb-4">Owner & Vehicle Info</h4>
                    <div className="grid grid-cols-2 gap-6">
                        <div>
                            <p className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground mb-1">Owner Name</p>
                            <p className="text-[14px] font-bold text-foreground">{vehicle.ownerName || "—"}</p>
                        </div>
                        <div>
                            <p className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground mb-1">Phone Number</p>
                            <p className="text-[14px] font-bold text-foreground">{vehicle.phone || "—"}</p>
                        </div>
                        <div>
                            <p className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground mb-1">Make / Model</p>
                            <p className="text-[14px] font-bold text-foreground">{vehicle.makeModel || "—"}</p>
                        </div>
                        <div>
                            <p className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground mb-1">Color</p>
                            <div className="flex items-center gap-2">
                                {vehicle.color && (
                                    <div className="w-3 h-3 rounded-full border border-border" style={{ backgroundColor: vehicle.color }} />
                                )}
                                <p className="text-[14px] font-bold text-foreground">{vehicle.color || "—"}</p>
                            </div>
                        </div>
                        <div>
                            <p className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground mb-1">Company</p>
                            <p className="text-[14px] font-bold text-foreground">{vehicle.company || "—"}</p>
                        </div>
                    </div>
                </div>

                {/* Session History */}
                <div>
                    <h4 className="text-[11px] font-black uppercase tracking-widest text-muted-foreground border-b border-border/50 pb-2 mb-4">Latest Sessions</h4>
                    <div className="flex flex-col gap-3">
                        {vehicle.sessions.length === 0 ? (
                            <p className="text-[13px] font-bold text-muted-foreground py-4 text-center">No parking history found.</p>
                        ) : (
                            vehicle.sessions.map(session => (
                                <div key={session.id} className="p-4 rounded-xl border border-border/50 bg-secondary/10 flex items-center justify-between">
                                    <div>
                                        <p className="text-[13px] font-bold text-foreground">{session.site?.name}</p>
                                        <p className="text-[11px] font-semibold text-muted-foreground mt-0.5">
                                            {formatTime(session.checkIn)} {session.checkOut ? ` → ${formatTime(session.checkOut)}` : ' (Ongoing)'}
                                        </p>
                                    </div>
                                    <div className="text-right">
                                        <p className="text-[13px] font-black text-foreground">
                                            {formatCurrency(session.amount || vehicle.category?.price || 0)}
                                        </p>
                                        <span className={cn(
                                            "text-[9px] font-black uppercase tracking-widest",
                                            !session.checkOut ? "text-emerald-500" : "text-muted-foreground"
                                        )}>
                                            {!session.checkOut ? "Active" : "Completed"}
                                        </span>
                                    </div>
                                </div>
                            ))
                        )}
                    </div>
                </div>

              </div>

              {/* Footer */}
              <div className="p-6 border-t border-border/50 bg-secondary/10 flex justify-end">
                <button
                  onClick={onClose}
                  className="px-6 py-2 rounded-xl text-[12px] font-black uppercase tracking-widest bg-secondary text-foreground hover:bg-secondary/80 transition-colors"
                >
                  Close
                </button>
              </div>

            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}
