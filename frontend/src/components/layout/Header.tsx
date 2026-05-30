"use client"

import React, { useState, useEffect, useRef } from "react";

import { Sheet, SheetContent, SheetTrigger, SheetClose } from "@/components/ui/sheet";
import { Sidebar } from "./Sidebar";
import { Button } from "@/components/ui/button";
import { useTheme } from "next-themes";
import { useAppearance } from "@/providers/AppearanceProvider";
import { SettingsDrawer } from "./SettingsDrawer";
import { cn } from "@/lib/utils";
import { useBreadcrumbStore } from "@/store/useBreadcrumbStore";
import Link from "next/link";
import { Icons8 } from "@/components/ui/icons8";
import { motion, AnimatePresence } from "framer-motion";
import { useSiteStore } from "@/store/useSiteStore";
import { useAuthStore } from "@/store/useAuthStore";

export function Header() {

    const { theme, setTheme, resolvedTheme } = useTheme();
    const { layoutWidth, showCaption } = useAppearance();
    const { breadcrumbs } = useBreadcrumbStore();
    const [mounted, setMounted] = useState(false);
    const [isProfileOpen, setIsProfileOpen] = useState(false);
    const [isNotifOpen, setIsNotifOpen] = useState(false);
    const [isSiteOpen, setIsSiteOpen] = useState(false);
    const [isFullscreen, setIsFullscreen] = useState(false);

    const { activeSiteId, setActiveSiteId, parkingSites } = useSiteStore();
    const activeSite = parkingSites.find(s => s.id === activeSiteId) || parkingSites[0];
    const { user: authUser, logout } = useAuthStore();
    const user = authUser || { name: "System Admin", phone: "admin@parking.co", image: null };

    const profileRef = useRef<HTMLDivElement>(null);
    const notifRef   = useRef<HTMLDivElement>(null);
    const siteRef    = useRef<HTMLDivElement>(null);


    const toggleFullscreen = () => {
        if (!document.fullscreenElement) {
            document.documentElement.requestFullscreen().catch(() => {});
        } else {
            document.exitFullscreen().catch(() => {});
        }
    };

    useEffect(() => {
        const handleClickOutside = (event: MouseEvent) => {
            if (profileRef.current && !profileRef.current.contains(event.target as Node)) {
                setIsProfileOpen(false);
            }
            if (notifRef.current && !notifRef.current.contains(event.target as Node)) {
                setIsNotifOpen(false);
            }
            if (siteRef.current && !siteRef.current.contains(event.target as Node)) {
                setIsSiteOpen(false);
            }
        };
        const handleFullscreenChange = () => {
            setIsFullscreen(!!document.fullscreenElement);
        };
        document.addEventListener("mousedown", handleClickOutside);
        document.addEventListener("fullscreenchange", handleFullscreenChange);
        setMounted(true);
        return () => {
            document.removeEventListener("mousedown", handleClickOutside);
            document.removeEventListener("fullscreenchange", handleFullscreenChange);
        };
    }, []);



    return (
        <header className={cn(
            "fixed top-0 right-0 z-[60] h-[60px] md:h-[70px] flex items-center glass border-b border-border transition-all duration-300 w-full",
            showCaption ? "xl:ps-[240px]" : "xl:ps-[90px]",
            "ps-0"
        )}>
            <div className={cn(
                "flex items-center justify-between w-full px-4 md:px-6",
                layoutWidth === "fixed" ? "max-w-7xl mx-auto" : "max-w-full"
            )}>
                {/* Left: Menu & Breadcrumbs */}
                <div className="flex items-center gap-1 sm:gap-4">
                    <div className="xl:hidden">
                        <Sheet>
                            <SheetTrigger asChild>
                                <Button variant="ghost" size="icon" className="h-9 w-9 rounded-xl hover:bg-muted transition-all">
                                    <Icons8 icon="menu" className="w-5 h-5" />
                                </Button>
                            </SheetTrigger>
                            <SheetContent side="left" className="p-0 border-none w-[280px] bg-card shadow-2xl">
                                <SheetClose asChild>
                                    <Sidebar isMobile={true} className="w-full h-full" />
                                </SheetClose>
                            </SheetContent>
                        </Sheet>
                    </div>

                    <div className="hidden lg:flex items-center gap-2 text-[13px] font-bold uppercase tracking-widest text-muted-foreground">
                        <Link href="/" className="hover:text-primary transition-colors">Hub</Link>
                        {breadcrumbs.map((crumb, index) => (
                            <React.Fragment key={index}>
                                <Icons8 icon="forward" className="w-4 h-4 opacity-40 shrink-0" />
                                {crumb.href ? (
                                    <Link href={crumb.href} className="hover:text-primary transition-colors truncate max-w-[150px]">
                                        {crumb.label}
                                    </Link>
                                ) : (
                                    <span className="text-foreground font-black tracking-widest truncate max-w-[200px]">{crumb.label}</span>
                                )}
                            </React.Fragment>
                        ))}
                    </div>
                </div>

                {/* Right: Tools & Profile */}
                <div className="flex items-center gap-2 md:gap-4">
                    {/* Global Site Switcher */}
                    <div className="relative hidden md:block" ref={siteRef}>
                        <button
                            onClick={() => { setIsSiteOpen(!isSiteOpen); setIsNotifOpen(false); setIsProfileOpen(false); }}
                            className="flex items-center gap-2 h-10 px-4 rounded-xl bg-primary/10 hover:bg-primary/20 text-primary border border-primary/20 transition-all font-black text-[11px] uppercase tracking-widest"
                        >
                            <Icons8 icon="parking" className="w-4 h-4" />
                            {activeSite.name}
                            <Icons8 icon="collapse" className={cn("w-3 h-3 transition-transform", isSiteOpen && "rotate-180")} />
                        </button>
                        
                        <AnimatePresence>
                            {isSiteOpen && (
                                <motion.div 
                                    initial={{ opacity: 0, y: 10, scale: 0.95 }}
                                    animate={{ opacity: 1, y: 0, scale: 1 }}
                                    exit={{ opacity: 0, y: 10, scale: 0.95 }}
                                    className="absolute top-full right-0 mt-3 w-64 glass border border-border rounded-2xl shadow-2xl z-[60] overflow-hidden"
                                >
                                    <div className="p-4 border-b border-border bg-card/50">
                                        <p className="text-[10px] font-black uppercase tracking-widest text-muted-foreground mb-1">Select Facility</p>
                                    </div>
                                    <div className="p-2 flex flex-col gap-1 max-h-64 overflow-y-auto">
                                        {parkingSites.map(site => (
                                            <button
                                                key={site.id}
                                                onClick={() => { setActiveSiteId(site.id); setIsSiteOpen(false); }}
                                                className={cn(
                                                    "w-full flex items-center justify-between p-3 rounded-xl transition-all text-left",
                                                    activeSiteId === site.id 
                                                        ? "bg-primary/10 text-primary font-black" 
                                                        : "hover:bg-secondary/30 text-foreground font-bold"
                                                )}
                                            >
                                                <div className="flex flex-col">
                                                    <span className="text-[12px]">{site.name}</span>
                                                    <span className="text-[10px] text-muted-foreground font-semibold">{site.location}</span>
                                                </div>
                                                {activeSiteId === site.id && <Icons8 icon="checkmark" className="w-4 h-4" />}
                                            </button>
                                        ))}
                                    </div>
                                </motion.div>
                            )}
                        </AnimatePresence>
                    </div>

                    <div className="h-6 w-[1px] bg-border mx-1 hidden md:block" />

                    <div className="hidden lg:flex items-center gap-1">
                        <Button
                            variant="ghost" size="icon"
                            className={cn("h-10 w-10 rounded-full hover:bg-muted transition-all", isFullscreen && "bg-primary/10 text-primary")}
                            onClick={toggleFullscreen}
                        >
                            <Icons8 icon={isFullscreen ? "collapse" : "expand"} className="w-5 h-5" />
                        </Button>

                        <Button
                            variant="ghost" size="icon"
                            className="h-10 w-10 rounded-full hover:bg-muted transition-all"
                            onClick={() => setTheme(resolvedTheme === 'dark' ? 'light' : 'dark')}
                        >
                            {mounted && resolvedTheme === 'dark' ? <Icons8 icon="sun" className="w-5 h-5" /> : <Icons8 icon="moon-symbol" className="w-5 h-5" />}
                        </Button>

                        <SettingsDrawer
                            trigger={
                                <Button variant="ghost" size="icon" className="h-10 w-10 rounded-full hover:bg-muted transition-all group">
                                    <Icons8 icon="settings" className="w-5 h-5 group-hover:rotate-45 transition-transform" />
                                </Button>
                            }
                        />

                        <div className="relative" ref={notifRef}>
                            <Button
                                variant="ghost" size="icon"
                                className="h-10 w-10 rounded-full hover:bg-muted relative"
                                onClick={() => setIsNotifOpen(!isNotifOpen)}
                            >
                                <Icons8 icon="bell" className="w-6 h-6" />
                                <span className="absolute top-2 right-2 w-2 h-2 bg-primary rounded-full animate-ping" />
                                <span className="absolute top-2 right-2 w-2 h-2 bg-primary rounded-full border-2 border-card" />
                            </Button>
                            
                            <AnimatePresence>
                                {isNotifOpen && (
                                    <motion.div 
                                        initial={{ opacity: 0, y: 10, scale: 0.95 }}
                                        animate={{ opacity: 1, y: 0, scale: 1 }}
                                        exit={{ opacity: 0, y: 10, scale: 0.95 }}
                                        className="absolute mt-3 right-0 w-[380px] glass border border-border rounded-3xl shadow-2xl z-[60] overflow-hidden"
                                    >
                                        <div className="flex items-center justify-between px-5 py-4 border-b border-border bg-card/50">
                                            <h3 className="text-[14px] font-black tracking-widest uppercase text-foreground">Alerts</h3>
                                        </div>
                                        <div className="p-6 flex flex-col items-center justify-center text-center">
                                            <Icons8 icon="box" className="w-16 h-16 mb-4 opacity-50" />
                                            <p className="text-sm font-black text-foreground/40 uppercase tracking-widest">All Clear</p>
                                        </div>
                                    </motion.div>
                                )}
                            </AnimatePresence>
                        </div>
                    </div>

                    <div className="h-6 w-[1px] bg-border mx-1 hidden sm:block" />

                    <div className="relative" ref={profileRef}>
                        <button
                            onClick={() => { setIsProfileOpen(!isProfileOpen); setIsNotifOpen(false); }}
                            className="flex items-center p-0.5 md:p-1 rounded-full transition-all group outline-none"
                        >
                            <div className="w-8 h-8 md:w-9 md:h-9 rounded-full bg-primary/20 border-2 border-primary/50 flex items-center justify-center overflow-hidden transition-transform group-hover:scale-105">
                                    <Icons8 icon="user-male-circle" className="w-6 h-6" />
                            </div>
                        </button>

                        <AnimatePresence>
                            {isProfileOpen && (
                                <motion.div 
                                    initial={{ opacity: 0, y: 10, scale: 0.95 }}
                                    animate={{ opacity: 1, y: 0, scale: 1 }}
                                    exit={{ opacity: 0, y: 10, scale: 0.95 }}
                                    className="absolute top-full right-0 mt-3 w-64 glass border border-border rounded-2xl shadow-2xl z-[60] overflow-hidden"
                                >
                                    <div className="p-5 border-b border-border bg-card/50">
                                        <p className="text-[11px] font-bold uppercase tracking-wider text-muted-foreground mb-1">Authenticated Account</p>
                                        <p className="text-[14px] font-semibold text-foreground truncate">{user.phone || (user as any).email}</p>
                                    </div>
                                    <div className="p-2 flex flex-col gap-0.5">
                                        <button
                                            onClick={logout}
                                            className="w-full flex items-center gap-3 p-3 text-[14px] font-bold uppercase tracking-widest rounded-lg hover:bg-destructive/10 text-destructive transition-all group"
                                        >
                                            <Icons8 icon="exit" className="w-5 h-5 group-hover:-translate-x-1 transition-transform" />
                                            <span>System Logout</span>
                                        </button>
                                    </div>
                                </motion.div>
                            )}
                        </AnimatePresence>
                    </div>
                </div>
            </div>
        </header>
    );
}
