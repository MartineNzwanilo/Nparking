"use client";
import React from 'react';

interface MapPickerProps {
    value?: { lat: number, lng: number };
    onChange?: (pos: { lat: number, lng: number }) => void;
}

export default function MapPicker({ value, onChange }: MapPickerProps) {
    return (
        <div className="h-[250px] w-full bg-muted/10 rounded-2xl flex flex-col items-center justify-center border border-border/5">
            <span className="text-[10px] font-black uppercase tracking-[0.2em] text-muted-foreground/40">Map Module Placeholder</span>
        </div>
    );
}
