"use client"

import React from "react"
import Link from "next/link"
import { usePathname } from "next/navigation"
import { cn } from "@/lib/utils"
import { Icons8 } from "@/components/ui/icons8"

const navItems = [
    { label: "Hub", href: "/", icon: "dashboard" },
    { label: "CCTV", href: "/surveillance", icon: "security-camera" },
    { label: "Fleet", href: "/vehicles", icon: "car" },
    { label: "Reports", href: "/reports", icon: "combo-chart" },
    { label: "Settings", href: "/settings", icon: "settings" },
]

export function BottomNav() {
    const pathname = usePathname()

    return (
        <nav className="md:hidden fixed bottom-0 left-0 right-0 z-[50] glass border-t border-border/40 px-3 pb-safe pt-2">
            <div className="flex items-center justify-around h-16 max-w-lg mx-auto bg-card/40 rounded-2xl border border-white/5 shadow-2xl mb-1">
                {navItems.map((item) => {
                    const isActive = pathname === item.href

                    return (
                        <Link 
                            key={item.label} 
                            href={item.href}
                            className={cn(
                                "flex flex-col items-center justify-center gap-1 w-14 h-full transition-all duration-300 relative group active:scale-90",
                                isActive ? "text-primary" : "text-muted-foreground/60 hover:text-primary/70"
                            )}
                        >
                            <div className={cn(
                                "flex flex-col items-center justify-center transition-all duration-300",
                                isActive ? "-translate-y-1.5 scale-110" : "translate-y-0"
                            )}>
                                <div className={cn(
                                    "p-2 rounded-xl transition-all duration-300 flex items-center justify-center",
                                    isActive ? "bg-primary/10 shadow-[0_4px_20px_rgba(var(--primary),0.2)]" : "bg-transparent"
                                )}>
                                    <Icons8 icon={item.icon} className={cn("w-6 h-6", isActive ? "" : "opacity-80 grayscale")} />
                                </div>
                                {isActive && (
                                    <span className="text-[9px] font-black uppercase tracking-widest mt-0.5 animate-in fade-in slide-in-from-bottom-1 duration-300">
                                        {item.label}
                                    </span>
                                )}
                            </div>
                            {isActive && (
                                <span className="absolute -bottom-1 w-6 h-1 bg-primary rounded-full blur-[2px] opacity-40 animate-pulse" />
                            )}
                        </Link>
                    )
                })}
            </div>
            
            <style jsx>{`
                .pb-safe {
                    padding-bottom: env(safe-area-inset-bottom);
                }
            `}</style>
        </nav>
    )
}
