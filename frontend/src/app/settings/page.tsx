"use client"

import React, { useEffect, useState } from "react"
import { motion } from "framer-motion"
import { useBreadcrumbStore } from "@/store/useBreadcrumbStore"
import { useAppearance } from "@/providers/AppearanceProvider"
import { useTheme } from "next-themes"
import { toast } from "sonner"
import { Icons8 } from "@/components/ui/icons8"
import { cn } from "@/lib/utils"
import { useSiteStore, ParkingSite } from "@/store/useSiteStore"
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query"
import { apiClient } from "@/lib/apiClient"
import { PrinterModal } from "./PrinterModal"

const ACCENT_COLORS = [
    { label: "Sky Blue",    value: "#04a9f5" },
    { label: "Indigo",      value: "#4680ff" },
    { label: "Violet",      value: "#7c3aed" },
    { label: "Rose",        value: "#f43f5e" },
    { label: "Amber",       value: "#f59e0b" },
    { label: "Emerald",     value: "#10b981" },
    { label: "Teal",        value: "#14b8a6" },
    { label: "Orange",      value: "#f97316" },
]

const FONT_SIZES = [
    { key: "small",       label: "S",    px: "14px", desc: "Compact"   },
    { key: "normal",      label: "M",    px: "16px", desc: "Default"   },
    { key: "large",       label: "L",    px: "18px", desc: "Comfortable" },
    { key: "extra-large", label: "XL",   px: "20px", desc: "Spacious"  },
] as const

const FONT_FAMILIES = [
    { key: "geist",       label: "Geist",       preview: "Aa"  },
    { key: "inter",       label: "Inter",       preview: "Aa"  },
    { key: "outfit",      label: "Outfit",      preview: "Aa"  },
    { key: "montserrat",  label: "Montserrat",  preview: "Aa"  },
] as const

