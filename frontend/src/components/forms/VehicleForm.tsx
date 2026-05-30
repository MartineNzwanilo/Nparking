"use client"

import { useState } from "react"
import { useQuery, useQueryClient } from "@tanstack/react-query"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Car, Fingerprint, Calendar, User, Zap } from "lucide-react"
import { toast } from "sonner"

interface VehicleFormProps {
    initialData?: any
    onSuccess: () => void
}

export function VehicleForm({ initialData, onSuccess }: VehicleFormProps) {
    const isEditing = !!initialData
    const [isSubmitting, setIsSubmitting] = useState(false)
    const queryClient = useQueryClient()

    const [formData, setFormData] = useState({
        registrationNumber: initialData?.registrationNumber || "",
        chassisNo: initialData?.chassisNo || "",
        maker: initialData?.maker || "",
        model: initialData?.model || "",
        year: initialData?.year || new Date().getFullYear(),
        ownerId: initialData?.ownerId || ""
    })

    const { data: customers = [] } = useQuery({
        queryKey: ['customers'],
        queryFn: async () => {
            const res = await fetch('/api/customers');
            return res.json();
        }
    })

    const updateField = (field: string, value: any) => {
        setFormData(prev => ({ ...prev, [field]: value }))
    }

    const handleSubmit = async () => {
        if (!formData.ownerId) {
            toast.error("Please select an owner")
            return
        }

        setIsSubmitting(true)
        try {
            const url = isEditing ? `/api/vehicles/${initialData.id}` : '/api/vehicles'
            const method = isEditing ? 'PATCH' : 'POST'

            const res = await fetch(url, {
                method,
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    ...formData,
                    year: parseInt(formData.year.toString())
                })
            })

            if (res.ok) {
                toast.success(isEditing ? "Vehicle record updated" : "Vehicle registered successfully")
                queryClient.invalidateQueries({ queryKey: ['vehicles'] })
                onSuccess()
            } else {
                const err = await res.json()
                toast.error(err.message || "Failed to save vehicle")
            }
        } catch (error) {
            console.error("Submission failed:", error)
            toast.error("An error occurred")
        } finally {
            setIsSubmitting(false)
        }
    }

    return (
        <div className="flex-1 overflow-y-auto p-10 space-y-10 custom-scrollbar-hidden">
            <div className="space-y-10">
                <div className="space-y-6">
                    <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-xl bg-primary/10 border border-primary/20 flex items-center justify-center text-primary shadow-[0_0_15px_rgba(var(--primary),0.1)]">
                             <Fingerprint className="w-4 h-4" />
                        </div>
                        <h3 className="text-[10px] font-black uppercase tracking-[0.4em] text-primary">01. ASSET SPECIFICATIONS</h3>
                    </div>
                    
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div className="space-y-3">
                            <Label className="text-[10px] font-black uppercase tracking-[0.2em] text-foreground/40 ml-1">REGISTRATION PROTOCOL (PLATE)</Label>
                            <div className="relative group">
                                <Car className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-foreground/20 group-focus-within:text-primary transition-colors" />
                                <Input 
                                    value={formData.registrationNumber}
                                    onChange={(e) => updateField('registrationNumber', e.target.value)}
                                    placeholder="T 123 ABC" 
                                    className="h-14 pl-12 bg-white/[0.02] border-white/[0.05] focus:bg-white/[0.04] transition-all rounded-2xl text-[13px] font-bold text-foreground placeholder:text-foreground/10" 
                                />
                            </div>
                        </div>
                        <div className="space-y-3">
                            <Label className="text-[10px] font-black uppercase tracking-[0.2em] text-foreground/40 ml-1">V.I.N. / CHASSIS IDENTIFIER</Label>
                            <div className="relative group">
                                <Fingerprint className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-foreground/20 group-focus-within:text-primary transition-colors" />
                                <Input 
                                    value={formData.chassisNo}
                                    onChange={(e) => updateField('chassisNo', e.target.value)}
                                    placeholder="UNIQUE CHASSIS SERIAL" 
                                    className="h-14 pl-12 bg-white/[0.02] border-white/[0.05] focus:bg-white/[0.04] transition-all rounded-2xl text-[13px] font-bold text-foreground placeholder:text-foreground/10" 
                                />
                            </div>
                        </div>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div className="space-y-3">
                            <Label className="text-[10px] font-black uppercase tracking-[0.2em] text-foreground/40 ml-1">MANUFACTURER / MAKER</Label>
                            <Input 
                                value={formData.maker}
                                onChange={(e) => updateField('maker', e.target.value)}
                                placeholder="E.G. TOYOTA PERFORMANCE" 
                                className="h-14 bg-white/[0.02] border-white/[0.05] focus:bg-white/[0.04] transition-all rounded-2xl text-[13px] font-bold text-foreground placeholder:text-foreground/10" 
                            />
                        </div>
                        <div className="space-y-3">
                            <Label className="text-[10px] font-black uppercase tracking-[0.2em] text-foreground/40 ml-1">ENGINEERING MODEL</Label>
                            <Input 
                                value={formData.model}
                                onChange={(e) => updateField('model', e.target.value)}
                                placeholder="E.G. LAND CRUISER 300" 
                                className="h-14 bg-white/[0.02] border-white/[0.05] focus:bg-white/[0.04] transition-all rounded-2xl text-[13px] font-bold text-foreground placeholder:text-foreground/10" 
                            />
                        </div>
                    </div>

                    <div className="space-y-3">
                        <Label className="text-[10px] font-black uppercase tracking-[0.2em] text-foreground/40 ml-1">FABRICATION YEAR</Label>
                        <div className="relative group">
                            <Calendar className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-foreground/20 group-focus-within:text-primary transition-colors" />
                            <Input 
                                type="number"
                                value={formData.year}
                                onChange={(e) => updateField('year', e.target.value)}
                                placeholder="2024" 
                                className="h-14 pl-12 bg-white/[0.02] border-white/[0.05] focus:bg-white/[0.04] transition-all rounded-2xl text-[13px] font-bold text-foreground placeholder:text-foreground/10" 
                            />
                        </div>
                    </div>
                </div>

                <div className="space-y-6">
                    <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-xl bg-primary/10 border border-primary/20 flex items-center justify-center text-primary shadow-[0_0_15px_rgba(var(--primary),0.1)]">
                             <User className="w-4 h-4" />
                        </div>
                        <h3 className="text-[10px] font-black uppercase tracking-[0.4em] text-primary">02. PERFORMANCE OWNERSHIP</h3>
                    </div>
                    <div className="space-y-3">
                        <Label className="text-[10px] font-black uppercase tracking-[0.2em] text-foreground/40 ml-1">ASSIGNED OPERATOR (OWNER)</Label>
                        <Select value={formData.ownerId} onValueChange={(v) => updateField('ownerId', v)}>
                            <SelectTrigger className="h-14 bg-white/[0.02] border-white/[0.05] hover:bg-white/[0.04] transition-all rounded-2xl text-[13px] font-bold text-foreground focus:ring-primary/30 shadow-inner">
                                <SelectValue placeholder="LOCATE OPERATOR DOSSIER..." />
                            </SelectTrigger>
                            <SelectContent className="glass border-white/[0.08] rounded-2xl shadow-2xl p-1">
                                {customers.map((c: any) => (
                                    <SelectItem key={c.id} value={c.id} className="rounded-xl focus:bg-primary/10 focus:text-primary py-3">
                                        <div className="flex items-center gap-3">
                                            <div className="w-6 h-6 rounded-lg bg-primary/5 border border-primary/10 flex items-center justify-center">
                                                <User className="w-3 h-3 text-primary" />
                                            </div>
                                            <div>
                                                <p className="font-bold">{c.name}</p>
                                                {c.companyName && <p className="text-[9px] font-bold text-foreground/40 uppercase tracking-widest">{c.companyName}</p>}
                                            </div>
                                        </div>
                                    </SelectItem>
                                ))}
                                {customers.length === 0 && <p className="p-6 text-[10px] font-bold text-foreground/30 text-center uppercase tracking-widest">No operators synchronized</p>}
                            </SelectContent>
                        </Select>
                    </div>
                </div>
            </div>

            <div className="pt-6">
                <Button 
                    className={`w-full h-16 rounded-[2rem] font-black text-[14px] uppercase tracking-[0.4em] transition-all duration-700 relative overflow-hidden shadow-2xl ${
                        isSubmitting ? 'bg-muted text-foreground/20' : 'bg-primary hover:bg-primary/90 text-background hover:scale-[1.01] active:scale-[0.99] shadow-[0_20px_50px_-10px_rgba(var(--primary),0.5)]'
                    }`}
                    onClick={handleSubmit}
                    disabled={isSubmitting || !formData.registrationNumber || !formData.maker || !formData.ownerId}
                >
                    <div className="relative z-10 flex items-center gap-3">
                        {isSubmitting ? (
                            <>
                                <Zap className="w-5 h-5 animate-spin" />
                                <span>COMMITTING DATA...</span>
                            </>
                        ) : (
                            <>
                                <Car className="w-5 h-5" />
                                <span>{isEditing ? 'COMMIT SPECIFICATIONS' : 'INITIALIZE ASSET REGISTRATION'}</span>
                            </>
                        )}
                    </div>
                    {!isSubmitting && (
                        <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/10 to-transparent -translate-x-full animate-[shimmer_2s_infinite] pointer-events-none" />
                    )}
                </Button>
            </div>
        </div>
    )
}
