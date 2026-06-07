"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { motion } from "framer-motion";
import { Icons8 } from "@/components/ui/icons8";
import { apiClient } from "@/lib/apiClient";
import { useAuthStore } from "@/store/useAuthStore";

export default function LoginPage() {
  const router = useRouter();
  const { setUser } = useAuthStore();
  const [identifier, setIdentifier] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");

    try {
      // 1. Authenticate and get token
      const res = await apiClient.post("/api/auth/login", { identifier, password });
      const { accessToken } = res.data;
      
      // 2. Store token securely in localStorage
      localStorage.setItem("parking-auth-token", accessToken);

      // 3. Fetch user profile
      const userRes = await apiClient.get("/api/auth/me");
      const userData = userRes.data;

      // Ensure only ADMIN users can access the web panel
      if (userData.role !== 'ADMIN') {
        localStorage.removeItem("parking-auth-token");
        throw new Error("Access Denied: Web panel is for Administrators only.");
      }

      setUser(userData);

      // 4. Redirect to dashboard
      router.push("/");
    } catch (err: any) {
      console.error("Login failed:", err);
      setError(err.response?.data?.message || "Invalid credentials or server error");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen w-full flex items-center justify-center bg-background p-4 relative overflow-hidden">
      {/* Simplified Background */}
      <div className="absolute inset-0 z-0 bg-background"></div>

      <motion.div 
        initial={{ opacity: 0, scale: 0.95, y: 20 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        transition={{ duration: 0.5, ease: "easeOut" }}
        className="w-full max-w-md relative z-10"
      >
        <div className="glass border border-border/50 shadow-2xl rounded-3xl p-8 md:p-10 flex flex-col gap-8">
            <div className="flex flex-col items-center text-center gap-3">
                <div className="w-16 h-16 rounded-2xl bg-primary/10 flex items-center justify-center border border-primary/20 shadow-inner">
                    <Icons8 icon="parking" className="w-8 h-8 text-primary" />
                </div>
                <div>
                    <h1 className="text-2xl font-black uppercase tracking-widest text-foreground">Parking System</h1>
                </div>
            </div>

            {error && (
                <div className="w-full bg-destructive/10 border border-destructive/20 text-destructive text-[11px] font-bold uppercase tracking-widest p-4 rounded-xl text-center">
                    {error}
                </div>
            )}

            <form onSubmit={handleLogin} className="flex flex-col gap-5">
                <div className="space-y-4">
                    <div className="space-y-2">
                        <label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground ml-1">Phone Number or Email</label>
                        <div className="relative">
                            <div className="absolute left-4 top-1/2 -translate-y-1/2 w-8 h-8 rounded-lg bg-emerald-500/10 flex items-center justify-center">
                                <Icons8 icon="person" className="w-4 h-4 text-emerald-500" />
                            </div>
                            <input 
                                type="text" 
                                value={identifier}
                                onChange={(e) => setIdentifier(e.target.value)}
                                className="w-full h-12 bg-secondary/30 border border-border rounded-xl pl-14 pr-4 text-sm font-medium focus:outline-none focus:border-emerald-500/50 focus:ring-2 focus:ring-emerald-500/20 transition-all placeholder:text-muted-foreground/30" 
                                placeholder="e.g. 0712... or email@example.com"
                                required
                                disabled={loading}
                            />
                        </div>
                    </div>
                    
                    <div className="space-y-2">
                        <div className="flex items-center justify-between ml-1">
                            <label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">Password</label>
                            <Link href="/forgot-password" className="text-[10px] font-bold text-emerald-500 hover:text-emerald-600 transition-colors">Forgot Password?</Link>
                        </div>
                        <div className="relative">
                            <div className="absolute left-4 top-1/2 -translate-y-1/2 w-8 h-8 rounded-lg bg-indigo-500/10 flex items-center justify-center">
                                <Icons8 icon="lock" className="w-4 h-4 text-indigo-500" />
                            </div>
                            <input 
                                type="password" 
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                                className="w-full h-12 bg-secondary/30 border border-border rounded-xl pl-14 pr-4 text-sm font-medium focus:outline-none focus:border-indigo-500/50 focus:ring-2 focus:ring-indigo-500/20 transition-all placeholder:text-muted-foreground/30 font-mono tracking-widest" 
                                placeholder="••••••••"
                                required
                                disabled={loading}
                            />
                        </div>
                    </div>
                </div>

                <button 
                    type="submit" 
                    disabled={loading}
                    className="w-full h-12 mt-2 bg-primary hover:bg-primary/90 text-white font-black text-[11px] uppercase tracking-widest rounded-2xl transition-all shadow-xl shadow-primary/20 flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                    {loading ? (
                        <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                    ) : (
                        <>
                            Authenticate Session
                            <Icons8 icon="forward" className="w-4 h-4 invert" />
                        </>
                    )}
                </button>
            </form>
        </div>
      </motion.div>
    </div>
  );
}
