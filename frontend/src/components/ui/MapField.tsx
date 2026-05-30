"use client"
import dynamic from 'next/dynamic'
import { MapPin } from 'lucide-react'

const DynamicMap = dynamic(() => import('./MapPicker'), { 
    ssr: false, 
    loading: () => (
        <div className="h-[250px] w-full bg-muted/10 animate-pulse rounded-2xl flex flex-col items-center justify-center border border-border/5">
            <MapPin className="w-8 h-8 text-primary/20 mb-2 animate-bounce" />
            <span className="text-[10px] font-black uppercase tracking-[0.2em] text-muted-foreground/40">Initializing Orbit...</span>
        </div>
    ) 
})

export default DynamicMap;
