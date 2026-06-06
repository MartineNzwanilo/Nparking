"use client";

import React, { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Icons8 } from "@/components/ui/icons8";
import { cn, formatCurrency, getImageUrl } from "@/lib/utils";

interface Session {
  id: string;
  checkIn: string;
  checkOut: string | null;
  amountDue: number | null;
  propertiesLeft?: string | null;
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
  frontImage?: string | null;
  plateImage?: string | null;
  sideImage?: string | null;
  category: { id: string; name: string; price: number };
  sessions: Session[];
}

interface VehicleDetailsModalProps {
  vehicle: Vehicle | null;
  isOpen: boolean;
  onClose: () => void;
}

function ImageGallery({ vehicle }: { vehicle: Vehicle }) {
  const images = [
    { label: "Front View", src: getImageUrl(vehicle.frontImage), icon: "car" },
    { label: "Plate",      src: getImageUrl(vehicle.plateImage), icon: "road" },
    { label: "Side View",  src: getImageUrl(vehicle.sideImage),  icon: "car" },
  ].filter(img => img.src);

  const [activeImg, setActiveImg] = useState<string | null>(
    images[0]?.src ?? null
  );

  if (images.length === 0) return null;

  return (
    <div>
      <h4 className="text-[11px] font-black uppercase tracking-widest text-muted-foreground border-b border-border/50 pb-2 mb-4">
        Vehicle Images
      </h4>

      {/* Main preview */}
      <div className="w-full h-52 rounded-2xl overflow-hidden bg-secondary/30 border border-border mb-3 flex items-center justify-center">
        {activeImg ? (
          <img
            src={activeImg}
            alt="Vehicle"
            className="w-full h-full object-cover"
          />
        ) : (
          <Icons8 icon="car" className="w-16 h-16 opacity-20" />
        )}
      </div>

      {/* Thumbnails */}
      <div className="flex gap-3">
        {images.map((img) => (
          <button
            key={img.label}
            onClick={() => setActiveImg(img.src!)}
            className={cn(
              "flex-1 rounded-xl overflow-hidden border-2 transition-all h-20",
              activeImg === img.src
                ? "border-primary shadow-md shadow-primary/20"
                : "border-border opacity-60 hover:opacity-100"
            )}
          >
            <div className="relative w-full h-full">
              <img
                src={img.src!}
                alt={img.label}
                className="w-full h-full object-cover"
              />
              <span className="absolute bottom-0 left-0 right-0 text-center text-[8px] font-black uppercase tracking-widest bg-black/50 text-white py-1">
                {img.label}
              </span>
            </div>
          </button>
        ))}
      </div>
    </div>
  );
}

export function VehicleDetailsModal({ vehicle, isOpen, onClose }: VehicleDetailsModalProps) {
  if (!vehicle) return null;

  const latestSession = vehicle.sessions?.[0];
  const isParked = latestSession && !latestSession.checkOut;

  const formatTime = (dateStr: string) => {
    return new Date(dateStr).toLocaleString([], { dateStyle: "medium", timeStyle: "short" });
  };

  const hasImages = vehicle.frontImage || vehicle.plateImage || vehicle.sideImage;

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
            <div className="bg-card border border-border shadow-2xl rounded-3xl overflow-hidden flex flex-col max-h-[90vh]">

              {/* Header */}
              <div className="flex items-center justify-between px-8 py-6 border-b border-border/50 bg-secondary/10 shrink-0">
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

                {/* Properties Left Alert */}
                {latestSession?.propertiesLeft && (
                  <div className="flex items-start gap-3 p-4 rounded-2xl bg-amber-500/8 border border-amber-500/30">
                    <div className="w-8 h-8 rounded-xl bg-amber-500/15 flex items-center justify-center shrink-0 mt-0.5">
                      <Icons8 icon="box" className="w-4 h-4 text-amber-500" />
                    </div>
                    <div>
                      <p className="text-[11px] font-black uppercase tracking-widest text-amber-600 dark:text-amber-400 mb-1">
                        Properties Left in Vehicle
                      </p>
                      <p className="text-[13px] font-semibold text-foreground">
                        {latestSession.propertiesLeft}
                      </p>
                    </div>
                  </div>
                )}

                {/* Image Gallery */}
                {hasImages && <ImageGallery vehicle={vehicle} />}

                {/* Owner Information */}
                <div>
                  <h4 className="text-[11px] font-black uppercase tracking-widest text-muted-foreground border-b border-border/50 pb-2 mb-4">
                    Owner &amp; Vehicle Info
                  </h4>
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
                          <div
                            className="w-3 h-3 rounded-full border border-border"
                            style={{ backgroundColor: vehicle.color }}
                          />
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
                  <h4 className="text-[11px] font-black uppercase tracking-widest text-muted-foreground border-b border-border/50 pb-2 mb-4">
                    Recent Sessions
                  </h4>
                  <div className="flex flex-col gap-3">
                    {vehicle.sessions.length === 0 ? (
                      <p className="text-[13px] font-bold text-muted-foreground py-4 text-center">
                        No parking history found.
                      </p>
                    ) : (
                      vehicle.sessions.map((session) => (
                        <div key={session.id} className="p-4 rounded-xl border border-border/50 bg-secondary/10 flex flex-col gap-2">
                          <div className="flex items-center justify-between">
                            <div>
                              <p className="text-[13px] font-bold text-foreground">{session.site?.name}</p>
                              <p className="text-[11px] font-semibold text-muted-foreground mt-0.5">
                                {formatTime(session.checkIn)}
                                {session.checkOut ? ` → ${formatTime(session.checkOut)}` : " (Ongoing)"}
                              </p>
                            </div>
                            <div className="text-right">
                              <p className="text-[13px] font-black text-foreground">
                                {formatCurrency(session.amountDue || vehicle.category?.price || 0)}
                              </p>
                              <span className={cn(
                                "text-[9px] font-black uppercase tracking-widest",
                                !session.checkOut ? "text-emerald-500" : "text-muted-foreground"
                              )}>
                                {!session.checkOut ? "Active" : "Completed"}
                              </span>
                            </div>
                          </div>
                          {session.propertiesLeft && (
                            <div className="flex items-center gap-2 px-3 py-2 rounded-lg bg-amber-500/8 border border-amber-500/20">
                              <span className="text-[9px] font-black uppercase tracking-widest text-amber-600 dark:text-amber-400 shrink-0">
                                Items:
                              </span>
                              <span className="text-[11px] font-semibold text-foreground truncate">
                                {session.propertiesLeft}
                              </span>
                            </div>
                          )}
                        </div>
                      ))
                    )}
                  </div>
                </div>

              </div>

              {/* Footer */}
              <div className="p-6 border-t border-border/50 bg-secondary/10 flex justify-end shrink-0">
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
