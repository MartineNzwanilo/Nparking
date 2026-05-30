"use client"

import React from "react";
import { 
    Sheet, SheetContent, SheetHeader, 
    SheetTitle, SheetTrigger, SheetClose 
} from "@/components/ui/sheet";
import { cn } from "@/lib/utils";
import { useTheme } from "next-themes";
import { useAppearance } from "@/providers/AppearanceProvider";
import { Icons8 } from "@/components/ui/icons8";

const ACCENT_COLORS = [
    { name: "Blue", color: "#4680ff" },
    { name: "Purple", color: "#9d3aff" },
    { name: "Pink", color: "#ff5cd4" },
    { name: "Red", color: "#ff4500" },
    { name: "Orange", color: "#ffa500" },
    { name: "Yellow", color: "#ffcc00" },
    { name: "Teal", color: "#00d2d3" },
    { name: "Sea Green", color: "#1abc9c" },
    { name: "Dark Cyan", color: "#008080" },
    { name: "Sky Blue", color: "#00bfff" },
];

export function SettingsDrawer({ trigger }: { trigger: React.ReactNode }) {
    const { theme, setTheme } = useTheme();
    const { 
        accentColor, setAccentColor, 
        sidebarTheme, setSidebarTheme,
        layoutWidth, setLayoutWidth, 
        showCaption, setShowCaption,
        themeLayout, setThemeLayout
    } = useAppearance();

    const syncSetting = async (key: string, value: string | boolean | number) => {
        try {
            await fetch("/api/settings", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ [key]: value }),
            });
        } catch (e) {
            console.error("Failed to sync header setting", e);
        }
    };

    const resetLayout = () => {
        setAccentColor("#4680ff");
        setTheme("light");
        setSidebarTheme("dark");
        setLayoutWidth("full");
        setShowCaption(true);
        setThemeLayout("ltr");
        
        // Push reset to DB
        syncSetting("ACCENT_COLOR", "#4680ff");
        syncSetting("SYSTEM_THEME", "light");
        syncSetting("SIDEBAR_THEME", "dark");
        syncSetting("LAYOUT_WIDTH", "full");
        syncSetting("SIDEBAR_CAPTION", "true");
        syncSetting("THEME_LAYOUT", "ltr");
    };

    return (
        <Sheet>
            <SheetTrigger asChild>
                {trigger}
            </SheetTrigger>
            <SheetContent 
                side="right" 
                showCloseButton={false}
                className="w-full sm:w-[320px] md:w-[350px] p-0 border-l border-border glass shadow-2xl animate-in slide-in-from-right duration-300 z-[100]"
            >
                <SheetHeader className="px-5 py-3 md:py-4 border-b border-border flex flex-row items-center justify-between space-y-0 sticky top-0 bg-background/80 backdrop-blur-md z-10">
                    <SheetTitle className="text-[13px] md:text-[14px] font-black text-foreground uppercase tracking-tight">Settings</SheetTitle>
                    <SheetClose className="h-8 w-8 rounded-xl flex items-center justify-center text-destructive bg-destructive/5 hover:bg-destructive/10 transition-all outline-none border border-destructive/10">
                        <Icons8 icon="multiply" className="h-4 w-4" />
                    </SheetClose>
                </SheetHeader>

                <div className="h-[calc(100vh-61px)] overflow-y-auto px-5 py-5 flex flex-col gap-7 custom-scrollbar-hidden">
                    
                    {/* Theme Mode */}
                    <section className="space-y-3">
                        <div className="space-y-0.5">
                            <h3 className="text-[12px] font-bold text-foreground uppercase tracking-widest">Theme Mode</h3>
                            <p className="text-[10px] text-muted-foreground">Choose light or dark mode or Auto</p>
                        </div>
                        <div className="grid grid-cols-3 gap-3">
                            {[
                                { id: "light", name: "Light", icon: "sun" },
                                { id: "dark", name: "Dark", icon: "moon-symbol" },
                                { id: "system", name: "Auto", icon: "monitor" }
                            ].map((mode) => (
                                <button 
                                    key={mode.id}
                                    onClick={() => { setTheme(mode.id); syncSetting("SYSTEM_THEME", mode.id); }}
                                    className={cn(
                                        "relative flex flex-col p-3 rounded-2xl border transition-all active:scale-95",
                                        theme === mode.id ? "border-primary bg-primary/[0.04] shadow-sm" : "border-border/50 hover:bg-muted/50"
                                    )}
                                >
                                    <div className="flex items-center gap-2 mb-2.5">
                                        <div className={cn(
                                            "w-3.5 h-3.5 rounded-full border flex items-center justify-center transition-all",
                                            theme === mode.id ? "border-primary" : "border-muted-foreground/30"
                                        )}>
                                            {theme === mode.id && <div className="w-2 h-2 rounded-full bg-primary" />}
                                        </div>
                                        <span className={cn("text-[10px] font-bold uppercase tracking-tight", theme === mode.id ? "text-primary" : "text-muted-foreground")}>{mode.name}</span>
                                    </div>
                                    <div className={cn(
                                        "w-full h-10 rounded-xl border flex items-center justify-center transition-all shadow-inner",
                                        mode.id === "dark" ? "bg-slate-900" : "bg-slate-50",
                                        theme === mode.id ? "border-primary/20" : "border-border/30"
                                    )}>
                                        <Icons8 icon={mode.icon} className="w-5 h-5" />
                                    </div>
                                </button>
                            ))}
                        </div>
                    </section>

                    {/* Sidebar Theme */}
                    <section className="space-y-3">
                        <div className="space-y-0.5">
                            <h3 className="text-[12px] font-bold text-foreground uppercase tracking-widest">Sidebar Theme</h3>
                            <p className="text-[10px] text-muted-foreground">Choose Sidebar Style</p>
                        </div>
                        <div className="grid grid-cols-2 gap-2">
                            {[
                                { id: "dark", name: "Dark", bg: "bg-slate-900" },
                                { id: "light", name: "Light", bg: "bg-white" }
                            ].map((st) => (
                                <button 
                                    key={st.id}
                                    onClick={() => { setSidebarTheme(st.id as any); syncSetting("SIDEBAR_THEME", st.id); }}
                                    className={cn(
                                        "relative flex flex-col p-2.5 rounded-xl border transition-all",
                                        sidebarTheme === st.id ? "border-primary bg-primary/[0.03] shadow-sm" : "border-border/50"
                                    )}
                                >
                                    <div className="flex items-center gap-1.5 mb-2">
                                        <div className={cn(
                                            "w-3 h-3 rounded-full border flex items-center justify-center transition-all",
                                            sidebarTheme === st.id ? "border-primary" : "border-muted-foreground/30"
                                        )}>
                                            {sidebarTheme === st.id && <div className="w-1.5 h-1.5 rounded-full bg-primary" />}
                                        </div>
                                        <span className={cn("text-[10px] font-semibold uppercase", sidebarTheme === st.id ? "text-primary" : "text-muted-foreground")}>{st.name}</span>
                                    </div>
                                    <div className={cn(
                                        "w-full h-8 rounded-lg border relative overflow-hidden bg-muted/30 transition-all text-muted-foreground/30",
                                        sidebarTheme === st.id ? "border-primary/20" : "border-border/30"
                                    )}>
                                        <div className={cn("absolute inset-y-0 left-0 w-1/4 border-r border-border/30", st.bg)} />
                                        <div className="absolute top-2 right-2 left-[35%] h-1 bg-current rounded-full opacity-20" />
                                        <div className="absolute top-4 right-6 left-[35%] h-1 bg-current rounded-full opacity-20" />
                                    </div>
                                </button>
                            ))}
                        </div>
                    </section>

                    {/* Accent color */}
                    <section className="space-y-3">
                        <div className="space-y-0.5">
                            <h3 className="text-[12px] font-bold text-foreground uppercase tracking-widest">Accent color</h3>
                            <p className="text-[10px] text-muted-foreground">Pick theme color</p>
                        </div>
                        <div className="grid grid-cols-5 gap-y-2.5 gap-x-1 justify-items-center">
                            {ACCENT_COLORS.map((item) => (
                                <button
                                    key={item.name}
                                    onClick={() => { setAccentColor(item.color); syncSetting("ACCENT_COLOR", item.color); }}
                                    className={cn(
                                        "relative w-5.5 h-5.5 rounded-full flex items-center justify-center transition-all hover:scale-110 active:scale-95 shadow-sm",
                                        accentColor === item.color ? "ring-2 ring-primary ring-offset-2" : "border border-border/50"
                                    )}
                                    style={{ backgroundColor: item.color }}
                                >
                                    {accentColor === item.color && (
                                        <Icons8 icon="checkmark" className="w-3 h-3 text-white" />
                                    )}
                                </button>
                            ))}
                        </div>
                    </section>

                    {/* Sidebar Caption */}
                    <section className="space-y-3">
                        <div className="space-y-0.5">
                            <h3 className="text-[12px] font-bold text-foreground uppercase tracking-widest">Sidebar Caption</h3>
                            <p className="text-[10px] text-muted-foreground">Labels Show/Hide</p>
                        </div>
                        <div className="grid grid-cols-2 gap-2">
                            {[
                                { id: true, name: "Caption Show" },
                                { id: false, name: "Caption Hide" }
                            ].map((cap) => (
                                <button 
                                    key={cap.name}
                                    onClick={() => { setShowCaption(cap.id); syncSetting("SIDEBAR_CAPTION", String(cap.id)); }}
                                    className={cn(
                                        "relative flex flex-col p-2.5 rounded-xl border transition-all",
                                        showCaption === cap.id ? "border-primary bg-primary/[0.03] shadow-sm" : "border-border/50"
                                    )}
                                >
                                    <div className="flex items-center gap-1.5 mb-2">
                                        <div className={cn(
                                            "w-3 h-3 rounded-full border flex items-center justify-center transition-all",
                                            showCaption === cap.id ? "border-primary" : "border-muted-foreground/30"
                                        )}>
                                            {showCaption === cap.id && <div className="w-1.5 h-1.5 rounded-full bg-primary" />}
                                        </div>
                                        <span className={cn("text-[10px] font-semibold uppercase", showCaption === cap.id ? "text-primary" : "text-muted-foreground")}>{cap.name}</span>
                                    </div>
                                    <div className={cn(
                                        "w-full h-8 rounded-lg border flex flex-col justify-center gap-1 px-3 bg-muted/30 transition-all text-muted-foreground/30",
                                        showCaption === cap.id ? "border-primary/20" : "border-border/30"
                                    )}>
                                        <div className="w-full h-1 bg-current rounded-full" />
                                        <div className={cn("h-1 bg-current rounded-full", cap.id ? "w-2/3" : "w-0")} />
                                        <div className="w-full h-1 bg-current rounded-full" />
                                    </div>
                                </button>
                            ))}
                        </div>
                    </section>

                    {/* Layout Width */}
                    <section className="space-y-3">
                        <div className="space-y-0.5">
                            <h3 className="text-[12px] font-bold text-foreground uppercase tracking-widest">Layout Width</h3>
                            <p className="text-[10px] text-muted-foreground">Choose Full or Container Layout</p>
                        </div>
                        <div className="grid grid-cols-2 gap-2">
                            {[
                                { id: "full", name: "Full Width", icon: "expand" },
                                { id: "fixed", name: "Fixed Width", icon: "checkmark" }
                            ].map((w) => (
                                <button 
                                    key={w.id}
                                    onClick={() => { setLayoutWidth(w.id as any); syncSetting("LAYOUT_WIDTH", w.id); }}
                                    className={cn(
                                        "relative flex flex-col p-2.5 rounded-xl border transition-all",
                                        layoutWidth === w.id ? "border-primary bg-primary/[0.03] shadow-sm" : "border-border/50"
                                    )}
                                >
                                    <div className="flex items-center gap-1.5 mb-2">
                                        <div className={cn(
                                            "w-3 h-3 rounded-full border flex items-center justify-center transition-all",
                                            layoutWidth === w.id ? "border-primary" : "border-muted-foreground/30"
                                        )}>
                                            {layoutWidth === w.id && <div className="w-1.5 h-1.5 rounded-full bg-primary" />}
                                        </div>
                                        <span className={cn("text-[10px] font-semibold uppercase", layoutWidth === w.id ? "text-primary" : "text-muted-foreground")}>{w.name}</span>
                                    </div>
                                    <div className={cn(
                                        "w-full h-8 rounded-lg border flex items-center justify-center bg-muted/30 transition-all text-muted-foreground/40",
                                        layoutWidth === w.id ? "border-primary/20" : "border-border/30"
                                    )}>
                                        {w.id === "full" ? <Icons8 icon="expand" className="w-4 h-4" /> : <div className="w-1/2 h-1/2 rounded-full border border-dashed border-current" />}
                                    </div>
                                </button>
                            ))}
                        </div>
                    </section>

                    {/* Theme Layout */}
                    <section className="space-y-3">
                        <div className="space-y-0.5">
                            <h3 className="text-[12px] font-bold text-foreground uppercase tracking-widest">Theme Layout</h3>
                            <p className="text-[10px] text-muted-foreground">Direction LTR/RTL</p>
                        </div>
                        <div className="grid grid-cols-2 gap-2">
                            {[
                                { id: "ltr", name: "LTR", icon: "align-left" },
                                { id: "rtl", name: "RTL", icon: "align-right" }
                            ].map((lay) => (
                                <button 
                                    key={lay.id}
                                    onClick={() => { setThemeLayout(lay.id as any); syncSetting("THEME_LAYOUT", lay.id); }}
                                    className={cn(
                                        "relative flex flex-col p-2.5 rounded-xl border transition-all",
                                        themeLayout === lay.id ? "border-primary bg-primary/[0.03] shadow-sm" : "border-border/50"
                                    )}
                                >
                                    <div className="flex items-center gap-1.5 mb-2">
                                        <div className={cn(
                                            "w-3 h-3 rounded-full border flex items-center justify-center transition-all",
                                            themeLayout === lay.id ? "border-primary" : "border-muted-foreground/30"
                                        )}>
                                            {themeLayout === lay.id && <div className="w-1.5 h-1.5 rounded-full bg-primary" />}
                                        </div>
                                        <span className={cn("text-[10px] font-semibold uppercase", themeLayout === lay.id ? "text-primary" : "text-muted-foreground")}>{lay.name}</span>
                                    </div>
                                    <div className={cn(
                                        "w-full h-8 rounded-lg border flex items-center justify-center bg-muted/30 transition-all text-muted-foreground/40",
                                        themeLayout === lay.id ? "border-primary/20" : "border-border/30"
                                    )}>
                                        <Icons8 icon={lay.icon} className="w-4 h-4" />
                                    </div>
                                </button>
                            ))}
                        </div>
                    </section>

                    {/* Reset Button */}
                    <div className="mt-1 pb-8">
                        <button 
                            onClick={resetLayout}
                            className="w-full h-9 bg-muted/20 text-destructive border border-border hover:bg-destructive/5 hover:text-destructive hover:border-destructive/30 rounded-xl text-[12px] font-bold uppercase tracking-widest transition-all group flex items-center justify-center gap-2"
                        >
                            <Icons8 icon="synchronize" className="w-4 h-4 group-hover:rotate-180 transition-transform duration-500" />
                            Reset Layout
                        </button>
                    </div>
                </div>

                <style jsx global>{`
                    .custom-scrollbar-hidden::-webkit-scrollbar {
                        width: 0px;
                        display: none;
                    }
                `}</style>
            </SheetContent>
        </Sheet>
    );
}
