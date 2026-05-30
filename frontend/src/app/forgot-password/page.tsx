"use client"

import React, { useState } from "react"
import { motion } from "framer-motion"
import { Icons8 } from "@/components/ui/icons8"

export default function ForgotPasswordPage() {
    const [step, setStep] = useState<"email" | "otp" | "reset">("email")
    const [email, setEmail] = useState("")
    const [otp, setOtp] = useState("")
    const [newPassword, setNewPassword] = useState("")
    const [loading, setLoading] = useState(false)
    const [error, setError] = useState("")
    const [success, setSuccess] = useState("")

    const handleSendOtp = async (e: React.FormEvent) => {
        e.preventDefault()
        setError("")
        setLoading(true)
        try {
            const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000'}/api/auth/forgot-password`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ email })
            })
            const data = await res.json()
            if (!res.ok) throw new Error(data.message || "Failed to send OTP")
            setStep("otp")
            setSuccess("We've sent a 6-digit code to your email.")
        } catch (err: any) {
            setError(err.message)
        } finally {
            setLoading(false)
        }
    }

    const handleVerifyOtp = async (e: React.FormEvent) => {
        e.preventDefault()
        if (otp.length !== 6) {
            setError("OTP must be 6 digits")
            return
        }
        setError("")
        setStep("reset")
    }

    const handleResetPassword = async (e: React.FormEvent) => {
        e.preventDefault()
        setError("")
        setLoading(true)
        try {
            const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000'}/api/auth/reset-password`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ email, otp, newPassword })
            })
            const data = await res.json()
            if (!res.ok) throw new Error(data.message || "Failed to reset password")
            setSuccess("Password updated successfully!")
            setTimeout(() => {
                window.location.href = "/login"
            }, 2000)
        } catch (err: any) {
            setError(err.message)
        } finally {
            setLoading(false)
        }
    }

    return (
        <div className="min-h-screen w-full flex items-center justify-center bg-background relative overflow-hidden">
            {/* Background elements (same as login) */}
            <div className="absolute top-0 left-0 w-full h-full overflow-hidden pointer-events-none">
                <div className="absolute top-[-10%] left-[-10%] w-[40%] h-[40%] bg-primary/20 rounded-full blur-[120px]" />
                <div className="absolute bottom-[-10%] right-[-10%] w-[40%] h-[40%] bg-blue-500/10 rounded-full blur-[120px]" />
            </div>

            <motion.div 
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className="w-full max-w-md p-8 bg-card border border-border shadow-2xl rounded-[2rem] relative z-10 mx-4"
            >
                <div className="flex flex-col items-center mb-10">
                    <div className="w-16 h-16 bg-primary/10 rounded-2xl flex items-center justify-center mb-6 shadow-inner border border-primary/20">
                        <Icons8 icon="lock" className="w-8 h-8 text-primary" />
                    </div>
                    <h1 className="text-2xl font-black uppercase tracking-tight text-foreground text-center">
                        {step === "email" ? "Reset Password" : step === "otp" ? "Verify OTP" : "New Password"}
                    </h1>
                    <p className="text-xs font-bold text-muted-foreground uppercase tracking-widest mt-2 text-center">
                        {step === "email" ? "Enter your email to receive a code" : step === "otp" ? "Enter the 6-digit code sent to your email" : "Create a new secure password"}
                    </p>
                </div>

                {error && (
                    <div className="mb-6 p-4 rounded-xl bg-red-500/10 border border-red-500/20 text-red-500 text-xs font-bold flex items-center gap-3">
                        <Icons8 icon="error" className="w-4 h-4" />
                        {error}
                    </div>
                )}
                
                {success && step !== "otp" && (
                    <div className="mb-6 p-4 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-500 text-xs font-bold flex items-center gap-3">
                        <Icons8 icon="checkmark" className="w-4 h-4" />
                        {success}
                    </div>
                )}

                {step === "email" && (
                    <form onSubmit={handleSendOtp} className="flex flex-col gap-5">
                        <div className="space-y-2">
                            <label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground ml-1">Email Address</label>
                            <div className="relative">
                                <div className="absolute left-4 top-1/2 -translate-y-1/2 w-8 h-8 rounded-lg bg-emerald-500/10 flex items-center justify-center">
                                    <Icons8 icon="mail" className="w-4 h-4 text-emerald-500" />
                                </div>
                                <input 
                                    type="email" 
                                    value={email}
                                    onChange={(e) => setEmail(e.target.value)}
                                    className="w-full h-12 bg-secondary/30 border border-border rounded-xl pl-14 pr-4 text-sm font-medium focus:outline-none focus:border-emerald-500/50 focus:ring-2 focus:ring-emerald-500/20 transition-all placeholder:text-muted-foreground/30" 
                                    placeholder="parking@company.com"
                                    required
                                    disabled={loading}
                                />
                            </div>
                        </div>
                        <button 
                            type="submit" 
                            disabled={loading || !email}
                            className="w-full h-12 mt-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-xl font-black text-[12px] uppercase tracking-widest transition-all active:scale-[0.98] disabled:opacity-50 disabled:pointer-events-none flex items-center justify-center gap-2 shadow-lg shadow-primary/25"
                        >
                            {loading ? (
                                <Icons8 icon="spinner" className="w-5 h-5 animate-spin invert" />
                            ) : "Send Reset Code"}
                        </button>
                    </form>
                )}

                {step === "otp" && (
                    <form onSubmit={handleVerifyOtp} className="flex flex-col gap-5">
                        <div className="space-y-2">
                            <label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground ml-1">6-Digit OTP</label>
                            <div className="relative">
                                <input 
                                    type="text" 
                                    maxLength={6}
                                    value={otp}
                                    onChange={(e) => setOtp(e.target.value.replace(/[^0-9]/g, ''))}
                                    className="w-full h-14 bg-secondary/30 border border-border rounded-xl text-center text-2xl tracking-[1em] font-mono font-bold focus:outline-none focus:border-emerald-500/50 focus:ring-2 focus:ring-emerald-500/20 transition-all" 
                                    placeholder="------"
                                    required
                                    disabled={loading}
                                />
                            </div>
                        </div>
                        <button 
                            type="submit" 
                            disabled={loading || otp.length !== 6}
                            className="w-full h-12 mt-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-xl font-black text-[12px] uppercase tracking-widest transition-all active:scale-[0.98] disabled:opacity-50 disabled:pointer-events-none flex items-center justify-center gap-2 shadow-lg shadow-primary/25"
                        >
                            Verify Code
                        </button>
                    </form>
                )}

                {step === "reset" && (
                    <form onSubmit={handleResetPassword} className="flex flex-col gap-5">
                        <div className="space-y-2">
                            <label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground ml-1">New Password</label>
                            <div className="relative">
                                <div className="absolute left-4 top-1/2 -translate-y-1/2 w-8 h-8 rounded-lg bg-indigo-500/10 flex items-center justify-center">
                                    <Icons8 icon="lock" className="w-4 h-4 text-indigo-500" />
                                </div>
                                <input 
                                    type="password" 
                                    value={newPassword}
                                    onChange={(e) => setNewPassword(e.target.value)}
                                    className="w-full h-12 bg-secondary/30 border border-border rounded-xl pl-14 pr-4 text-sm font-medium focus:outline-none focus:border-indigo-500/50 focus:ring-2 focus:ring-indigo-500/20 transition-all placeholder:text-muted-foreground/30 font-mono tracking-widest" 
                                    placeholder="••••••••"
                                    required
                                    disabled={loading}
                                />
                            </div>
                        </div>
                        <button 
                            type="submit" 
                            disabled={loading || !newPassword}
                            className="w-full h-12 mt-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-xl font-black text-[12px] uppercase tracking-widest transition-all active:scale-[0.98] disabled:opacity-50 disabled:pointer-events-none flex items-center justify-center gap-2 shadow-lg shadow-primary/25"
                        >
                            {loading ? (
                                <Icons8 icon="spinner" className="w-5 h-5 animate-spin invert" />
                            ) : "Update Password"}
                        </button>
                    </form>
                )}
                
                <div className="mt-8 text-center">
                    <a href="/login" className="text-[10px] font-bold text-muted-foreground hover:text-foreground transition-colors uppercase tracking-widest">
                        Back to Login
                    </a>
                </div>
            </motion.div>
        </div>
    )
}
