"use client"

import React, { useEffect, useState } from "react"
import { motion, AnimatePresence } from "framer-motion"
import { useQuery } from "@tanstack/react-query"
import { format, subDays } from "date-fns"
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, Legend
} from "recharts"
import { useTheme } from "next-themes"

import { useBreadcrumbStore } from "@/store/useBreadcrumbStore"
import { useSiteStore } from "@/store/useSiteStore"
import { StatCard } from "@/components/ui/stat-card"
import { Icons8 } from "@/components/ui/icons8"
import { apiClient } from "@/lib/apiClient"
import { exportCSV, exportPDF } from "@/lib/exportUtils"
import { cn } from "@/lib/utils"

const COLORS = ['#10b981', '#3b82f6', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899']

// ─── Report Tabs Config ───────────────────────────────────────────────────────
const REPORT_TABS = [
  { id: 'overview',        label: 'Overview',          icon: 'combo-chart',      endpoint: null },
  { id: 'daily-revenue',   label: 'Daily Revenue',     icon: 'money-bag',        endpoint: 'daily-revenue' },
  { id: 'sessions',        label: 'Sessions',          icon: 'car',              endpoint: 'sessions' },
  { id: 'staff',           label: 'Staff Performance', icon: 'user-male-circle', endpoint: 'staff-performance' },
  { id: 'vehicle-history', label: 'Vehicle History',   icon: 'road',             endpoint: 'vehicle-history' },
  { id: 'site-utilization',label: 'Site Utilization',  icon: 'parking',          endpoint: 'site-utilization' },
  { id: 'security',        label: 'Security',          icon: 'security-camera',  endpoint: 'security' },
]

// ─── Reusable Components ──────────────────────────────────────────────────────
function ExportBar({ onPDF, onCSV, isExporting, rowCount }: { onPDF: () => void; onCSV: () => void; isExporting: boolean; rowCount: number }) {
  return (
    <div className="flex items-center gap-3 flex-wrap">
      <span className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">
        {rowCount} record{rowCount !== 1 ? 's' : ''}
      </span>
      <div className="flex-1" />
      <button
        onClick={onCSV}
        disabled={isExporting || rowCount === 0}
        className="h-9 px-5 rounded-xl text-[10px] font-black uppercase tracking-widest bg-secondary text-foreground hover:bg-primary/10 hover:text-primary border border-border flex items-center gap-2 transition-all disabled:opacity-40"
      >
        <Icons8 icon="export-csv" className="w-4 h-4" />
        Export CSV
      </button>
      <button
        onClick={onPDF}
        disabled={isExporting || rowCount === 0}
        className="h-9 px-5 rounded-xl text-[10px] font-black uppercase tracking-widest bg-primary text-white hover:bg-primary/90 flex items-center gap-2 transition-all disabled:opacity-40 shadow-lg shadow-primary/20"
      >
        <Icons8 icon="pdf" className="w-4 h-4 invert" />
        {isExporting ? 'Generating...' : 'Export PDF'}
      </button>
    </div>
  )
}

function DataTable({ rows, emptyMessage = "No records found for this period." }: { rows: any[]; emptyMessage?: string }) {
  if (!rows?.length) {
    return (
      <div className="flex flex-col items-center justify-center py-20 opacity-40 gap-3">
        <Icons8 icon="empty-box" className="w-14 h-14 grayscale" />
        <p className="text-[11px] font-black uppercase tracking-widest">{emptyMessage}</p>
      </div>
    )
  }
  const headers = Object.keys(rows[0])
  return (
    <div className="overflow-x-auto">
      <table className="w-full text-left border-collapse">
        <thead>
          <tr className="border-b border-border/50 bg-secondary/20">
            {headers.map(h => (
              <th key={h} className="px-4 py-3 text-[10px] font-black uppercase tracking-widest text-muted-foreground whitespace-nowrap">
                {h.replace(/([A-Z])/g, ' $1')}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row, idx) => (
            <tr key={idx} className="border-b border-border/30 hover:bg-muted/20 transition-colors">
              {headers.map(h => (
                <td key={h} className={cn(
                  "px-4 py-3 text-[12px] font-bold whitespace-nowrap",
                  row[h] === 'STILL INSIDE' ? "text-red-500" :
                  row[h] === 'EXITED' ? "text-emerald-500" :
                  row[h] === 'YES' ? "text-red-500 font-black" :
                  h === 'amount' || h === 'amountDue' || h === 'amountPaid' || h === 'totalRevenue'
                    ? "text-emerald-500 font-black" : "text-foreground"
                )}>
                  {(h === 'amount' || h === 'amountDue' || h === 'amountPaid' || h === 'totalRevenue') && typeof row[h] === 'number'
                    ? `Tsh ${row[h].toLocaleString()}`
                    : String(row[h] ?? '—')}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

function SummaryCards({ summary }: { summary: Record<string, any> }) {
  return (
    <div className="flex flex-wrap gap-4 p-4 bg-secondary/10 rounded-2xl border border-border/50">
      {Object.entries(summary).map(([key, val]) => (
        <div key={key} className="flex flex-col gap-0.5">
          <span className="text-[9px] font-black uppercase tracking-widest text-muted-foreground">
            {key.replace(/([A-Z])/g, ' $1')}
          </span>
          <span className="text-[15px] font-black text-foreground">
            {typeof val === 'number' && key.toLowerCase().includes('revenue')
              ? `Tsh ${val.toLocaleString()}`
              : String(val)}
          </span>
        </div>
      ))}
    </div>
  )
}

// ─── Main Page ────────────────────────────────────────────────────────────────
export default function ReportsPage() {
  const { setBreadcrumbs } = useBreadcrumbStore()
  const { activeSiteId } = useSiteStore()
  const { resolvedTheme } = useTheme()
  const isDark = resolvedTheme === 'dark'

  const gridColor = isDark ? '#1e293b' : '#dbe0e5'
  const tickColor = isDark ? '#94a3b8' : '#8996a4'
  const tooltipBg = isDark ? '#141c2f' : '#ffffff'
  const tooltipBorder = isDark ? '#1e293b' : '#dbe0e5'

  const [activeTab, setActiveTab] = useState('overview')
  const [startDate, setStartDate] = useState(format(subDays(new Date(), 30), 'yyyy-MM-dd'))
  const [endDate, setEndDate] = useState(format(new Date(), 'yyyy-MM-dd'))
  const [plateSearch, setPlateSearch] = useState('')
  const [isExporting, setIsExporting] = useState(false)

  useEffect(() => {
    setBreadcrumbs([
      { label: "Dashboard", href: "/" },
      { label: "Reports", href: "/reports" }
    ])
  }, [setBreadcrumbs])

  const activeConfig = REPORT_TABS.find(t => t.id === activeTab)!

  // Overview Charts Query
  const overviewQuery = useQuery({
    queryKey: ["dashboard-metrics", activeSiteId],
    queryFn: async () => {
      const res = await apiClient.get(`/api/reports/dashboard?siteId=${activeSiteId}`)
      return res.data
    },
    enabled: activeTab === 'overview'
  })

  // Dynamic Report Query
  const reportQuery = useQuery({
    queryKey: [activeConfig.endpoint, startDate, endDate, activeSiteId, plateSearch],
    queryFn: async () => {
      if (!activeConfig.endpoint) return null
      const params = new URLSearchParams({ startDate, endDate, siteId: activeSiteId })
      if (activeTab === 'vehicle-history' && plateSearch) params.set('plate', plateSearch)
      const res = await apiClient.get(`/api/reports/${activeConfig.endpoint}?${params}`)
      return res.data
    },
    enabled: !!activeConfig.endpoint
  })

  const rows: any[] = reportQuery.data?.rows ?? []
  const summary: any = reportQuery.data?.summary ?? null

  const handlePDF = async () => {
    setIsExporting(true)
    try {
      await exportPDF(
        `${activeTab}-${startDate}-${endDate}`,
        activeConfig.label,
        `${startDate} to ${endDate}${activeSiteId !== 'all' ? ` · Site Filtered` : ''}`,
        rows,
        summary
      )
    } finally { setIsExporting(false) }
  }

  const handleCSV = () => {
    exportCSV(`${activeTab}-${startDate}-${endDate}`, rows)
  }

  return (
    <div className="w-full h-full flex flex-col gap-6 pb-10">

      {/* Tab Navigation */}
      <div className="flex items-center gap-1 overflow-x-auto pb-1">
        {REPORT_TABS.map(tab => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={cn(
              "h-9 px-4 rounded-xl text-[10px] font-black uppercase tracking-widest flex items-center gap-2 transition-all shrink-0 whitespace-nowrap",
              activeTab === tab.id
                ? "bg-primary text-white shadow-lg shadow-primary/20"
                : "bg-secondary/60 text-muted-foreground hover:text-foreground hover:bg-secondary"
            )}
          >
            <Icons8 icon={tab.icon} className={cn("w-3.5 h-3.5", activeTab === tab.id && "invert")} />
            {tab.label}
          </button>
        ))}
      </div>

      {/* ── OVERVIEW TAB ── */}
      <AnimatePresence mode="wait">
        {activeTab === 'overview' && (
          <motion.div key="overview" initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }} className="flex flex-col gap-6">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <StatCard title="Total Revenue (30 Days)" value={`Tsh ${(overviewQuery.data?.keyMetrics?.totalRevenue ?? 0).toLocaleString()}`} icon="combo-chart" trend={{ value: 0, label: "Live data", isPositive: true }} delay={0.1} />
              <StatCard title="Avg Session Duration" value={overviewQuery.data?.keyMetrics?.avgSessionDuration ?? '—'} icon="monitor" trend={{ value: 0, label: "Live data", isPositive: true }} delay={0.2} />
              <StatCard title="Total Vehicles (30 Days)" value={(overviewQuery.data?.keyMetrics?.totalVehicles ?? 0).toLocaleString()} icon="car" trend={{ value: 0, label: "Live data", isPositive: true }} delay={0.3} />
            </div>

            <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
              <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.4 }} className="xl:col-span-2 glass border border-border rounded-3xl p-6 min-h-[380px] flex flex-col shadow-sm">
                <h3 className="text-[13px] font-black uppercase tracking-widest text-foreground mb-6">Revenue Trajectory (30 Days)</h3>
                <div className="flex-1 min-h-[280px]">
                  <ResponsiveContainer width="100%" height="100%">
                    <AreaChart data={overviewQuery.data?.revenueOverTime ?? []} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                      <defs>
                        <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="#10b981" stopOpacity={0.3} />
                          <stop offset="95%" stopColor="#10b981" stopOpacity={0} />
                        </linearGradient>
                      </defs>
                      <CartesianGrid strokeDasharray="3 3" vertical={false} stroke={gridColor} />
                      <XAxis dataKey="date" tickFormatter={(val) => format(new Date(val), 'MMM dd')} axisLine={false} tickLine={false} tick={{ fontSize: 10, fill: tickColor, fontWeight: 900 }} dy={10} />
                      <YAxis axisLine={false} tickLine={false} tickFormatter={(val) => `${val >= 1000 ? (val / 1000) + 'k' : val}`} tick={{ fontSize: 10, fill: tickColor, fontWeight: 900 }} />
                      <Tooltip contentStyle={{ background: tooltipBg, border: `1px solid ${tooltipBorder}`, borderRadius: '12px', fontSize: '12px', fontWeight: 900 }} formatter={(v: any) => [`Tsh ${Number(v).toLocaleString()}`, 'Revenue']} labelFormatter={(l) => format(new Date(l), 'MMM dd, yyyy')} />
                      <Area type="monotone" dataKey="revenue" stroke="#10b981" strokeWidth={3} fillOpacity={1} fill="url(#colorRevenue)" dot={false} activeDot={{ r: 5, fill: '#10b981', strokeWidth: 0 }} />
                    </AreaChart>
                  </ResponsiveContainer>
                </div>
              </motion.div>

              <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.5 }} className="glass border border-border rounded-3xl p-6 flex flex-col shadow-sm">
                <h3 className="text-[13px] font-black uppercase tracking-widest text-foreground mb-2">Traffic Distribution</h3>
                <div className="flex-1 min-h-[300px] flex items-center justify-center relative">
                  {!overviewQuery.data?.vehicleDistribution?.length ? (
                    <div className="flex flex-col items-center justify-center opacity-40 gap-3">
                      <Icons8 icon="car" className="w-16 h-16 grayscale" />
                      <p className="text-[11px] font-black uppercase tracking-widest text-center">No Traffic Data</p>
                    </div>
                  ) : (
                    <ResponsiveContainer width="100%" height="100%">
                      <PieChart>
                        <Pie data={overviewQuery.data.vehicleDistribution} cx="50%" cy="50%" innerRadius={70} outerRadius={100} paddingAngle={5} dataKey="value" stroke="none">
                          {overviewQuery.data.vehicleDistribution.map((_: any, index: number) => (
                            <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                          ))}
                        </Pie>
                        <Tooltip contentStyle={{ borderRadius: '12px', border: `1px solid ${tooltipBorder}`, backgroundColor: tooltipBg, fontWeight: 900, fontSize: '12px' }} />
                        <Legend verticalAlign="bottom" height={36} iconType="circle" formatter={(value) => <span className="text-[10px] font-black uppercase tracking-widest text-muted-foreground ml-1">{value}</span>} />
                      </PieChart>
                    </ResponsiveContainer>
                  )}
                </div>
              </motion.div>
            </div>
          </motion.div>
        )}

        {/* ── DATA REPORT TABS ── */}
        {activeTab !== 'overview' && (
          <motion.div key={activeTab} initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }} className="flex flex-col gap-5">

            {/* Filters */}
            <div className="glass border border-border rounded-2xl p-4 flex flex-wrap items-end gap-4">
              <div>
                <label className="text-[9px] font-black uppercase tracking-widest text-muted-foreground block mb-1.5">Start Date</label>
                <input type="date" value={startDate} onChange={e => setStartDate(e.target.value)}
                  className="h-9 px-3 bg-background border border-border rounded-xl text-[12px] font-bold text-foreground focus:outline-none focus:border-primary transition-all" />
              </div>
              <div>
                <label className="text-[9px] font-black uppercase tracking-widest text-muted-foreground block mb-1.5">End Date</label>
                <input type="date" value={endDate} onChange={e => setEndDate(e.target.value)}
                  className="h-9 px-3 bg-background border border-border rounded-xl text-[12px] font-bold text-foreground focus:outline-none focus:border-primary transition-all" />
              </div>

              {/* Quick presets */}
              {[
                { label: 'Today', days: 0 },
                { label: '7 Days', days: 7 },
                { label: '30 Days', days: 30 },
              ].map(p => (
                <button key={p.label} onClick={() => { setStartDate(format(subDays(new Date(), p.days), 'yyyy-MM-dd')); setEndDate(format(new Date(), 'yyyy-MM-dd')) }}
                  className="h-9 px-4 rounded-xl text-[10px] font-black uppercase tracking-widest bg-secondary hover:bg-primary/10 hover:text-primary text-muted-foreground border border-border transition-all">
                  {p.label}
                </button>
              ))}

              {activeTab === 'vehicle-history' && (
                <div>
                  <label className="text-[9px] font-black uppercase tracking-widest text-muted-foreground block mb-1.5">Plate Number</label>
                  <input
                    type="text"
                    value={plateSearch}
                    onChange={e => setPlateSearch(e.target.value.toUpperCase())}
                    placeholder="e.g. EE5435T6"
                    className="h-9 px-3 bg-background border border-border rounded-xl text-[12px] font-bold text-foreground focus:outline-none focus:border-primary transition-all w-40 uppercase"
                  />
                </div>
              )}
            </div>

            {/* Summary */}
            {summary && <SummaryCards summary={summary} />}

            {/* Table */}
            <div className="glass border border-border rounded-3xl overflow-hidden shadow-sm">
              {/* Export bar */}
              <div className="px-6 py-4 border-b border-border/50 flex items-center gap-4 flex-wrap">
                <h3 className="text-[13px] font-black uppercase tracking-widest text-foreground">
                  {activeConfig.label}
                </h3>
                <ExportBar onPDF={handlePDF} onCSV={handleCSV} isExporting={isExporting} rowCount={rows.length} />
              </div>

              {reportQuery.isLoading ? (
                <div className="flex items-center justify-center py-20">
                  <div className="w-6 h-6 border-2 border-primary border-t-transparent rounded-full animate-spin" />
                </div>
              ) : (
                <DataTable rows={rows} />
              )}
            </div>

          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}
