"use client"

import React from "react";
import { usePathname } from "next/navigation";
import { Sidebar } from "@/components/layout/Sidebar";
import { Header } from "@/components/layout/Header";
import { BottomNav } from "@/components/layout/BottomNav";
import { useAppearance } from "@/providers/AppearanceProvider";
import { cn } from "@/lib/utils";
import { useAuthStore } from "@/store/useAuthStore";
import { apiClient } from "@/lib/apiClient";
import { useEffect, useState } from "react";

export function Shell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const { showCaption, layoutWidth } = useAppearance();
  const { user, setUser, setLoading, isLoading, isAuthenticated } = useAuthStore();
  const [authChecked, setAuthChecked] = useState(false);

  useEffect(() => {
    const hydrateAuth = async () => {
      const token = localStorage.getItem("parking-auth-token");
      if (!token) {
        setLoading(false);
        setAuthChecked(true);
        if (pathname !== "/login" && pathname !== "/forgot-password") {
          window.location.href = "/login";
        }
        return;
      }

      if (!isAuthenticated) {
        try {
          const res = await apiClient.get("/api/auth/me");
          setUser(res.data);
        } catch (error) {
          // Error is handled by apiClient interceptor which clears token and redirects
        }
      }
      
      setLoading(false);
      setAuthChecked(true);
    };

    hydrateAuth();
  }, [pathname, isAuthenticated, setUser, setLoading]);

  // Render standalone (no sidebar/header) for auth pages
  if (pathname === "/login" || pathname === "/forgot-password") {
    return <>{children}</>;
  }

  if (!authChecked || isLoading) {
    return (
      <div className="w-full h-screen flex items-center justify-center bg-background">
        <div className="w-12 h-12 border-4 border-primary/30 border-t-primary rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="flex h-screen overflow-hidden bg-background">
      <Sidebar className="hidden xl:flex" />
      <div 
        className={cn(
          "flex-1 flex flex-col overflow-hidden relative transition-all duration-300",
          showCaption ? "xl:ms-[240px]" : "xl:ms-[90px]",
          "ms-0" // Default to no margin on mobile
        )}
      >
        <Header />
        <main className="flex-1 overflow-y-auto w-full pt-[60px] md:pt-[70px] pb-20 md:pb-0 scroll-smooth">
          <div 
            className={cn(
              "w-full relative animate-in fade-in duration-500 p-4 md:p-6",
              layoutWidth === "fixed" ? "max-w-7xl mx-auto" : "max-w-full"
            )}
          >
            {children}
          </div>
        </main>
        <BottomNav />
      </div>
    </div>
  );
}