export default function SettingsPage() {
  const { setBreadcrumbs } = useBreadcrumbStore()
  const { theme, setTheme } = useTheme()
  const { 
      fontSize, setFontSize, 
      fontFamily, setFontFamily, 
      accentColor, setAccentColor, 
      sidebarTheme, setSidebarTheme, 
      themeLayout, setThemeLayout
  } = useAppearance()

  const [activeTab, setActiveTab] = useState("appearance")
  const [mounted, setMounted] = useState(false)
  const { parkingSites, activeSiteId } = useSiteStore()
  
  const queryClient = useQueryClient()
  const [printerModalOpen, setPrinterModalOpen] = useState(false)
  const [editingPrinter, setEditingPrinter] = useState<any>(null)

  const { data: printers, isLoading: isPrintersLoading } = useQuery({
    queryKey: ["printers"],
    queryFn: async () => {
      const res = await apiClient.get("/api/printer")
      return res.data
    }
  })

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
  
  const [settings, setSettings] = useState({
    smtpHost: '',
    smtpPort: 587,
    smtpUser: '',
    smtpPassword: '',
    enableEmailAlerts: false,
    twilioAccountSid: '',
    twilioAuthToken: '',
    twilioWhatsappNum: '',
    enableWhatsappAlerts: false,
    twilioSmsNum: '',
    enableSmsAlerts: false,
    enableBeemSms: false,
    beemApiKey: '',
    beemSecretKey: '',
    beemSenderId: 'INFO',
    smsTemplate: '',
    overstayTimeLimit: '08:00:00',
    overstayFineAmount: 5000,
  });
  const [isSaving, setIsSaving] = useState(false);
  const [beemBalance, setBeemBalance] = useState<string | null>(null);
  const [isCheckingBalance, setIsCheckingBalance] = useState(false);

  const handleCheckBalance = async () => {
    setIsCheckingBalance(true);
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000'}/api/settings/beem-balance`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('parking-auth-token')}`
        }
      });
      const data = await res.json();
      if (data.error) {
        setBeemBalance(`Error: ${data.error}`);
      } else if (data.data?.credit_balance !== undefined) {
        setBeemBalance(data.data.credit_balance.toString());
      } else if (data.data?.balance !== undefined) {
        setBeemBalance(data.data.balance.toString());
      } else {
        setBeemBalance("Balance info unavailable");
      }
    } catch (e) {
      setBeemBalance("Network error");
    }
    setIsCheckingBalance(false);
  };

  useEffect(() => {
    setMounted(true)
    setBreadcrumbs([
      { label: "Dashboard", href: "/" },
      { label: "Administration", href: "/settings" }
    ])
    


    fetch(`${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000'}/api/settings`)
      .then(res => res.json())
      .then(data => {
         if (data) {
           setSettings({
             smtpHost: data.smtpHost || '',
             smtpPort: data.smtpPort || 587,
             smtpUser: data.smtpUser || '',
             smtpPassword: data.smtpPassword || '',
             enableEmailAlerts: data.enableEmailAlerts || false,
             twilioAccountSid: data.twilioAccountSid || '',
             twilioAuthToken: data.twilioAuthToken || '',
             twilioWhatsappNum: data.twilioWhatsappNum || '',
             enableWhatsappAlerts: data.enableWhatsappAlerts || false,
             twilioSmsNum: data.twilioSmsNum || '',
             enableSmsAlerts: data.enableSmsAlerts || false,
             enableBeemSms: data.enableBeemSms || false,
             beemApiKey: data.beemApiKey || '',
             beemSecretKey: data.beemSecretKey || '',
             beemSenderId: data.beemSenderId || 'INFO',
             smsTemplate: data.smsTemplate || '',
             overstayTimeLimit: data.overstayTimeLimit || '08:00:00',
             overstayFineAmount: data.overstayFineAmount || 5000,
           });
         }
      })
      .catch(err => console.error("Failed to load settings", err));
  }, [setBreadcrumbs])

  const handleSave = async () => {
    setIsSaving(true);
    try {
       await fetch(`${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000'}/api/settings`, {
         method: 'POST',
         headers: { 'Content-Type': 'application/json' },
         body: JSON.stringify(settings)
       });
       // Optional: Show success toast
    } catch (e) {
       console.error(e);
    }
    setIsSaving(false);
  }

  const handleExport = async () => {
    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000'}/api/backup/export`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('parking-auth-token')}`
        }
      });
      if (!response.ok) throw new Error("Export failed");
      
      const blob = await response.blob();
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      const dateStr = new Date().toISOString().split('T')[0];
      link.setAttribute('download', `nparking-backup-${dateStr}.json`);
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      toast.success("Backup downloaded successfully!");
    } catch (e) {
      toast.error("Failed to download backup");
      console.error(e);
    }
  };

  const handleImport = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (!confirm("WARNING: This will WIPE the current database and completely replace it with the backup file. Any data created after the backup will be lost forever. Are you absolutely sure you want to proceed?")) {
      e.target.value = ''; // Reset input
      return;
    }

    const formData = new FormData();
    formData.append('file', file);

    const loadingToast = toast.loading("Restoring database from backup...");
    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000'}/api/backup/import`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('parking-auth-token')}`
        },
        body: formData
      });
      
      const data = await response.json();
      if (response.ok && data.success) {
        toast.success("Database restored successfully!", { id: loadingToast });
        setTimeout(() => window.location.reload(), 1500);
      } else {
        throw new Error(data.message || "Unknown error");
      }
    } catch (e: any) {
      toast.error("Failed to restore backup: " + e.message, { id: loadingToast });
      console.error(e);
    }
    e.target.value = ''; // Reset input
  };

  const handleReset = async () => {
    if (!confirm("FACTORY RESET WARNING: This will immediately delete ALL data in the system (Vehicles, Users, Settings, Payments) and re-create a default admin user. THIS CANNOT BE UNDONE. Are you 100% sure you want to proceed?")) {
      return;
    }

    const verifyPrompt = prompt("Type 'RESET' to confirm you want to delete all data:");
    if (verifyPrompt !== 'RESET') {
      toast.error("Reset cancelled. You didn't type 'RESET'.");
      return;
    }

    const loadingToast = toast.loading("Wiping database and resetting to factory defaults...");
    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000'}/api/backup/reset`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('parking-auth-token')}`
        }
      });
      
      const data = await response.json();
      if (response.ok && data.success) {
        toast.success("Factory Reset successful! You will be logged out.", { id: loadingToast });
        localStorage.removeItem('parking-auth-token');
        setTimeout(() => window.location.href = '/login', 2000);
      } else {
        throw new Error(data.message || "Unknown error");
      }
    } catch (e: any) {
      toast.error("Failed to factory reset: " + e.message, { id: loadingToast });
      console.error(e);
    }
  };

  if (!mounted) return null;

  return (
    <div className="w-full h-full flex flex-col gap-6 pb-20">
      {/* Header Area */}
      <div className="w-full flex justify-end">
        <button onClick={handleSave} disabled={isSaving} className="h-10 px-8 rounded-xl font-black text-[11px] uppercase tracking-widest flex items-center gap-2 bg-emerald-500 hover:bg-emerald-600 text-white shadow-xl shadow-emerald-500/20 transition-all active:scale-95 disabled:opacity-50">
          <Icons8 icon={isSaving ? "spinner" : "save"} className={cn("w-4 h-4 invert", isSaving && "animate-spin")} />
          {isSaving ? "Saving..." : "Save"}
        </button>
      </div>

      <div className="w-full flex flex-col lg:flex-row gap-8">
        
        {/* Navigation Tabs */}
        <div className="w-full lg:w-64 shrink-0 flex flex-col gap-2">
           {[
             { value: "appearance",   icon: "paint-palette",  label: "Appearance"   },
             { value: "general",      icon: "combo-chart",    label: "General"      },
             { value: "security",     icon: "lock",   label: "Security"     },
             { value: "notifications",icon: "bell",     label: "Notifications"},
             { value: "printers",     icon: "printer",  label: "Printers"     },
             { value: "backup",       icon: "synchronize",  label: "Backup & Restore" },
           ].map(tab => (
             <button
               key={tab.value}
               onClick={() => setActiveTab(tab.value)}
               className={cn(
                 "w-full flex items-center gap-3 px-5 py-4 rounded-2xl transition-all border text-left",
                 activeTab === tab.value 
                  ? "bg-primary text-white border-primary shadow-lg shadow-primary/20" 
                  : "bg-card border-border hover:bg-secondary/30 text-muted-foreground hover:text-foreground"
               )}
             >
                <Icons8 icon={tab.icon} className={cn("w-5 h-5", activeTab === tab.value && "invert")} />
                <span className="text-[11px] font-black uppercase tracking-widest">{tab.label}</span>
             </button>
           ))}
        </div>

        {/* Tab Content */}
        <div className="flex-1 w-full">
          {activeTab === "appearance" && (
            <motion.div 
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              className="grid grid-cols-1 xl:grid-cols-2 gap-8"
            >
              {/* Interface Mode & Styles */}
              <div className="bg-card border border-border shadow-sm rounded-3xl overflow-hidden flex flex-col">
                <div className="p-5 border-b border-border/50 bg-secondary/5 flex items-center gap-3">
                    <div className="p-2 rounded-xl bg-indigo-500/10 border border-indigo-500/20">
                        <Icons8 icon="paint-palette" className="w-5 h-5 text-indigo-500" />
                    </div>
                    <div>
                        <h3 className="text-[13px] font-black uppercase tracking-tight text-foreground">Interface Mode</h3>
                        <p className="text-[10px] font-bold text-muted-foreground">Choose the visual theme of the platform</p>
                    </div>
                </div>
                
                <div className="p-6 space-y-8">
                    {/* Theme Mode */}
                    <div className="grid grid-cols-3 gap-3">
                        {[
                            { value: "light",  icon: "sun",     label: "Light"  },
                            { value: "dark",   icon: "moon-symbol",    label: "Dark"   },
                            { value: "system", icon: "monitor", label: "System" },
                        ].map(m => (
                            <button
                                key={m.value}
                                onClick={() => setTheme(m.value)}
                                className={cn(
                                    "py-5 rounded-2xl border transition-all flex flex-col items-center gap-3 group relative overflow-hidden",
                                    theme === m.value
                                        ? "bg-primary border-primary shadow-lg shadow-primary/20 text-white"
                                        : "bg-secondary/10 border-border hover:bg-secondary/30 text-foreground"
                                )}
                            >
                                <Icons8 icon={m.icon} className={cn("w-6 h-6 relative z-10", theme === m.value && "invert")} />
                                <span className="text-[10px] font-black uppercase tracking-widest relative z-10">{m.label}</span>
                                {theme === m.value && <Icons8 icon="checkmark" className="w-4 h-4 invert absolute top-2 right-2 opacity-80" />}
                            </button>
                        ))}
                    </div>

                    <div className="h-px w-full bg-border/50" />

                    {/* Sidebar Theme & Layout */}
                    <div className="grid grid-cols-2 gap-8">
                        {/* Sidebar Theme */}
                        <div className="space-y-3">
                            <label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">Sidebar Style</label>
                            <div className="flex flex-col gap-3">
                                {(["dark","light"] as const).map(s => (
                                    <button
                                        key={s}
                                        onClick={() => setSidebarTheme(s)}
                                        className={cn(
                                            "p-4 rounded-2xl border transition-all flex items-center justify-between",
                                            sidebarTheme === s
                                                ? "bg-primary/10 border-primary text-primary font-black"
                                                : "bg-secondary/10 border-border text-muted-foreground font-bold"
                                        )}
                                    >
                                        <div className="flex items-center gap-3">
                                            <Icons8 icon={s === "dark" ? "moon-symbol" : "sun"} className={cn("w-4 h-4", sidebarTheme === s ? "text-primary" : "text-muted-foreground")} />
                                            <span className="text-[11px] uppercase tracking-widest font-black capitalize">{s}</span>
                                        </div>
                                        {sidebarTheme === s && <Icons8 icon="checkmark" className="w-4 h-4 text-primary" />}
                                    </button>
                                ))}
                            </div>
                        </div>

                        {/* Layout Direction */}
                        <div className="space-y-3">
                            <label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">Layout Direction</label>
                            <div className="flex flex-col gap-3">
                                {(["ltr","rtl"] as const).map(dir => (
                                    <button
                                        key={dir}
                                        onClick={() => setThemeLayout(dir)}
                                        className={cn(
                                            "p-4 rounded-2xl border transition-all flex items-center justify-between",
                                            themeLayout === dir
                                                ? "bg-primary/10 border-primary text-primary font-black"
                                                : "bg-secondary/10 border-border text-muted-foreground font-bold"
                                        )}
                                    >
                                        <div className="flex items-center gap-3">
                                            <Icons8 icon={dir === "ltr" ? "align-left" : "align-right"} className={cn("w-4 h-4", themeLayout === dir ? "text-primary" : "text-muted-foreground")} />
                                            <span className="text-[11px] uppercase tracking-widest font-black">{dir.toUpperCase()}</span>
                                        </div>
                                        {themeLayout === dir && <Icons8 icon="checkmark" className="w-4 h-4 text-primary" />}
                                    </button>
                                ))}
                            </div>
                        </div>
                    </div>
                </div>
              </div>

              {/* Typography & Colors */}
              <div className="flex flex-col gap-8">
                  {/* Typography */}
                  <div className="bg-card border border-border shadow-sm rounded-3xl overflow-hidden">
                      <div className="p-5 border-b border-border/50 bg-secondary/5 flex items-center gap-3">
                          <div className="p-2 rounded-xl bg-violet-500/10 border border-violet-500/20">
                              <Icons8 icon="type" className="w-5 h-5 text-violet-500" />
                          </div>
                          <div>
                              <h3 className="text-[13px] font-black uppercase tracking-tight text-foreground">Typography</h3>
                              <p className="text-[10px] font-bold text-muted-foreground">Font family and global text scaling</p>
                          </div>
                      </div>
                      <div className="p-6 space-y-8">
                          {/* Font Family */}
                          <div className="space-y-3">
                              <label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">Font Family</label>
                              <div className="grid grid-cols-2 gap-3">
                                  {FONT_FAMILIES.map(f => (
                                      <button
                                          key={f.key}
                                          onClick={() => setFontFamily(f.key as any)}
                                          className={cn(
                                              "py-4 px-5 rounded-2xl border transition-all flex items-center justify-between",
                                              fontFamily === f.key
                                                  ? "bg-primary/10 border-primary text-primary"
                                                  : "bg-secondary/10 border-border text-foreground/70 hover:bg-secondary/30"
                                          )}
                                      >
                                          <span className="text-[12px] font-black uppercase tracking-tight">{f.label}</span>
                                          {fontFamily === f.key && <Icons8 icon="checkmark" className="w-4 h-4 text-primary" />}
                                      </button>
                                  ))}
                              </div>
                          </div>

                          {/* Font Size */}
                          <div className="space-y-3">
                              <div className="flex items-center justify-between">
                                  <label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">Font Size</label>
                                  <span className="text-[10px] font-bold text-primary bg-primary/10 px-2 py-0.5 rounded-full">{FONT_SIZES.find(s => s.key === fontSize)?.px}</span>
                              </div>
                              <div className="grid grid-cols-4 gap-2">
                                  {FONT_SIZES.map(s => (
                                      <button
                                          key={s.key}
                                          onClick={() => setFontSize(s.key as any)}
                                          className={cn(
                                              "py-4 rounded-2xl border transition-all flex flex-col items-center justify-center gap-1",
                                              fontSize === s.key
                                                  ? "bg-primary border-primary text-white shadow-lg shadow-primary/20"
                                                  : "bg-secondary/10 border-border hover:bg-secondary/30"
                                          )}
                                      >
                                          <span className="text-[14px] font-black">{s.label}</span>
                                          <span className={cn("text-[9px] font-bold uppercase tracking-widest", fontSize === s.key ? "text-white/80" : "text-muted-foreground")}>
                                              {s.px}
                                          </span>
                                      </button>
                                  ))}
                              </div>
                          </div>

                          {/* Preview Area */}
                          <div className="mt-6 p-5 bg-secondary/10 border border-border/50 rounded-2xl">
                              <p className="text-[9px] font-black uppercase tracking-widest text-muted-foreground mb-3">Live Preview</p>
                              <p className="font-medium text-foreground">
                                  The quick brown fox jumps over the lazy dog. Smart Parking Management System dashboard preview.
                              </p>
                          </div>
                      </div>
                  </div>

                  {/* Accent Color */}
                  <div className="bg-card border border-border shadow-sm rounded-3xl overflow-hidden">
                      <div className="p-5 border-b border-border/50 bg-secondary/5 flex items-center gap-3">
                          <div className="p-2 rounded-xl bg-pink-500/10 border border-pink-500/20">
                              <Icons8 icon="rgb-circle-1" className="w-5 h-5 text-pink-500" />
                          </div>
                          <div>
                              <h3 className="text-[13px] font-black uppercase tracking-tight text-foreground">Accent Color</h3>
                              <p className="text-[10px] font-bold text-muted-foreground">Primary brand color used across the platform</p>
                          </div>
                      </div>
                      <div className="p-6">
                          <div className="grid grid-cols-4 gap-4">
                              {ACCENT_COLORS.map(color => (
                                  <button
                                      key={color.label}
                                      onClick={() => setAccentColor(color.value)}
                                      className={cn(
                                          "flex flex-col items-center justify-center gap-3 p-3 rounded-2xl border transition-all hover:bg-secondary/20",
                                          accentColor === color.value ? "border-primary bg-primary/5" : "border-transparent"
                                      )}
                                  >
                                      <div 
                                          className={cn(
                                              "w-10 h-10 rounded-full flex items-center justify-center shadow-inner transition-transform",
                                              accentColor === color.value ? "scale-110 shadow-lg" : "hover:scale-105"
                                          )}
                                          style={{ backgroundColor: color.value, boxShadow: accentColor === color.value ? `0 4px 14px 0 ${color.value}40` : '' }}
                                      >
                                          {accentColor === color.value && <Icons8 icon="checkmark" className="w-4 h-4 invert" />}
                                      </div>
                                      <span className={cn(
                                          "text-[9px] font-black uppercase tracking-widest",
                                          accentColor === color.value ? "text-primary" : "text-muted-foreground"
                                      )}>{color.label}</span>
                                  </button>
                              ))}
                          </div>
                      </div>
                  </div>
              </div>
            </motion.div>
          )}

          {activeTab === "notifications" && (
            <motion.div 
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              className="flex flex-col gap-8"
            >
              <div className="bg-card border border-border shadow-sm rounded-3xl overflow-hidden">
                <div className="p-5 border-b border-border/50 bg-secondary/5 flex items-center gap-3">
                  <div className="p-2 rounded-xl bg-orange-500/10 border border-orange-500/20">
                    <Icons8 icon="bell" className="w-5 h-5 text-orange-500" />
                  </div>
                  <div>
                    <h3 className="text-[13px] font-black uppercase tracking-tight text-foreground">Email Notifications</h3>
                    <p className="text-[10px] font-bold text-muted-foreground">Configure SMTP server for sending emails to users</p>
                  </div>
                </div>
                
                <div className="p-6 space-y-6">
                  <div className="flex items-center justify-between">
                    <div>
                      <h4 className="text-[11px] font-black uppercase tracking-widest text-foreground">Enable Email Alerts</h4>
                      <p className="text-[10px] text-muted-foreground">Turn on to allow the system to send emails (like passwords)</p>
                    </div>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input type="checkbox" className="sr-only peer" checked={settings.enableEmailAlerts} onChange={(e) => setSettings({...settings, enableEmailAlerts: e.target.checked})} />
                      <div className="w-11 h-6 bg-secondary peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-emerald-500"></div>
                    </label>
                  </div>

                  <div className="h-px w-full bg-border/50" />

                  <div className="grid grid-cols-2 gap-6">
                    <div className="space-y-2">
                      <label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">SMTP Host</label>
                      <input 
                        type="text" 
                        value={settings.smtpHost || ''} 
                        onChange={(e) => setSettings({...settings, smtpHost: e.target.value})}
                        className="w-full h-11 bg-secondary/30 border border-border rounded-xl px-4 text-sm font-medium focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all" 
                        placeholder="smtp.gmail.com" 
                      />
                    </div>
                    <div className="space-y-2">
                      <label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">SMTP Port</label>
                      <input 
                        type="number" 
                        value={settings.smtpPort || ''} 
                        onChange={(e) => setSettings({...settings, smtpPort: parseInt(e.target.value) || 0})}
                        className="w-full h-11 bg-secondary/30 border border-border rounded-xl px-4 text-sm font-medium focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all" 
                        placeholder="587" 
                      />
                    </div>
                    <div className="space-y-2">
                      <label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">SMTP User (Email)</label>
                      <input 
                        type="email" 
                        value={settings.smtpUser || ''} 
                        onChange={(e) => setSettings({...settings, smtpUser: e.target.value})}
                        className="w-full h-11 bg-secondary/30 border border-border rounded-xl px-4 text-sm font-medium focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all" 
                        placeholder="parking@company.com" 
                      />
                    </div>
                    <div className="space-y-2">
                      <label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">SMTP App Password</label>
                      <input 
                        type="password" 
                        value={settings.smtpPassword || ''} 
                        onChange={(e) => setSettings({...settings, smtpPassword: e.target.value})}
                        className="w-full h-11 bg-secondary/30 border border-border rounded-xl px-4 text-sm font-medium focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all" 
                        placeholder="••••••••••••" 
                      />
                    </div>
                  </div>
                </div>
              </div>

              <div className="bg-card border border-border shadow-sm rounded-3xl overflow-hidden mt-8">
                <div className="p-5 border-b border-border/50 bg-secondary/5 flex items-center gap-3">
                  <div className="p-2 rounded-xl bg-emerald-500/10 border border-emerald-500/20">
                    <Icons8 icon="whatsapp" className="w-5 h-5 text-emerald-500" />
                  </div>
                  <div>
                    <h3 className="text-[13px] font-black uppercase tracking-tight text-foreground">WhatsApp Notifications (Twilio)</h3>
                    <p className="text-[10px] font-bold text-muted-foreground">Configure Twilio API credentials to automatically message vehicle owners.</p>
                  </div>
                </div>
                
                <div className="p-6 space-y-6">
                  <div className="flex items-center justify-between">
                    <div>
                      <h4 className="text-[11px] font-black uppercase tracking-widest text-foreground">Enable WhatsApp Alerts</h4>
                      <p className="text-[10px] text-muted-foreground">Turn on to allow the system to send digital tickets via WhatsApp.</p>
                    </div>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input type="checkbox" className="sr-only peer" checked={settings.enableWhatsappAlerts} onChange={(e) => setSettings({...settings, enableWhatsappAlerts: e.target.checked})} />
                      <div className="w-11 h-6 bg-secondary peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-emerald-500"></div>
                    </label>
                  </div>

                  <div className="h-px w-full bg-border/50" />

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div className="space-y-2 md:col-span-2">
                      <label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">Twilio Account SID</label>
                      <input 
                        type="text" 
                        value={settings.twilioAccountSid || ''} 
                        onChange={(e) => setSettings({...settings, twilioAccountSid: e.target.value})}
                        className="w-full h-11 bg-secondary/30 border border-border rounded-xl px-4 text-sm font-medium focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all font-mono" 
                        placeholder="ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" 
                      />
                    </div>
                    <div className="space-y-2">
                      <label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">Twilio Auth Token</label>
                      <input 
                        type="password" 
                        value={settings.twilioAuthToken || ''} 
                        onChange={(e) => setSettings({...settings, twilioAuthToken: e.target.value})}
                        className="w-full h-11 bg-secondary/30 border border-border rounded-xl px-4 text-sm font-medium focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all font-mono" 
                        placeholder="••••••••••••••••••••••••••••••••" 
                      />
                    </div>
                    <div className="space-y-2">
                      <label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">WhatsApp Sender Number</label>
                      <input 
                        type="tel" 
                        value={settings.twilioWhatsappNum || ''} 
                        onChange={(e) => setSettings({...settings, twilioWhatsappNum: e.target.value})}
                        className="w-full h-11 bg-secondary/30 border border-border rounded-xl px-4 text-sm font-medium focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all font-mono" 
                        placeholder="+14155238886" 
                      />
                    </div>
                  </div>
                </div>
              </div>

              <div className="bg-card border border-border shadow-sm rounded-3xl overflow-hidden mt-8">
                <div className="p-5 border-b border-border/50 bg-secondary/5 flex items-center gap-3">
                  <div className="p-2 rounded-xl bg-blue-500/10 border border-blue-500/20">
                    <Icons8 icon="speech-bubble" className="w-5 h-5 text-blue-500" />
                  </div>
                  <div>
                    <h3 className="text-[13px] font-black uppercase tracking-tight text-foreground">Standard SMS (Twilio)</h3>
                    <p className="text-[10px] font-bold text-muted-foreground">Send standard text messages to users using your Twilio SMS number.</p>
                  </div>
                </div>
                
                <div className="p-6 space-y-6">
                  <div className="flex items-center justify-between">
                    <div>
                      <h4 className="text-[11px] font-black uppercase tracking-widest text-foreground">Enable SMS Alerts</h4>
                      <p className="text-[10px] text-muted-foreground">Turn on to allow the system to send standard SMS texts.</p>
                    </div>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input type="checkbox" className="sr-only peer" checked={settings.enableSmsAlerts} onChange={(e) => setSettings({...settings, enableSmsAlerts: e.target.checked})} />
                      <div className="w-11 h-6 bg-secondary peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-emerald-500"></div>
                    </label>
                  </div>

                  <div className="h-px w-full bg-border/50" />

                  <div className="grid grid-cols-1 gap-6">
                    <div className="space-y-2">
                      <label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">Twilio SMS Sender Number</label>
                      <input 
                        type="tel" 
                        value={settings.twilioSmsNum || ''} 
                        onChange={(e) => setSettings({...settings, twilioSmsNum: e.target.value})}
                        className="w-full h-11 bg-secondary/30 border border-border rounded-xl px-4 text-sm font-medium focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all font-mono" 
                        placeholder="+1507502..." 
                      />
                      <p className="text-[9px] font-bold text-muted-foreground mt-1">
                        We will securely reuse the Account SID and Auth Token you configured above for WhatsApp.
                      </p>
                    </div>
                  </div>
                </div>
              </div>

              <div className="bg-card border border-border shadow-sm rounded-3xl overflow-hidden mt-8">
                <div className="p-5 border-b border-border/50 bg-secondary/5 flex items-center gap-3">
                  <div className="p-2 rounded-xl bg-orange-500/10 border border-orange-500/20">
                    <Icons8 icon="messaging" className="w-5 h-5 text-orange-500" />
                  </div>
                  <div>
                    <h3 className="text-[13px] font-black uppercase tracking-tight text-foreground">SMS Notifications (Beem Africa)</h3>
                    <p className="text-[10px] font-bold text-muted-foreground">Send text messages locally using Beem Africa SMS Gateway API keys.</p>
                  </div>
                </div>
                
                <div className="p-6 space-y-6">
                  <div className="flex items-center justify-between">
                    <div>
                      <h4 className="text-[11px] font-black uppercase tracking-widest text-foreground">Enable Beem Africa SMS</h4>
                      <p className="text-[10px] text-muted-foreground">Turn on to deliver SMS notifications using Beem Africa API.</p>
                    </div>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input type="checkbox" className="sr-only peer" checked={settings.enableBeemSms} onChange={(e) => setSettings({...settings, enableBeemSms: e.target.checked})} />
                      <div className="w-11 h-6 bg-secondary peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-emerald-500"></div>
                    </label>
                  </div>

                  <div className="h-px w-full bg-border/50" />

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div className="space-y-2 md:col-span-2">
                      <label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">Beem API Key</label>
                      <input 
                        type="text" 
                        value={settings.beemApiKey || ''} 
                        onChange={(e) => setSettings({...settings, beemApiKey: e.target.value})}
                        className="w-full h-11 bg-secondary/30 border border-border rounded-xl px-4 text-sm font-medium focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all font-mono" 
                        placeholder="e.g. 5b11a94200..." 
                      />
                    </div>
                    <div className="space-y-2">
                      <label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">Beem Secret Key</label>
                      <input 
                        type="password" 
                        value={settings.beemSecretKey || ''} 
                        onChange={(e) => setSettings({...settings, beemSecretKey: e.target.value})}
                        className="w-full h-11 bg-secondary/30 border border-border rounded-xl px-4 text-sm font-medium focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all font-mono" 
                        placeholder="••••••••••••••••" 
                      />
                    </div>
                    <div className="space-y-2">
                      <label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">Beem Sender ID (Sender Name)</label>
                      <input 
                        type="text" 
                        value={settings.beemSenderId || ''} 
                        onChange={(e) => setSettings({...settings, beemSenderId: e.target.value})}
                        className="w-full h-11 bg-secondary/30 border border-border rounded-xl px-4 text-sm font-medium focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all font-mono" 
                        placeholder="e.g. INFO or approved Sender ID" 
                      />
                    </div>

                    <div className="space-y-2">
                      <label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">Current SMS Balance</label>
                      <div className="flex items-center gap-4 h-11">
                        <button 
                          onClick={handleCheckBalance} 
                          disabled={isCheckingBalance}
                          className="h-full px-6 rounded-xl font-black text-[11px] uppercase tracking-widest bg-orange-500/10 text-orange-500 hover:bg-orange-500/20 transition-all flex items-center gap-2"
                        >
                          <Icons8 icon={isCheckingBalance ? "spinner" : "synchronize"} className={cn("w-4 h-4", isCheckingBalance && "animate-spin")} />
                          Check Balance
                        </button>
                        {beemBalance && (
                          <span className="text-sm font-black text-foreground">
                            {beemBalance} {beemBalance.includes('Error') ? '' : 'SMS'}
                          </span>
                        )}
                      </div>
                    </div>
                    
                    <div className="space-y-2 md:col-span-2">
                      <div className="flex flex-col md:flex-row md:items-center justify-between gap-1">
                        <label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">Check-in SMS Message Template</label>
                        <span className="text-[9px] font-bold text-primary font-mono select-all">Variables: {`{plateNumber}, {categoryName}, {siteName}, {driverName}, {checkInTime}, {amountDue}, {ticketCode}, {propertiesLeft}`}</span>
                      </div>
                      <textarea 
                        value={settings.smsTemplate || ''} 
                        onChange={(e) => setSettings({...settings, smsTemplate: e.target.value})}
                        rows={3}
                        className="w-full bg-secondary/30 border border-border rounded-2xl p-4 text-xs font-semibold focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all" 
                        placeholder="e.g. Nparking: Vehicle {plateNumber} checked in at {siteName}. {propertiesLeft} Code: {ticketCode}." 
                      />
                    </div>
                  </div>
                </div>
              </div>
            </motion.div>
          )}

          {activeTab === "general" && (
            <motion.div 
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              className="flex flex-col gap-8"
            >
              <div className="bg-card border border-border shadow-sm rounded-3xl overflow-hidden">
                <div className="p-5 border-b border-border/50 bg-secondary/5 flex items-center gap-3">
                  <div className="p-2 rounded-xl bg-indigo-500/10 border border-indigo-500/20">
                    <Icons8 icon="time" className="w-5 h-5 text-indigo-500" />
                  </div>
                  <div>
                    <h3 className="text-[13px] font-black uppercase tracking-tight text-foreground">Parking Rules & Fines</h3>
                    <p className="text-[10px] font-bold text-muted-foreground">Configure checkout limits and automatic penalties for overstaying vehicles.</p>
                  </div>
                </div>
                
                <div className="p-6 space-y-6">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div className="space-y-2">
                      <label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">Checkout Deadline</label>
                      <input 
                        type="time" 
                        value={settings.overstayTimeLimit || '08:00:00'} 
                        onChange={(e) => setSettings({...settings, overstayTimeLimit: e.target.value})}
                        className="w-full h-11 bg-secondary/30 border border-border rounded-xl px-4 text-sm font-medium focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all font-mono" 
                      />
                      <p className="text-[9px] font-bold text-muted-foreground mt-1">
                        Vehicles must be checked out before this time on their expected departure day to avoid a fine.
                      </p>
                    </div>
                    <div className="space-y-2">
                      <label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">Overstay Penalty (TZS)</label>
                      <input 
                        type="number" 
                        value={settings.overstayFineAmount || ''} 
                        onChange={(e) => setSettings({...settings, overstayFineAmount: parseInt(e.target.value) || 0})}
                        className="w-full h-11 bg-secondary/30 border border-border rounded-xl px-4 text-sm font-medium focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all font-mono" 
                        placeholder="5000" 
                      />
                      <p className="text-[9px] font-bold text-muted-foreground mt-1">
                        This fine is automatically added to the total when scanning a late checkout.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </motion.div>
          )}

          {activeTab === "printers" && (
            <motion.div 
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              className="flex flex-col gap-6"
            >
              <div className="flex items-center justify-between mb-4">
                  <div>
                      <h3 className="text-[18px] font-black uppercase tracking-widest text-foreground">Hardware & Printers</h3>
                      <p className="text-[12px] font-bold text-muted-foreground mt-1">Manage ESC/POS receipt printers across facilities.</p>
                  </div>
                  <button 
                    onClick={handleAddPrinter}
                    className="h-10 px-8 rounded-xl font-black text-[11px] uppercase tracking-widest flex items-center gap-2 bg-blue-500 hover:bg-blue-600 text-white shadow-xl shadow-blue-500/20 transition-all active:scale-95"
                  >
                    <Icons8 icon="plus" className="w-4 h-4 invert" />
                    Add Printer
                  </button>
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
                                      <p className="text-[13px] font-black text-foreground mt-0.5">{parkingSites.find(s => s.id === printer.siteId)?.name || printer.site?.name || "Unknown"}</p>
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
          )}

          {activeTab === "backup" && (
            <motion.div 
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              className="space-y-8"
            >
              <div className="bg-card border border-border shadow-sm rounded-3xl overflow-hidden flex flex-col">
                <div className="p-5 border-b border-border/50 bg-emerald-500/5 flex items-center gap-3">
                    <div className="p-2 rounded-xl bg-emerald-500/10 border border-emerald-500/20">
                        <Icons8 icon="export-csv" className="w-5 h-5 text-emerald-500" />
                    </div>
                    <div>
                        <h3 className="text-[13px] font-black uppercase tracking-tight text-foreground">Data Export</h3>
                        <p className="text-[10px] font-bold text-muted-foreground">Download a complete snapshot of the system database</p>
                    </div>
                </div>
                <div className="p-6">
                    <p className="text-xs text-muted-foreground mb-6">
                      Exporting creates a JSON backup of all vehicles, users, sessions, settings, and expenses currently in the database. 
                      You can keep this file safe offline and use it to restore the system if anything goes wrong.
                    </p>
                    <button onClick={handleExport} className="px-6 py-3 bg-emerald-500 text-white rounded-xl text-xs font-bold uppercase tracking-widest hover:bg-emerald-600 transition-all shadow-xl shadow-emerald-500/20 flex items-center gap-2">
                      <Icons8 icon="save" className="w-4 h-4 invert" />
                      Download Full Backup
                    </button>
                </div>
              </div>

              <div className="bg-card border border-red-500/30 shadow-sm rounded-3xl overflow-hidden flex flex-col">
                <div className="p-5 border-b border-red-500/20 bg-red-500/5 flex items-center gap-3">
                    <div className="p-2 rounded-xl bg-red-500/10 border border-red-500/20">
                        <Icons8 icon="warning-shield" className="w-5 h-5 text-red-500" />
                    </div>
                    <div>
                        <h3 className="text-[13px] font-black uppercase tracking-tight text-red-500">System Restore</h3>
                        <p className="text-[10px] font-bold text-red-500/70">Wipe and replace current data with a backup file</p>
                    </div>
                </div>
                <div className="p-6">
                    <div className="p-4 bg-red-500/10 border border-red-500/20 rounded-xl mb-6">
                      <h4 className="text-xs font-bold text-red-500 flex items-center gap-2 mb-1">
                        <Icons8 icon="error" className="w-4 h-4 text-red-500" />
                        DANGER ZONE
                      </h4>
                      <p className="text-[11px] text-red-500/80 font-medium">
                        Restoring a backup will instantly drop the current active database and replace it with the backup contents. Any data generated after the backup was created will be permanently lost.
                      </p>
                    </div>
                    
                    <div className="relative inline-block">
                      <input 
                        type="file" 
                        accept=".json" 
                        onChange={handleImport}
                        className="absolute inset-0 w-full h-full opacity-0 cursor-pointer z-10" 
                      />
                      <button className="px-6 py-3 bg-red-500 text-white rounded-xl text-xs font-bold uppercase tracking-widest hover:bg-red-600 transition-all shadow-xl shadow-red-500/20 flex items-center gap-2 pointer-events-none">
                        <Icons8 icon="synchronize" className="w-4 h-4 invert" />
                        Select Backup to Restore
                      </button>
                    </div>
                </div>
              </div>

              {/* FACTORY RESET CARD */}
              <div className="bg-card border border-red-500/50 shadow-sm rounded-3xl overflow-hidden flex flex-col">
                <div className="p-5 border-b border-red-500/20 bg-red-500/5 flex items-center gap-3">
                    <div className="p-2 rounded-xl bg-red-500/20 border border-red-500/30">
                        <Icons8 icon="error" className="w-5 h-5 text-red-500" />
                    </div>
                    <div>
                        <h3 className="text-[13px] font-black uppercase tracking-tight text-red-500">Factory Reset</h3>
                        <p className="text-[10px] font-bold text-red-500/70">Completely wipe system and restore default settings</p>
                    </div>
                </div>
                <div className="p-6">
                    <div className="p-4 bg-red-500/20 border border-red-500/30 rounded-xl mb-6">
                      <h4 className="text-xs font-black text-red-600 flex items-center gap-2 mb-1">
                        <Icons8 icon="siren" className="w-5 h-5 text-red-600 animate-pulse" />
                        EXTREME DANGER
                      </h4>
                      <p className="text-[11px] text-red-600/90 font-medium">
                        This action will immediately permanently delete EVERY SINGLE RECORD in your database. All users, all vehicles, all parking sessions, and all financial data will be permanently wiped. A single default admin account will be recreated.
                      </p>
                    </div>
                    
                    <button onClick={handleReset} className="px-6 py-3 bg-red-600 text-white rounded-xl text-xs font-bold uppercase tracking-widest hover:bg-red-700 transition-all shadow-xl shadow-red-600/30 flex items-center gap-2">
                      <Icons8 icon="multiply" className="w-4 h-4 invert" />
                      Execute Factory Reset
                    </button>
                </div>
              </div>
            </motion.div>
          )}

          {activeTab !== "appearance" && activeTab !== "notifications" && activeTab !== "general" && activeTab !== "printers" && activeTab !== "backup" && (
             <div className="flex flex-col items-center justify-center h-[400px] border border-dashed border-border rounded-3xl bg-card/30">
               <Icons8 icon="road-worker" className="w-16 h-16 opacity-20 mb-4" />
               <h3 className="text-sm font-black tracking-widest uppercase text-muted-foreground">Module Under Construction</h3>
               <p className="text-[11px] font-bold text-muted-foreground/50 uppercase mt-2 text-center max-w-sm">
                 The {activeTab} module is currently being built for the Parking System architecture.
               </p>
             </div>
          )}
        </div>

      </div>

      <PrinterModal
        isOpen={printerModalOpen}
        onClose={() => setPrinterModalOpen(false)}
        printer={editingPrinter}
        sites={parkingSites}
      />
    </div>
  )
}
