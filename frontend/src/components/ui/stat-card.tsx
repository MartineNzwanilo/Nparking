"use client"

import React from "react"
import { cn } from "@/lib/utils"
import { motion } from "framer-motion"
import { Icons8 } from "./icons8"

interface StatCardProps {
  title: string
  value: string | number
  trend?: {
    value: number
    label: string
    isPositive?: boolean
  }
  icon: string
  className?: string
  delay?: number
}

export function StatCard({ title, value, trend, icon, className, delay = 0 }: StatCardProps) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5, delay, ease: "easeOut" }}
      className={cn(
        "relative overflow-hidden rounded-3xl glass border border-border p-6",
        "hover:shadow-2xl hover:-translate-y-1 transition-all duration-300 group",
        className
      )}
    >
      <div className="absolute -right-6 -top-6 opacity-10 group-hover:scale-110 group-hover:opacity-20 transition-all duration-500">
        <Icons8 icon={icon} className="w-32 h-32" />
      </div>

      <div className="relative z-10 flex flex-col gap-4">
        <div className="flex items-center gap-3">
          <div className="w-12 h-12 rounded-2xl bg-primary/10 border border-primary/20 flex items-center justify-center">
             <Icons8 icon={icon} className="w-7 h-7" />
          </div>
          <h3 className="text-[13px] font-black uppercase tracking-widest text-muted-foreground">
            {title}
          </h3>
        </div>

        <div>
          <h2 className="text-4xl font-black tracking-tight text-foreground">
            {value}
          </h2>
          
          {trend && (
            <div className="flex items-center gap-2 mt-2">
              <span className={cn(
                "px-2 py-0.5 rounded-full text-[11px] font-bold uppercase tracking-widest",
                trend.isPositive !== false ? "bg-green-500/10 text-green-500" : "bg-red-500/10 text-red-500"
              )}>
                {trend.isPositive !== false ? "+" : "-"}{trend.value}%
              </span>
              <span className="text-[11px] font-semibold text-muted-foreground uppercase tracking-widest">
                {trend.label}
              </span>
            </div>
          )}
        </div>
      </div>
      
      {/* Animated glow on hover */}
      <div className="absolute inset-0 bg-gradient-to-r from-primary/0 via-primary/5 to-primary/0 opacity-0 group-hover:opacity-100 -translate-x-full group-hover:translate-x-full transition-all duration-1000 ease-in-out pointer-events-none" />
    </motion.div>
  )
}
