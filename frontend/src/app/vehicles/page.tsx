"use client";

import React, { useEffect, useState } from "react";
import { motion } from "framer-motion";
import { useQuery } from "@tanstack/react-query";
import { useBreadcrumbStore } from "@/store/useBreadcrumbStore";
import { Icons8 } from "@/components/ui/icons8";
import { cn, formatCurrency } from "@/lib/utils";
import { apiClient } from "@/lib/apiClient";
import { VehicleDetailsModal } from "./VehicleDetailsModal";

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

export default function VehiclesPage() {
  const { setBreadcrumbs } = useBreadcrumbStore();
  const [searchTerm, setSearchTerm] = useState("");
  const [debouncedSearch, setDebouncedSearch] = useState("");
  const [selectedVehicle, setSelectedVehicle] = useState<Vehicle | null>(null);

  // Debounce search input to prevent spamming the backend
  useEffect(() => {
    const timer = setTimeout(() => setDebouncedSearch(searchTerm), 500);
    return () => clearTimeout(timer);
  }, [searchTerm]);

  useEffect(() => {
    setBreadcrumbs([
      { label: "Dashboard", href: "/" },
      { label: "Fleet", href: "/vehicles" },
    ]);
  }, [setBreadcrumbs]);

  const { data: vehicles, isLoading, isError } = useQuery<Vehicle[]>({
    queryKey: ["vehicles", debouncedSearch],
    queryFn: async () => {
      const endpoint = debouncedSearch.trim() 
        ? `/api/vehicles?plate=${encodeURIComponent(debouncedSearch.trim())}` 
        : `/api/vehicles`;
      const res = await apiClient.get(endpoint);
      return res.data;
    },
  });

  // Duration Helper
  const calculateDuration = (checkInStr: string, checkOutStr: string | null) => {
    const checkIn = new Date(checkInStr);
    const end = checkOutStr ? new Date(checkOutStr) : new Date();
    const diffMs = end.getTime() - checkIn.getTime();
    
    const diffHrs = Math.floor(diffMs / (1000 * 60 * 60));
    const diffMins = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60));
    
    if (diffHrs > 0) return `${diffHrs}h ${diffMins}m`;
    return `${diffMins}m`;
  };

  // Entry Time Helper
  const formatTime = (dateStr: string) => {
    return new Date(dateStr).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  };

  return (
    <div className="w-full h-full flex flex-col gap-6">
      {/* Search & Actions Bar */}
      <div className="flex flex-col md:flex-row items-center justify-between gap-4 w-full">
        <div className="relative w-full md:w-96">
            <Icons8 icon="search" className="w-5 h-5 absolute left-4 top-1/2 -translate-y-1/2 text-muted-foreground opacity-50" />
            <input 
                type="text" 
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                placeholder="Search by license plate..."
                className="w-full h-12 pl-12 pr-4 bg-card border border-border rounded-2xl text-[13px] font-semibold text-foreground focus:outline-none focus:ring-2 focus:ring-primary/50 transition-all shadow-sm"
            />
        </div>
        <button className="h-12 px-6 rounded-2xl font-black text-[11px] uppercase tracking-widest flex items-center justify-center gap-2 bg-primary hover:bg-primary/90 text-white shadow-xl shadow-primary/20 transition-all active:scale-95 w-full md:w-auto shrink-0">
          <Icons8 icon="plus" className="w-4 h-4 invert" />
          Register Vehicle
        </button>
      </div>

      <motion.div 
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.1 }}
        className="glass border border-border rounded-3xl overflow-hidden shadow-sm flex flex-col min-h-[400px]"
      >
        <div className="overflow-x-auto w-full">
          <table className="w-full text-left border-collapse min-w-[800px]">
            <thead>
              <tr className="border-b border-border/50 bg-secondary/20">
                <th className="px-6 py-4 text-[11px] font-black uppercase tracking-widest text-muted-foreground">License Plate</th>
                <th className="px-6 py-4 text-[11px] font-black uppercase tracking-widest text-muted-foreground">Type</th>
                <th className="px-6 py-4 text-[11px] font-black uppercase tracking-widest text-muted-foreground">Entry Time</th>
                <th className="px-6 py-4 text-[11px] font-black uppercase tracking-widest text-muted-foreground">Duration</th>
                <th className="px-6 py-4 text-[11px] font-black uppercase tracking-widest text-muted-foreground">Amount</th>
                <th className="px-6 py-4 text-[11px] font-black uppercase tracking-widest text-muted-foreground">Status</th>
                <th className="px-6 py-4 text-[11px] font-black uppercase tracking-widest text-muted-foreground text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {isLoading && (
                Array.from({ length: 5 }).map((_, i) => (
                  <tr key={`skeleton-${i}`} className="border-b border-border/30">
                    <td className="px-6 py-4"><div className="h-10 bg-secondary/50 rounded-xl animate-pulse w-32" /></td>
                    <td className="px-6 py-4"><div className="h-4 bg-secondary/50 rounded animate-pulse w-16" /></td>
                    <td className="px-6 py-4"><div className="h-4 bg-secondary/50 rounded animate-pulse w-20" /></td>
                    <td className="px-6 py-4"><div className="h-4 bg-secondary/50 rounded animate-pulse w-16" /></td>
                    <td className="px-6 py-4"><div className="h-4 bg-secondary/50 rounded animate-pulse w-12" /></td>
                    <td className="px-6 py-4"><div className="h-6 bg-secondary/50 rounded-full animate-pulse w-20" /></td>
                    <td className="px-6 py-4"><div className="h-4 bg-secondary/50 rounded animate-pulse w-16 ml-auto" /></td>
                  </tr>
                ))
              )}

              {isError && !isLoading && (
                <tr>
                    <td colSpan={7} className="p-12 text-center">
                        <div className="flex flex-col items-center justify-center gap-3">
                            <Icons8 icon="error" className="w-12 h-12 text-destructive opacity-50" />
                            <p className="text-[13px] font-bold text-muted-foreground">Failed to load fleet data. Ensure backend is running.</p>
                        </div>
                    </td>
                </tr>
              )}

              {!isLoading && !isError && vehicles && vehicles.length === 0 && (
                <tr>
                    <td colSpan={7} className="p-16 text-center">
                        <div className="flex flex-col items-center justify-center gap-4">
                            <div className="w-20 h-20 bg-secondary/30 rounded-full flex items-center justify-center">
                                <Icons8 icon="car" className="w-10 h-10 opacity-30" />
                            </div>
                            <div>
                                <h4 className="text-[14px] font-black uppercase tracking-widest text-foreground">No Vehicles Found</h4>
                                <p className="text-[12px] font-bold text-muted-foreground mt-1">There are no vehicles registered or matching your search.</p>
                            </div>
                        </div>
                    </td>
                </tr>
              )}

              {!isLoading && !isError && vehicles && vehicles.map((vehicle) => {
                const latestSession = vehicle.sessions?.[0];
                const isParked = latestSession && !latestSession.checkOut;

                return (
                  <tr key={vehicle.id} className="border-b border-border/30 hover:bg-muted/20 transition-colors">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center shrink-0">
                          <Icons8 icon="car" className="w-6 h-6" />
                        </div>
                        <div className="flex flex-col">
                            <span className="text-[13px] font-black uppercase tracking-widest text-foreground">{vehicle.plateNumber}</span>
                            {vehicle.isBlacklisted && <span className="text-[9px] font-black text-destructive tracking-widest uppercase">Blacklisted</span>}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-[12px] font-bold text-muted-foreground">
                        {vehicle.category?.name || "Unknown"}
                    </td>
                    <td className="px-6 py-4 text-[12px] font-bold text-muted-foreground">
                        {latestSession ? formatTime(latestSession.checkIn) : "-"}
                    </td>
                    <td className="px-6 py-4 text-[12px] font-bold text-muted-foreground">
                        {latestSession ? calculateDuration(latestSession.checkIn, latestSession.checkOut) : "-"}
                    </td>
                    <td className="px-6 py-4 text-[13px] font-black text-foreground">
                        {latestSession ? formatCurrency(latestSession.amount || vehicle.category?.price || 0) : "-"}
                    </td>
                    <td className="px-6 py-4">
                        {latestSession ? (
                            <span className={cn(
                                "px-3 py-1 rounded-full text-[10px] font-black uppercase tracking-widest",
                                isParked ? "bg-emerald-500/10 text-emerald-500" : "bg-amber-500/10 text-amber-500"
                            )}>
                                {isParked ? "Parked" : "Exited"}
                            </span>
                        ) : (
                            <span className="px-3 py-1 rounded-full text-[10px] font-black uppercase tracking-widest bg-secondary text-muted-foreground">
                                Registered
                            </span>
                        )}
                    </td>
                    <td className="px-6 py-4 text-right">
                      <button 
                        onClick={() => setSelectedVehicle(vehicle)}
                        className="text-[11px] font-bold text-primary hover:underline uppercase tracking-wider"
                      >
                        Details
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </motion.div>

      <VehicleDetailsModal 
        isOpen={!!selectedVehicle} 
        vehicle={selectedVehicle} 
        onClose={() => setSelectedVehicle(null)} 
      />
    </div>
  );
}
