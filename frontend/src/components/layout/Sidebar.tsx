"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import React, { useState, useRef, useEffect } from "react";
import { cn } from "@/lib/utils";
import { useAppearance } from "@/providers/AppearanceProvider";
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "../ui/tooltip";

import { motion, AnimatePresence } from "framer-motion";
import { Icons8 } from "@/components/ui/icons8";
import { useAuthStore } from "@/store/useAuthStore";

export interface SidebarProps {
  className?: string;
  isMobile?: boolean;
  onCloseTrigger?: () => void;
}



export function Sidebar({ className, isMobile, onCloseTrigger: CloseTrigger }: SidebarProps) {
  const pathname = usePathname();
  const { showCaption, sidebarTheme, siteName, sidebarConfig } = useAppearance();

  const [isProfileOpen, setIsProfileOpen] = useState(false);
  const profileRef = useRef<HTMLDivElement>(null);

  const isDark = sidebarTheme === "dark";
  const { user: authUser, logout } = useAuthStore();
  const user = authUser || { name: "System Admin", phone: "admin@parking.co", image: null };

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (profileRef.current && !profileRef.current.contains(event.target as Node)) {
        setIsProfileOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const baseClasses = isMobile
    ? cn("h-full w-full flex flex-col border-r border-sidebar-border transition-colors duration-300", 
         isDark ? "bg-[#0b1121] text-white" : "bg-white text-slate-600")
    : cn("fixed top-0 left-0 h-screen border-r border-sidebar-border flex flex-col z-50 transition-all duration-300 shadow-xl shadow-black/5",
         showCaption ? 'w-[240px]' : 'w-[75px]',
         isDark ? "bg-[#0b1121] text-white" : "bg-white text-slate-600");

  return (
    <TooltipProvider>
      <aside className={cn(baseClasses, className)}>
        {/* Header / Logo */}
        <div className="h-[70px] border-b border-sidebar-border flex items-center px-6 gap-3 shrink-0 relative overflow-hidden">
          <div className="w-9 h-9 rounded-xl flex items-center justify-center shrink-0 shadow-lg shadow-primary/20 backdrop-blur-md overflow-hidden bg-white/90 p-0.5">
            <img src="/nps_logo.png" alt="NPS Logo" className="w-full h-full object-contain" />
          </div>
          {showCaption && (
            <div className="flex flex-col z-10">
              <span className="font-black text-[14px] tracking-tight uppercase text-foreground leading-none">{siteName}</span>
              <span className="text-[9px] font-bold text-primary tracking-widest uppercase mt-0.5">Enterprise</span>
            </div>
          )}
          {/* Subtle animated background glow */}
          <motion.div 
            className="absolute -inset-4 bg-primary/10 blur-2xl rounded-full"
            animate={{ scale: [1, 1.2, 1], opacity: [0.3, 0.6, 0.3] }}
            transition={{ duration: 4, repeat: Infinity, ease: "easeInOut" }}
          />
        </div>

        {/* Navigation Section */}
        <div className="flex-1 overflow-y-auto overflow-x-hidden p-2 space-y-1 custom-scrollbar">
          {sidebarConfig.filter(item => item.visible).map((item) => {
            const isActive = pathname === item.href || pathname.startsWith(item.href + "/");
            const hasChildren = item.children && item.children.length > 0;
            
            return (
              <div key={item.id} className="flex flex-col">
                <Tooltip>
                  <TooltipTrigger asChild>
                    <Link
                      href={item.href}
                      onClick={() => isMobile && !hasChildren && CloseTrigger && CloseTrigger()}
                      className={cn(
                        "flex items-center gap-3 px-4 py-3.5 rounded-2xl transition-all duration-300 group relative",
                        isActive && !hasChildren
                          ? "bg-primary text-white shadow-[0_8px_20px_rgba(var(--primary),0.3)] scale-[1.02]" 
                          : isActive && hasChildren 
                          ? "bg-primary/10 text-primary" 
                          : isDark ? "text-slate-400 hover:bg-white/5 hover:text-white" : "text-slate-500 hover:bg-muted/30 hover:text-primary",
                        !showCaption && "justify-center px-2"
                      )}
                    >
                      <Icons8 icon={item.icon} isGif={item.isGif} className={cn(
                          "shrink-0 transition-all duration-300", 
                          isActive ? "scale-110" : "group-hover:scale-110",
                          showCaption ? "w-6 h-6" : "w-7 h-7"
                      )} />
                      {showCaption && (
                        <span className="text-[14px] font-bold tracking-tight whitespace-nowrap overflow-hidden text-ellipsis flex-1">
                          {item.label}
                        </span>
                      )}
                    </Link>
                  </TooltipTrigger>
                  {!showCaption && <TooltipContent side="right" className="font-semibold text-[11px] bg-popover text-popover-foreground border-none rounded-md px-3 py-1.5 shadow-xl">{item.label}</TooltipContent>}
                </Tooltip>

                {/* Submenu rendering */}
                <AnimatePresence>
                  {hasChildren && isActive && showCaption && (
                    <motion.div 
                      initial={{ height: 0, opacity: 0 }}
                      animate={{ height: "auto", opacity: 1 }}
                      exit={{ height: 0, opacity: 0 }}
                      className="ml-12 mt-1 flex flex-col gap-1 overflow-hidden"
                    >
                      {item.children!.filter(child => child.visible).map((child) => {
                        const isChildActive = pathname === child.href;
                        return (
                          <Link
                            key={child.id}
                            href={child.href}
                            onClick={() => isMobile && CloseTrigger && CloseTrigger()}
                            className={cn(
                              "text-[12px] font-bold py-2 px-3 rounded-xl transition-all",
                              isChildActive
                                ? "text-primary bg-primary/10"
                                : isDark ? "text-slate-500 hover:text-slate-300 hover:bg-white/5" : "text-slate-500 hover:text-primary hover:bg-muted"
                            )}
                          >
                            {child.label}
                          </Link>
                        );
                      })}
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>
            );
          })}
        </div>

        {/* Strategic Footer with Profile Popover */}
        <div className="p-2 border-t border-sidebar-border flex flex-col gap-2 items-center pb-8 pt-4 relative" ref={profileRef}>
          <Tooltip>
            <TooltipTrigger asChild>
                <Link
                href="/settings"
                className={cn(
                    "flex items-center justify-center w-full h-[50px] rounded-lg transition-all group",
                    isDark ? "text-slate-400 hover:bg-white/5 hover:text-white" : "text-slate-500 hover:bg-muted/50 hover:text-primary"
                )}
                >
                    <Icons8 icon="settings" className={cn("w-5 h-5 group-hover:rotate-45 transition-transform duration-500", isMobile && "w-6 h-6")} />
                </Link>
            </TooltipTrigger>
            <TooltipContent side="right" className="font-semibold text-[11px] bg-popover text-popover-foreground border-none rounded-md px-3 py-1.5 shadow-xl">Settings</TooltipContent>
          </Tooltip>

          {/* Profile Trigger */}
          <button 
            onClick={() => setIsProfileOpen(!isProfileOpen)}
            className={cn(
              "rounded-full border border-sidebar-border bg-muted flex items-center justify-center overflow-hidden cursor-pointer hover:border-primary/40 transition-all mt-1 outline-none relative group",
              isMobile ? "w-12 h-12" : "w-10 h-10",
              isProfileOpen && "border-primary shadow-sm"
            )}
          >
             {(user as any).image ? (
                <img src={(user as any).image} alt={user.name || ''} className="w-full h-full object-cover" />
             ) : (
                <div className="w-full h-full flex items-center justify-center bg-primary/10 text-primary scale-110">
                   <Icons8 icon="user-male-circle" className={cn("w-6 h-6")} />
                </div>
             )}
          </button>

          {/* Profile Popover with Framer Motion */}
          <AnimatePresence>
            {isProfileOpen && (
              <motion.div 
                initial={{ opacity: 0, y: 10, scale: 0.95 }}
                animate={{ opacity: 1, y: 0, scale: 1 }}
                exit={{ opacity: 0, y: 10, scale: 0.95 }}
                transition={{ duration: 0.2, ease: "easeOut" }}
                className={cn(
                  "absolute bottom-[80px] left-4 w-[280px] glass border border-border rounded-2xl shadow-2xl z-[60] overflow-hidden",
                  !showCaption && "left-[60px]"
                )}
              >
                {/* Actions Grid */}
                <div className="p-4 grid grid-cols-2 gap-2 border-b border-border/50 bg-secondary/10">
                  <Link href="/profile" className="flex flex-col items-center justify-center p-5 rounded-xl bg-primary/10 text-primary border border-primary/20 transition-all hover:bg-primary/20 group">
                     <Icons8 icon="user-male-circle" className="w-8 h-8 mb-1.5 transition-transform group-hover:scale-110" />
                     <span className="text-[10px] font-bold uppercase tracking-tight">My Account</span>
                  </Link>
                  <Link href="/settings" className="flex flex-col items-center justify-center p-5 rounded-xl bg-card text-muted-foreground border border-border hover:bg-muted/50 transition-all group">
                     <Icons8 icon="settings" className="w-8 h-8 mb-1.5 group-hover:rotate-45 transition-transform" />
                     <span className="text-[10px] font-bold uppercase tracking-tight">Settings</span>
                  </Link>
                  <button className="flex flex-col items-center justify-center p-5 rounded-xl bg-card text-muted-foreground border border-border hover:bg-muted/50 transition-all group">
                     <Icons8 icon="lock" className="w-8 h-8 mb-1.5 group-hover:scale-110 transition-all" />
                     <span className="text-[10px] font-bold uppercase tracking-tight">Lock Screen</span>
                  </button>
                  <button 
                    onClick={logout}
                    className="flex flex-col items-center justify-center p-5 rounded-xl bg-card text-muted-foreground border border-border hover:bg-destructive/10 hover:text-destructive hover:border-destructive/20 transition-all group"
                  >
                     <Icons8 icon="exit" className="w-8 h-8 mb-1.5 group-hover:-translate-x-1 transition-transform" />
                     <span className="text-[10px] font-bold uppercase tracking-tight">Logout</span>
                  </button>
                </div>

                {/* User Identity Footer */}
                <div className="p-4 flex items-center justify-between bg-card text-foreground">
                  <div className="flex items-center gap-3">
                     <div className="w-10 h-10 rounded-xl bg-primary/10 border border-primary/20 flex items-center justify-center overflow-hidden">
                        {(user as any).image ? (
                          <img src={(user as any).image} alt="" className="w-full h-full object-cover" />
                        ) : <Icons8 icon="user-male-circle" className="w-7 h-7" />}
                     </div>
                     <div className="flex flex-col">
                        <p className="text-[13px] font-bold leading-tight">{user.name || 'Jonh Smith'}</p>
                        <p className="text-[10px] text-muted-foreground font-bold uppercase tracking-widest">{(user as any).email?.includes('admin') ? 'Administrator' : 'User profile'}</p>
                     </div>
                  </div>
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>

        <style jsx global>{`
          .custom-scrollbar-hidden::-webkit-scrollbar {
            width: 0px;
            display: none;
          }
        `}</style>
      </aside>
    </TooltipProvider>
  );
}
