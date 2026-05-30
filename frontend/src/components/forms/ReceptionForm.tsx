"use client"

import { useState, useEffect } from "react"
import { useQuery, useQueryClient } from "@tanstack/react-query"
import { Button } from "@/components/ui/button"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Textarea } from "@/components/ui/textarea"
import { 
    User, Car, Settings, ClipboardList, Zap, 
    Search, AlertCircle, CheckCircle2 
} from "lucide-react"
import { toast } from "sonner"
import { Input } from "@/components/ui/input"
import { cn } from "@/lib/utils"

interface ReceptionFormProps {
    onSuccess: () => void
}

const SERVICE_TYPES = [
    { id: "VEHICLE_INSPECTION", label: "Vehicle Inspection", icon: <ClipboardList className="w-3.5 h-3.5" /> },
    { id: "VEHICLE_MAINTENANCE", label: "Vehicle Maintenance", icon: <Settings className="w-3.5 h-3.5" /> },
    { id: "OIL_SERVICE", label: "Oil Service", icon: <Zap className="w-3.5 h-3.5" /> },
]

export function ReceptionForm({ onSuccess }: ReceptionFormProps) {
    const [isSubmitting, setIsSubmitting] = useState(false)
    const [selectedOwnerId, setSelectedOwnerId] = useState("")
    const [selectedVehicleId, setSelectedVehicleId] = useState("")
    const [selectedServices, setSelectedServices] = useState<string[]>([])
    const [description, setDescription] = useState("")
    const queryClient = useQueryClient()

    const { data: customers = [] } = useQuery({
        queryKey: ['customers'],
        queryFn: async () => {
            const res = await fetch('/api/customers');
            return res.json();
        }
    })

    const { data: vehicles = [] } = useQuery({
        queryKey: ['vehicles', selectedOwnerId],
        queryFn: async () => {
            const res = await fetch('/api/vehicles');
            const allVehicles = await res.json();
            return allVehicles.filter((v: any) => v.ownerId === selectedOwnerId);
        },
        enabled: !!selectedOwnerId
    })

    const toggleService = (serviceId: string) => {
        setSelectedServices(prev => 
            prev.includes(serviceId) 
                ? prev.filter(s => s !== serviceId)
                : [...prev, serviceId]
        )
    }

    const handleSubmit = async () => {
        if (!selectedOwnerId || !selectedVehicleId || selectedServices.length === 0) {
            toast.error("Please fill in all required fields")
            return
        }

        setIsSubmitting(true)
        try {
            const vehicle = vehicles.find((v: any) => v.id === selectedVehicleId)
            const serviceLabels = SERVICE_TYPES
                .filter(s => selectedServices.includes(s.id))
                .map(s => s.label)
                .join(", ")

            const payload = {
                title: `Service: ${vehicle.registrationNumber} - ${serviceLabels}`,
                description: description || `Requested services: ${serviceLabels}`,
                customerId: selectedOwnerId,
                vehicleId: selectedVehicleId,
                serviceType: selectedServices.join(","),
                status: "PENDING",
                priority: "Medium"
            }

            const res = await fetch('/api/tasks', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            })

            if (res.ok) {
                toast.success("Job Card created successfully")
                queryClient.invalidateQueries({ queryKey: ['tasks'] })
                onSuccess()
            } else {
                toast.error("Failed to create Job Card")
            }
        } catch (error) {
            console.error("Submission failed:", error)
            toast.error("An error occurred")
        } finally {
            setIsSubmitting(false)
        }
    }

    return (
        <div className="flex-1 p-6 md:p-8 space-y-8 bg-card">
            <div className="space-y-8">
                {/* Step 1: Client Selection */}
                <div className="space-y-4">
                    <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-lg bg-primary/10 flex items-center justify-center text-primary">
                             <User className="w-4.5 h-4.5" />
                        </div>
                        <h3 className="text-[15px] font-bold text-foreground">1. Client Information</h3>
                    </div>
                    
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6 pt-2">
                        <div className="space-y-2">
                            <Label className="text-[11px] font-bold text-muted-foreground uppercase tracking-wider">Select Customer</Label>
                            <Select value={selectedOwnerId} onValueChange={(v) => { setSelectedOwnerId(v || ""); setSelectedVehicleId(""); }}>
                                <SelectTrigger className="h-[40px] bg-card border-border hover:border-primary transition-all rounded-lg text-[14px] text-card-foreground px-3.5">
                                    <SelectValue placeholder="Search or select customer..." />
                                </SelectTrigger>
                                <SelectContent className="bg-card border-border rounded-lg shadow-xl">
                                    {customers.map((c: any) => (
                                        <SelectItem key={c.id} value={c.id} className="focus:bg-muted py-2.5">
                                            <span className="font-medium text-foreground">{c.name}</span>
                                        </SelectItem>
                                    ))}
                                </SelectContent>
                            </Select>
                        </div>

                        <div className={`space-y-2 transition-all duration-300 ${selectedOwnerId ? 'opacity-100' : 'opacity-50 pointer-events-none'}`}>
                            <Label className="text-[11px] font-bold text-muted-foreground uppercase tracking-wider">Vehicle Details</Label>
                            <Select value={selectedVehicleId} onValueChange={(v) => setSelectedVehicleId(v || "")}>
                                <SelectTrigger className="h-[40px] bg-card border-border hover:border-primary transition-all rounded-lg text-[14px] text-card-foreground px-3.5">
                                    <SelectValue placeholder={selectedOwnerId ? "Select registration..." : "Select customer first"} />
                                </SelectTrigger>
                                <SelectContent className="bg-card border-border rounded-lg shadow-xl">
                                    {vehicles.map((v: any) => (
                                        <SelectItem key={v.id} value={v.id} className="focus:bg-muted py-2.5">
                                            <div className="flex flex-col">
                                                <span className="font-bold text-foreground">{v.registrationNumber}</span>
                                                <span className="text-[11px] text-muted-foreground">{v.maker} {v.model}</span>
                                            </div>
                                        </SelectItem>
                                    ))}
                                    {selectedOwnerId && vehicles.length === 0 && (
                                        <div className="p-4 text-center">
                                            <p className="text-[12px] text-muted-foreground mb-3">No vehicles found</p>
                                            <Link href="/vehicles" className="text-[12px] font-bold text-primary hover:underline">Add New Vehicle</Link>
                                        </div>
                                    )}
                                </SelectContent>
                            </Select>
                        </div>
                    </div>
                </div>

                {/* Step 2: Service Selection */}
                <div className="space-y-4">
                    <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-lg bg-primary/10 flex items-center justify-center text-primary">
                             <Zap className="w-4.5 h-4.5" />
                        </div>
                        <h3 className="text-[15px] font-bold text-foreground">2. Requested Services</h3>
                    </div>
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                        {SERVICE_TYPES.map((service) => {
                            const active = selectedServices.includes(service.id);
                            return (
                                <div 
                                    key={service.id}
                                    onClick={() => toggleService(service.id)}
                                    className={cn(
                                        "flex items-center gap-4 p-4 rounded-lg border transition-all cursor-pointer group",
                                        active 
                                            ? "bg-primary/5 border-primary" 
                                            : "bg-card border-border hover:border-primary/50"
                                    )}
                                >
                                    <div className={cn(
                                        "w-10 h-10 rounded flex items-center justify-center transition-all",
                                        active ? "bg-primary text-white" : "bg-muted text-card-foreground group-hover:text-primary"
                                    )}>
                                        {service.icon}
                                    </div>
                                    <div className="flex-1">
                                        <p className={cn("text-[14px] font-bold leading-tight", active ? "text-foreground" : "text-card-foreground")}>
                                            {service.label}
                                        </p>
                                        <p className="text-[11px] font-medium text-muted-foreground mt-1 italic">Click to select</p>
                                    </div>
                                    <div className={cn(
                                        "w-5 h-5 rounded-full border flex items-center justify-center",
                                        active ? "border-primary bg-primary" : "border-border bg-card"
                                    )}>
                                        {active && <CheckCircle2 className="w-3 h-3 text-white" />}
                                    </div>
                                </div>
                            );
                        })}
                    </div>
                </div>

                {/* Step 3: Additional Notes */}
                <div className="space-y-4">
                    <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-lg bg-primary/10 flex items-center justify-center text-primary">
                             <ClipboardList className="w-4.5 h-4.5" />
                        </div>
                        <h3 className="text-[15px] font-bold text-foreground">3. Additional Notes</h3>
                    </div>
                    <div className="space-y-2 pt-2">
                        <Label className="text-[11px] font-bold text-muted-foreground uppercase tracking-wider">Diagnostic Details / Requirements</Label>
                        <Textarea 
                            value={description}
                            onChange={(e) => setDescription(e.target.value)}
                            placeholder="Enter specific issues or instructions..." 
                            className="bg-card border-border hover:border-primary rounded-lg text-[14px] text-card-foreground min-h-[100px] p-3.5 resize-none focus:border-primary transition-all"
                        />
                    </div>
                </div>
            </div>

            <div className="pt-4">
                <Button 
                    className={cn(
                        "w-full h-12 rounded-lg font-bold text-[15px] transition-all shadow-sm",
                        isSubmitting ? "bg-muted text-muted-foreground" : "bg-primary hover:bg-primary/90 text-primary-foreground"
                    )}
                    onClick={handleSubmit}
                    disabled={isSubmitting || !selectedOwnerId || !selectedVehicleId || selectedServices.length === 0}
                >
                    {isSubmitting ? (
                        <div className="flex items-center gap-2">
                            <Settings className="w-5 h-5 animate-spin" />
                            <span>Processing...</span>
                        </div>
                    ) : (
                        "Create Service Job Card"
                    )}
                </Button>
            </div>
        </div>
    )
}

function Link({ href, children, className }: { href: string, children: React.ReactNode, className?: string }) {
    return (
        <a href={href} className={className}>{children}</a>
    )
}
