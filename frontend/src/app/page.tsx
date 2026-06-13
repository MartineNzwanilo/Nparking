"use client"

import React, { useEffect } from "react"
import { motion } from "framer-motion"
import { useQuery } from "@tanstack/react-query"
import { formatDistanceToNow } from "date-fns"
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer
} from "recharts"
import Link from "next/link"
import { useTheme } from "next-themes"

import { StatCard } from "@/components/ui/stat-card"
import { useBreadcrumbStore } from "@/store/useBreadcrumbStore"
import { Icons8 } from "@/components/ui/icons8"
import { apiClient } from "@/lib/apiClient"
import { useSiteStore } from "@/store/useSiteStore"
import { cn } from "@/lib/utils"

const CustomBarTooltip = ({ active, payload, label }: any) => {
  if (active && payload && payload.length) {
    return (
      <div className="bg-card border border-border px-3 py-2 rounded-xl shadow-xl">
        <p className="text-[10px] font-black uppercase tracking-widest text-muted-foreground mb-0.5">{label}</p>
        <p className="text-[13px] font-black text-emerald-500">{payload[0].value} check-ins</p>
      </div>
    )
  }
  return null
}

export default function DashboardPage() {
  const { setBreadcrumbs } = useBreadcrumbStore()
  const { activeSiteId } = useSiteStore()
  const { resolvedTheme } = useTheme()
  const isDark = resolvedTheme === 'dark'

  // Theme-aware colors for Recharts SVG context
  const gridColor = isDark ? '#1e293b' : '#dbe0e5'
  const tickColor = isDark ? '#94a3b8' : '#8996a4'
  const tooltipBg = isDark ? '#141c2f' : '#ffffff'
  const tooltipBorder = isDark ? '#1e293b' : '#dbe0e5'

  useEffect(() => {
    setBreadcrumbs([{ label: "Dashboard", href: "/" }])
  }, [setBreadcrumbs])

  const { data, isLoading } = useQuery({
    queryKey: ["main-dashboard", activeSiteId],
    queryFn: async () => {
      const res = await apiClient.get(`/api/reports/main?siteId=${activeSiteId}`)
      return res.data
    },
    refetchInterval: 30000, // auto-refresh every 30 seconds
  })

  const activeVehicles = data?.activeVehicles ?? 0
  const todaysRevenue = data?.todaysRevenue ?? 0
  const activeStaff = data?.activeStaff ?? 0
  const securityAlerts = data?.securityAlerts ?? 0
  const freeLodgeParkings = data?.freeLodgeParkings ?? 0
  const recentActivity = data?.recentActivity ?? []
  const hourlyTraffic = data?.hourlyTraffic ?? []

  // Only show hours with traffic + surrounding hours, filter to keep chart clean
  const filteredHours = hourlyTraffic.filter((_: any, i: number) => {
    const hour = parseInt(hourlyTraffic[i]?.hour)
    return hour >= 6 && hour <= 22
  })

  return (
    <div className="w-full h-full flex flex-col gap-6 pb-10">

      {/* Stats Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-6">
        <StatCard
          title="Active Vehicles"
          value={isLoading ? "—" : activeVehicles.toString()}
          icon="car"
          trend={{ value: 0, label: "Currently inside", isPositive: true }}
          delay={0.1}
        />
        <StatCard
          title="Today's Revenue"
          value={isLoading ? "—" : `Tsh ${todaysRevenue.toLocaleString()}`}
          icon="combo-chart"
          trend={{ value: 0, label: "Since midnight", isPositive: true }}
          delay={0.2}
        />
        <StatCard
          title="Free Parkings"
          value={isLoading ? "—" : freeLodgeParkings.toString()}
          icon="parking"
          trend={{ value: 0, label: "Lodge guests today", isPositive: true }}
          delay={0.3}
        />
        <StatCard
          title="Security Alerts"
          value={isLoading ? "—" : securityAlerts.toString()}
          icon="security-camera"
          trend={{ value: 0, label: securityAlerts > 0 ? "Blacklisted inside!" : "All clear", isPositive: securityAlerts === 0 }}
          delay={0.4}
        />
        <StatCard
          title="Active Staff"
          value={isLoading ? "—" : activeStaff.toString()}
          icon="user-male-circle"
          trend={{ value: 0, label: "Registered accounts", isPositive: true }}
          delay={0.5}
        />
      </div>

      {/* Charts & Activity Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">

        {/* Hourly Traffic Bar Chart */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5 }}
          className="lg:col-span-2 glass border border-border rounded-3xl p-6 min-h-[380px] flex flex-col shadow-sm"
        >
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="text-[13px] font-black uppercase tracking-widest text-foreground">Today's Traffic</h3>
              <p className="text-[10px] font-bold text-muted-foreground mt-0.5 uppercase tracking-widest">Hourly check-ins</p>
            </div>
            <Link href="/reports">
              <button className="text-[10px] font-black text-primary hover:text-primary/80 uppercase tracking-widest transition-colors">
                Full Report →
              </button>
            </Link>
          </div>

          <div className="flex-1 w-full min-h-[280px]">
            {isLoading ? (
              <div className="w-full h-full flex items-center justify-center opacity-40">
                <div className="w-6 h-6 border-2 border-primary border-t-transparent rounded-full animate-spin"></div>
              </div>
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={filteredHours} margin={{ top: 10, right: 5, left: -25, bottom: 0 }}>
                  <defs>
                    <linearGradient id="colorTraffic" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#10b981" stopOpacity={0.3}/>
                      <stop offset="95%" stopColor="#10b981" stopOpacity={0}/>
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke={gridColor} />
                  <XAxis
                    dataKey="hour"
                    axisLine={false}
                    tickLine={false}
                    tick={{ fontSize: 10, fill: tickColor, fontWeight: 900 }}
                    dy={8}
                  />
                  <YAxis
                    allowDecimals={false}
                    axisLine={false}
                    tickLine={false}
                    tick={{ fontSize: 10, fill: tickColor, fontWeight: 900 }}
                  />
                  <Tooltip
                    content={<CustomBarTooltip />}
                    contentStyle={{ background: tooltipBg, border: `1px solid ${tooltipBorder}`, borderRadius: '12px' }}
                  />
                  <Area
                    type="monotone"
                    dataKey="count"
                    stroke="#10b981"
                    strokeWidth={3}
                    fillOpacity={1}
                    fill="url(#colorTraffic)"
                    dot={false}
                    activeDot={{ r: 5, fill: '#10b981', strokeWidth: 0 }}
                  />
                </AreaChart>
              </ResponsiveContainer>
            )}
          </div>
        </motion.div>

        {/* Live Activity Feed */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.6 }}
          className="glass border border-border rounded-3xl p-6 flex flex-col shadow-sm"
        >
          <div className="flex items-center justify-between mb-5">
            <h3 className="text-[13px] font-black uppercase tracking-widest text-foreground">Live Activity</h3>
            <span className="flex items-center gap-1.5">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
              <span className="text-[9px] font-black uppercase tracking-widest text-emerald-500">Live</span>
            </span>
          </div>

          <div className="flex-1 flex flex-col gap-2.5 overflow-y-auto max-h-[340px]">
            {isLoading ? (
              <div className="flex-1 flex items-center justify-center opacity-40">
                <div className="w-6 h-6 border-2 border-primary border-t-transparent rounded-full animate-spin"></div>
              </div>
            ) : recentActivity.length === 0 ? (
              <div className="flex-1 flex flex-col items-center justify-center opacity-40 gap-3">
                <Icons8 icon="activity-feed" className="w-14 h-14 grayscale" />
                <p className="text-[10px] font-black uppercase tracking-widest text-center">No activity yet</p>
              </div>
            ) : (
              recentActivity.map((item: any) => (
                <div key={item.id} className="flex items-start gap-3 p-3 rounded-2xl bg-card border border-border/40 hover:border-primary/20 transition-colors">
                  <div className={cn(
                    "w-9 h-9 rounded-xl flex items-center justify-center shrink-0",
                    item.action === 'CHECK_IN' ? "bg-emerald-500/10" : "bg-blue-500/10"
                  )}>
                    <Icons8
                      icon={item.action === 'CHECK_IN' ? "enter-2" : "exit"}
                      className={cn("w-5 h-5", item.action === 'CHECK_IN' ? "text-emerald-500" : "text-blue-500")}
                    />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-[12px] font-black text-foreground uppercase tracking-wider truncate">
                      {item.plateNumber}
                    </p>
                    <p className="text-[10px] text-muted-foreground font-bold mt-0.5 truncate">
                      {item.action === 'CHECK_IN' ? 'Checked in' : `Checked out · Tsh ${item.amountDue.toLocaleString()}`}
                    </p>
                    <p className="text-[9px] text-muted-foreground/60 font-bold mt-0.5">
                      by {item.watchmanName}
                    </p>
                  </div>
                  <span className="text-[9px] font-black text-muted-foreground/50 whitespace-nowrap pt-1 shrink-0">
                    {formatDistanceToNow(new Date(item.time), { addSuffix: true })}
                  </span>
                </div>
              ))
            )}
          </div>
        </motion.div>
      </div>

      {/* Security Alert Banner */}
      {securityAlerts > 0 && (
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          className="flex items-center gap-4 px-6 py-4 rounded-2xl bg-red-500/10 border border-red-500/30"
        >
          <Icons8 icon="error" className="w-6 h-6 text-red-500 shrink-0" />
          <div className="flex-1">
            <p className="text-[12px] font-black uppercase tracking-widest text-red-500">
              {securityAlerts} Blacklisted Vehicle{securityAlerts > 1 ? 's' : ''} Currently Inside
            </p>
            <p className="text-[10px] font-bold text-red-400/80 mt-0.5">
              Immediate inspection required. Check the Vehicles page for details.
            </p>
          </div>
          <Link href="/vehicles">
            <button className="px-4 py-2 rounded-xl bg-red-500 text-white text-[10px] font-black uppercase tracking-widest hover:bg-red-600 transition-colors">
              View →
            </button>
          </Link>
        </motion.div>
      )}

    </div>
  )
}
