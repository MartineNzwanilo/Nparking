"use client"

import React, { useEffect, useState } from "react"
import { motion } from "framer-motion"
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query"
import { useBreadcrumbStore } from "@/store/useBreadcrumbStore"
import { Icons8 } from "@/components/ui/icons8"
import { cn } from "@/lib/utils"
import { useSiteStore, ParkingSite, defaultParkingSites } from "@/store/useSiteStore"
import { apiClient } from "@/lib/apiClient"
import { toast } from "sonner"
import { SiteModal } from "./SiteModal"
import { PrinterModal } from "./PrinterModal"

export default function AdministrationPage() {
  const { setBreadcrumbs } = useBreadcrumbStore()
  const queryClient = useQueryClient()
  const { activeSiteId, setParkingSites, parkingSites } = useSiteStore()
  
  const [modalOpen, setModalOpen] = useState(false)
  const [editingSite, setEditingSite] = useState<ParkingSite | null>(null)

  const [printerModalOpen, setPrinterModalOpen] = useState(false)
  const [editingPrinter, setEditingPrinter] = useState<any>(null)

  useEffect(() => {
    setBreadcrumbs([
      { label: "Dashboard", href: "/" },
      { label: "Administration", href: "/administration" }
    ])
  }, [setBreadcrumbs])

  // Fetch real sites from DB
  const { data: dbSites, isLoading, isError } = useQuery({
    queryKey: ["parking-sites"],
    queryFn: async () => {
      const res = await apiClient.get("/api/sites")
      return res.data
    }
  })

  const { data: printers, isLoading: isPrintersLoading } = useQuery({
    queryKey: ["printers"],
    queryFn: async () => {
      const res = await apiClient.get("/api/printer")
      return res.data
    }
  })

  // Sync to global store so Header dropdown updates
  useEffect(() => {
    if (dbSites) {
      // Calculate global totals
      const totalCapacity = dbSites.reduce((sum: number, site: any) => sum + (site.capacity || 0), 0);
      const globalOccupancyMap: Record<string, number> = {};
      
      const mappedSites: ParkingSite[] = dbSites.map((site: any) => {
        // Aggregate global occupancy
        if (site.occupancy) {
          site.occupancy.forEach((occ: any) => {
            globalOccupancyMap[occ.name] = (globalOccupancyMap[occ.name] || 0) + occ.count;
          });
        }
        
        return {
          id: site.id,
          name: site.name,
          location: site.location,
          capacity: site.capacity,
          status: "active",
          occupancy: site.occupancy || []
        };
      });

      const globalSite: ParkingSite = {
        id: "all",
        name: "All Sites (Global)",
        capacity: totalCapacity,
        status: "active",
        location: "Global Overview",
        occupancy: Object.entries(globalOccupancyMap).map(([name, count]) => ({ name, count }))
      };

      setParkingSites([globalSite, ...mappedSites])
    }
  }, [dbSites, setParkingSites])

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => {
      await apiClient.delete(`/api/sites/${id}`)
    },
    onSuccess: () => {
      toast.success("Site deleted successfully")
      queryClient.invalidateQueries({ queryKey: ["parking-sites"] })
    },
    onError: (err: any) => {
      toast.error(err.response?.data?.message || "Failed to delete site")
    }
  })

  const handleAdd = () => {
    setEditingSite(null)
    setModalOpen(true)
  }

  const handleEdit = (site: ParkingSite) => {
    if (site.id === "all") return; // Cannot edit the global dummy site
    setEditingSite(site)
    setModalOpen(true)
  }

  const handleDelete = (id: string) => {
    if (id === "all") return;
    if (confirm("Are you sure you want to delete this parking facility?")) {
      deleteMutation.mutate(id)
    }
  }

  const deletePrinterMutation = useMutation({
    mutationFn: async (id: string) => {
      await apiClient.delete(`/api/printer/${id}`)
    },
    onSuccess: () => {
      toast.success("Printer deleted successfully")
      queryClient.invalidateQueries({ queryKey: ["printers"] })
    },
    onError: (err: any) => {
      toast.error(err.response?.data?.message || "Failed to delete printer")
    }
  })

  const handleAddPrinter = () => {
    setEditingPrinter(null)
    setPrinterModalOpen(true)
  }

  const handleEditPrinter = (printer: any) => {
    setEditingPrinter(printer)
    setPrinterModalOpen(true)
  }

  const handleDeletePrinter = (id: string) => {
    if (confirm("Are you sure you want to delete this printer?")) {
      deletePrinterMutation.mutate(id)
    }
  }

  return (
    <div className="w-full h-full flex flex-col gap-6 pb-20">
      <div className="w-full flex justify-end gap-4">
        <button 
          onClick={handleAddPrinter}
          className="h-10 px-8 rounded-xl font-black text-[11px] uppercase tracking-widest flex items-center gap-2 bg-blue-500 hover:bg-blue-600 text-white shadow-xl shadow-blue-500/20 transition-all active:scale-95"
        >
          <Icons8 icon="plus" className="w-4 h-4 invert" />
          Add Printer
        </button>
        <button 
          onClick={handleAdd}
          className="h-10 px-8 rounded-xl font-black text-[11px] uppercase tracking-widest flex items-center gap-2 bg-emerald-500 hover:bg-emerald-600 text-white shadow-xl shadow-emerald-500/20 transition-all active:scale-95"
        >
          <Icons8 icon="plus" className="w-4 h-4 invert" />
          Create New Facility
        </button>
      </div>

      <div className="w-full flex flex-col gap-8">
        
        <motion.div 
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            className="flex flex-col gap-6"
        >
            <div className="flex items-center justify-between">
                <div>
                    <h3 className="text-[18px] font-black uppercase tracking-widest text-foreground">Parking Facilities</h3>
                    <p className="text-[12px] font-bold text-muted-foreground mt-1">Manage physical parking locations and capacities across your enterprise.</p>
                </div>
            </div>

            {isLoading ? (
              <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
                {[1,2,3].map(i => (
                  <div key={i} className="h-[200px] bg-secondary/50 rounded-3xl animate-pulse" />
                ))}
              </div>
            ) : isError ? (
              <div className="p-12 text-center border border-border border-dashed rounded-3xl">
                <Icons8 icon="error" className="w-12 h-12 text-destructive opacity-50 mx-auto" />
                <p className="text-[13px] font-bold text-muted-foreground mt-3">Failed to load parking facilities.</p>
              </div>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
                  {parkingSites.map(site => (
                      <div key={site.id} className={cn(
                          "bg-card border shadow-sm rounded-3xl p-6 transition-all group",
                          activeSiteId === site.id ? "border-primary shadow-primary/10 ring-1 ring-primary/20" : "border-border"
                      )}>
                          <div className="flex items-start justify-between mb-4">
                              <div className="flex items-center gap-3">
                                  <div className={cn(
                                      "w-12 h-12 rounded-2xl flex items-center justify-center shrink-0",
                                      site.id === "all" ? "bg-emerald-500/10 text-emerald-500" : "bg-primary/10 text-primary"
                                  )}>
                                      <Icons8 icon={site.id === "all" ? "globe" : "parking"} className="w-6 h-6" />
                                  </div>
                                  <div>
                                      <h4 className="text-[14px] font-black uppercase tracking-widest text-foreground line-clamp-1">{site.name}</h4>
                                      <p className="text-[11px] font-bold text-muted-foreground line-clamp-1">{site.location}</p>
                                  </div>
                              </div>
                              <div className={cn(
                                  "px-3 py-1 rounded-full text-[9px] font-black uppercase tracking-widest border shrink-0 ml-2",
                                  site.status === "active" ? "bg-emerald-500/10 text-emerald-500 border-emerald-500/20" : "bg-amber-500/10 text-amber-500 border-amber-500/20"
                              )}>
                                  {site.status}
                              </div>
                          </div>
                          
                          <div className="flex items-start justify-between mt-6 border-t border-border/50 pt-4">
                              <div>
                                  <p className="text-[9px] font-black uppercase tracking-widest text-muted-foreground">Estimated Spaces</p>
                                  <p className="text-[16px] font-black text-foreground mt-0.5">{site.capacity} <span className="text-[12px] text-muted-foreground">Total</span></p>
                              </div>
                              
                              <div className="flex flex-col items-end text-right">
                                  <p className="text-[9px] font-black uppercase tracking-widest text-muted-foreground mb-1">Live Occupancy</p>
                                  {(!site.occupancy || site.occupancy.length === 0) ? (
                                    <p className="text-[11px] font-bold text-muted-foreground">Empty</p>
                                  ) : (
                                    <div className="flex flex-col gap-0.5">
                                      {site.occupancy.map(occ => (
                                        <p key={occ.name} className="text-[12px] font-bold text-emerald-500 flex items-center justify-end gap-1.5">
                                            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                                            {occ.count} {occ.name}
                                        </p>
                                      ))}
                                    </div>
                                  )}
                              </div>
                          </div>
                          
                          {site.id !== "all" && (
                            <div className="flex items-center justify-end gap-3 mt-4 opacity-0 group-hover:opacity-100 transition-opacity">
                              <button onClick={() => handleEdit(site)} className="w-8 h-8 rounded-full bg-secondary text-primary hover:bg-primary hover:text-white flex items-center justify-center transition-colors">
                                <Icons8 icon="edit" className="w-4 h-4" />
                              </button>
                              <button onClick={() => handleDelete(site.id)} disabled={deleteMutation.isPending} className="w-8 h-8 rounded-full bg-secondary text-destructive hover:bg-destructive hover:text-white flex items-center justify-center transition-colors disabled:opacity-50">
                                <Icons8 icon="trash" className="w-4 h-4" />
                              </button>
                            </div>
                          )}
                      </div>
                  ))}
              </div>
            )}
        </motion.div>

        {/* PRINTERS SECTION */}
        <motion.div 
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            className="flex flex-col gap-6 mt-8"
        >
            <div className="flex items-center justify-between">
                <div>
                    <h3 className="text-[18px] font-black uppercase tracking-widest text-foreground">Hardware & Printers</h3>
                    <p className="text-[12px] font-bold text-muted-foreground mt-1">Manage ESC/POS receipt printers across facilities.</p>
                </div>
            </div>

            {isPrintersLoading ? (
              <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
                {[1,2].map(i => (
                  <div key={i} className="h-[140px] bg-secondary/50 rounded-3xl animate-pulse" />
                ))}
              </div>
            ) : !printers || printers.length === 0 ? (
              <div className="p-12 text-center border border-border border-dashed rounded-3xl">
                <Icons8 icon="printer" className="w-12 h-12 text-muted-foreground opacity-50 mx-auto" />
                <p className="text-[13px] font-bold text-muted-foreground mt-3">No printers configured yet.</p>
              </div>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
                  {printers.map((printer: any) => (
                      <div key={printer.id} className="bg-card border border-border shadow-sm rounded-3xl p-6 transition-all group flex flex-col justify-between">
                          <div>
                            <div className="flex items-start justify-between mb-2">
                                <div className="flex items-center gap-3">
                                    <div className="w-12 h-12 rounded-2xl flex items-center justify-center shrink-0 bg-blue-500/10 text-blue-500">
                                        <Icons8 icon="printer" className="w-6 h-6" />
                                    </div>
                                    <div>
                                        <h4 className="text-[14px] font-black uppercase tracking-widest text-foreground line-clamp-1">{printer.name}</h4>
                                        <p className="text-[11px] font-bold text-muted-foreground line-clamp-1">{printer.ip}</p>
                                    </div>
                                </div>
                                {printer.isDefault && (
                                  <div className="px-3 py-1 rounded-full text-[9px] font-black uppercase tracking-widest border shrink-0 ml-2 bg-blue-500/10 text-blue-500 border-blue-500/20">
                                      Default
                                  </div>
                                )}
                            </div>
                            
                            <div className="flex items-start justify-between mt-4">
                                <div>
                                    <p className="text-[9px] font-black uppercase tracking-widest text-muted-foreground">Assigned Facility</p>
                                    <p className="text-[13px] font-black text-foreground mt-0.5">{printer.site?.name || "Unknown"}</p>
                                </div>
                            </div>
                          </div>
                          
                          <div className="flex items-center justify-end gap-3 mt-4 opacity-0 group-hover:opacity-100 transition-opacity pt-4 border-t border-border/50">
                            <button onClick={() => handleEditPrinter(printer)} className="w-8 h-8 rounded-full bg-secondary text-primary hover:bg-primary hover:text-white flex items-center justify-center transition-colors">
                              <Icons8 icon="edit" className="w-4 h-4" />
                            </button>
                            <button onClick={() => handleDeletePrinter(printer.id)} disabled={deletePrinterMutation.isPending} className="w-8 h-8 rounded-full bg-secondary text-destructive hover:bg-destructive hover:text-white flex items-center justify-center transition-colors disabled:opacity-50">
                              <Icons8 icon="trash" className="w-4 h-4" />
                            </button>
                          </div>
                      </div>
                  ))}
              </div>
            )}
        </motion.div>

      </div>

      <SiteModal 
        isOpen={modalOpen} 
        onClose={() => setModalOpen(false)} 
        site={editingSite} 
      />

      <PrinterModal
        isOpen={printerModalOpen}
        onClose={() => setPrinterModalOpen(false)}
        printer={editingPrinter}
        sites={parkingSites}
      />
    </div>
  )
}
