"use client"

import React, { useEffect, useState, useMemo } from "react"
import { motion, AnimatePresence } from "framer-motion"
import { useQuery } from "@tanstack/react-query"
import { format, subDays } from "date-fns"
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, Legend, BarChart, Bar
} from "recharts"
import { useTheme } from "next-themes"

import { useBreadcrumbStore } from "@/store/useBreadcrumbStore"
import { useSiteStore } from "@/store/useSiteStore"
import { StatCard } from "@/components/ui/stat-card"
import { Icons8 } from "@/components/ui/icons8"
import { apiClient } from "@/lib/apiClient"
import { exportCSV, exportPDF } from "@/lib/exportUtils"
import { cn } from "@/lib/utils"
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"

const COLORS = ['#10b981', '#3b82f6', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899']

// ─── Report Tabs Config ───────────────────────────────────────────────────────
const REPORT_TABS = [
  { id: 'overview',        label: 'Overview',          icon: 'combo-chart',      endpoint: null },
  { id: 'financial',       label: 'Financials & Expenses', icon: 'briefcase',    endpoint: 'financial' },
  { id: 'daily-revenue',   label: 'Daily Revenue',     icon: 'money-bag',        endpoint: 'daily-revenue' },
  { id: 'sessions',        label: 'Sessions',          icon: 'car',              endpoint: 'sessions' },
  { id: 'overstay',        label: 'Overstay & Fines',  icon: 'warning-shield',   endpoint: 'overstay' },
  { id: 'staff',           label: 'Staff Performance', icon: 'user-male-circle', endpoint: 'staff-performance' },
  { id: 'vehicle-history', label: 'Vehicle History',   icon: 'road',             endpoint: 'vehicle-history' },
  { id: 'site-utilization',label: 'Site Utilization',  icon: 'parking',          endpoint: 'site-utilization' },
  { id: 'security',        label: 'Security',          icon: 'security-camera',  endpoint: 'security' },
]

// ─── Currency columns ─────────────────────────────────────────────────────────
const CURRENCY_COLS = new Set([
  'amount', 'amountDue', 'amountPaid', 'totalRevenue', 'fineAmount',
  'totalCharged', 'parkingCharge', 'totalFinesCharged', 'totalFines', 'totalPaid',
  'totalParkingRevenue', 'grandTotal', 'cashRevenue', 'mobileRevenue',
])

// ─── Sort indicator ───────────────────────────────────────────────────────────
function SortIcon({ col, sortCol, dir }: { col: string; sortCol: string; dir: 'asc' | 'desc' }) {
  if (col !== sortCol) return <span className="opacity-20 ml-1">↕</span>
  return <span className="ml-1 text-primary">{dir === 'asc' ? '↑' : '↓'}</span>
}

// ─── Export Bar ───────────────────────────────────────────────────────────────
function ExportBar({ onPDF, onCSV, onPrint, isExporting, rowCount, filtered }: {
  onPDF: () => void; onCSV: () => void; onPrint: () => void; isExporting: boolean; rowCount: number; filtered: number
}) {
  return (
    <div className="flex items-center gap-2 flex-wrap">
      <span className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">
        {filtered} of {rowCount} record{rowCount !== 1 ? 's' : ''}
      </span>
      <div className="flex-1" />
      <button
        onClick={onCSV}
        disabled={isExporting || filtered === 0}
        className="h-9 px-4 rounded-xl text-[10px] font-black uppercase tracking-widest bg-secondary text-foreground hover:bg-primary/10 hover:text-primary border border-border flex items-center gap-2 transition-all disabled:opacity-40"
      >
        <Icons8 icon="export-csv" className="w-4 h-4" />
        CSV
      </button>
      <button
        onClick={onPrint}
        disabled={isExporting || filtered === 0}
        className="h-9 px-4 rounded-xl text-[10px] font-black uppercase tracking-widest bg-emerald-500 hover:bg-emerald-600 text-white flex items-center gap-2 transition-all disabled:opacity-40 shadow-lg shadow-emerald-500/20"
      >
        <Icons8 icon="printer" className="w-4 h-4 invert" />
        Print
      </button>
      <button
        onClick={onPDF}
        disabled={isExporting || filtered === 0}
        className="h-9 px-4 rounded-xl text-[10px] font-black uppercase tracking-widest bg-primary text-white hover:bg-primary/90 flex items-center gap-2 transition-all disabled:opacity-40 shadow-lg shadow-primary/20"
      >
        <Icons8 icon="pdf" className="w-4 h-4 invert" />
        {isExporting ? 'PDF...' : 'PDF'}
      </button>
    </div>
  )
}

// ─── Smart Data Table with sort, search, pagination ──────────────────────────
function DataTable({
  rows,
  emptyMessage = "No records found for this period.",
}: {
  rows: any[]
  emptyMessage?: string
}) {
  const [sortCol, setSortCol] = useState('')
  const [sortDir, setSortDir] = useState<'asc' | 'desc'>('asc')
  const [search, setSearch] = useState('')
  const [page, setPage] = useState(1)
  const [pageSize, setPageSize] = useState(25)

  // Reset page when rows change
  useEffect(() => { setPage(1) }, [rows])

  if (!rows?.length) {
    return (
      <div className="flex flex-col items-center justify-center py-20 opacity-40 gap-3">
        <Icons8 icon="empty-box" className="w-14 h-14 grayscale" />
        <p className="text-[11px] font-black uppercase tracking-widest">{emptyMessage}</p>
      </div>
    )
  }

  const headers = Object.keys(rows[0])

  // Filter
  const filtered = useMemo(() => {
    if (!search.trim()) return rows
    const q = search.toLowerCase()
    return rows.filter(row =>
      headers.some(h => String(row[h] ?? '').toLowerCase().includes(q))
    )
  }, [rows, search, headers])

  // Sort
  const sorted = useMemo(() => {
    if (!sortCol) return filtered
    return [...filtered].sort((a, b) => {
      const av = a[sortCol]; const bv = b[sortCol]
      if (typeof av === 'number' && typeof bv === 'number') {
        return sortDir === 'asc' ? av - bv : bv - av
      }
      return sortDir === 'asc'
        ? String(av).localeCompare(String(bv))
        : String(bv).localeCompare(String(av))
    })
  }, [filtered, sortCol, sortDir])

  // Paginate
  const totalPages = Math.max(1, Math.ceil(sorted.length / pageSize))
  const paginated = sorted.slice((page - 1) * pageSize, page * pageSize)

  const handleSort = (col: string) => {
    if (sortCol === col) setSortDir(d => d === 'asc' ? 'desc' : 'asc')
    else { setSortCol(col); setSortDir('asc') }
    setPage(1)
  }

  const handleSearch = (v: string) => { setSearch(v); setPage(1) }

  return (
    <div className="flex flex-col gap-0">
      {/* Search + Page size */}
      <div className="px-4 py-3 border-b border-border/30 flex items-center gap-3 flex-wrap">
        <div className="relative flex-1 min-w-[180px] max-w-xs">
          <Icons8 icon="search" className="w-3.5 h-3.5 absolute left-3 top-1/2 -translate-y-1/2 opacity-40" />
          <input
            type="text"
            value={search}
            onChange={e => handleSearch(e.target.value)}
            placeholder="Search records…"
            className="w-full h-8 pl-8 pr-3 bg-secondary/40 border border-border rounded-lg text-[11px] font-bold text-foreground focus:outline-none focus:border-primary transition-all"
          />
          {search && (
            <button onClick={() => handleSearch('')} className="absolute right-2 top-1/2 -translate-y-1/2 opacity-40 hover:opacity-100">
              ✕
            </button>
          )}
        </div>
        <div className="flex items-center gap-2 ml-auto">
          <span className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">Show</span>
          {[10, 25, 50, 100].map(n => (
            <button
              key={n}
              onClick={() => { setPageSize(n); setPage(1) }}
              className={cn(
                "h-7 w-10 rounded-lg text-[10px] font-black transition-all",
                pageSize === n ? "bg-primary text-white" : "bg-secondary text-muted-foreground hover:text-foreground"
              )}
            >
              {n}
            </button>
          ))}
        </div>
      </div>

      {/* Table */}
      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="border-b border-border/50 bg-secondary/20">
              {headers.map(h => (
                <th
                  key={h}
                  onClick={() => handleSort(h)}
                  className="px-4 py-3 text-[10px] font-black uppercase tracking-widest text-muted-foreground whitespace-nowrap cursor-pointer hover:text-foreground select-none transition-colors"
                >
                  {h.replace(/([A-Z])/g, ' $1')}
                  <SortIcon col={h} sortCol={sortCol} dir={sortDir} />
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {paginated.length === 0 ? (
              <tr>
                <td colSpan={headers.length} className="text-center py-12 text-[11px] font-black uppercase tracking-widest text-muted-foreground opacity-40">
                  No results match your search
                </td>
              </tr>
            ) : paginated.map((row, idx) => (
              <tr
                key={idx}
                className={cn(
                  "border-b border-border/30 hover:bg-muted/20 transition-colors",
                  (row.fineAmount > 0 || row.watchmanForgot === 'YES') && "bg-amber-500/5"
                )}
              >
                {headers.map(h => (
                  <td
                    key={h}
                    className={cn(
                      "px-4 py-3 text-[12px] font-bold whitespace-nowrap",
                      row[h] === 'STILL INSIDE' ? "text-red-500" :
                      row[h] === 'EXITED' ? "text-emerald-500" :
                      row[h] === 'YES' ? "text-red-500 font-black" :
                      h === 'fineAmount' && typeof row[h] === 'number' && row[h] > 0 ? "text-amber-500 font-black" :
                      CURRENCY_COLS.has(h) ? "text-emerald-500 font-black" : "text-foreground"
                    )}
                  >
                    {CURRENCY_COLS.has(h) && typeof row[h] === 'number'
                      ? `Tsh ${row[h].toLocaleString()}`
                      : String(row[h] ?? '—')}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="px-4 py-3 border-t border-border/30 flex items-center justify-between flex-wrap gap-3">
          <span className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">
            Page {page} of {totalPages} · {sorted.length} records
          </span>
          <div className="flex items-center gap-1">
            <button
              onClick={() => setPage(1)}
              disabled={page === 1}
              className="h-7 px-2 rounded-lg text-[10px] font-black bg-secondary text-muted-foreground hover:text-foreground disabled:opacity-30 transition-all"
            >«</button>
            <button
              onClick={() => setPage(p => Math.max(1, p - 1))}
              disabled={page === 1}
              className="h-7 px-3 rounded-lg text-[10px] font-black bg-secondary text-muted-foreground hover:text-foreground disabled:opacity-30 transition-all"
            >Prev</button>
            {/* Page number buttons */}
            {Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
              const start = Math.max(1, Math.min(page - 2, totalPages - 4))
              const p = start + i
              return p <= totalPages ? (
                <button
                  key={p}
                  onClick={() => setPage(p)}
                  className={cn(
                    "h-7 w-7 rounded-lg text-[10px] font-black transition-all",
                    page === p ? "bg-primary text-white shadow-lg shadow-primary/20" : "bg-secondary text-muted-foreground hover:text-foreground"
                  )}
                >{p}</button>
              ) : null
            })}
            <button
              onClick={() => setPage(p => Math.min(totalPages, p + 1))}
              disabled={page === totalPages}
              className="h-7 px-3 rounded-lg text-[10px] font-black bg-secondary text-muted-foreground hover:text-foreground disabled:opacity-30 transition-all"
            >Next</button>
            <button
              onClick={() => setPage(totalPages)}
              disabled={page === totalPages}
              className="h-7 px-2 rounded-lg text-[10px] font-black bg-secondary text-muted-foreground hover:text-foreground disabled:opacity-30 transition-all"
            >»</button>
          </div>
        </div>
      )}
    </div>
  )
}

function SummaryCards({ summary }: { summary: Record<string, any> }) {
  return (
    <div className="flex flex-wrap gap-4 p-4 bg-secondary/10 rounded-2xl border border-border/50">
      {Object.entries(summary).map(([key, val]) => {
        const isFine = key.toLowerCase().includes('fine') || key.toLowerCase().includes('overstay')
        const isMoney = key.toLowerCase().includes('revenue') || key.toLowerCase().includes('paid') ||
          key.toLowerCase().includes('charge') || key.toLowerCase().includes('grand') ||
          key.toLowerCase().includes('cash') || key.toLowerCase().includes('mobile') ||
          key.toLowerCase().includes('expense') || key.toLowerCase().includes('profit') || isFine
        return (
          <div key={key} className="flex flex-col gap-0.5">
            <span className="text-[9px] font-black uppercase tracking-widest text-muted-foreground">
              {key.replace(/([A-Z])/g, ' $1')}
            </span>
            <span className={cn(
              "text-[15px] font-black",
              isFine && typeof val === 'number' && val > 0 ? "text-amber-500" : "text-foreground"
            )}>
              {typeof val === 'number' && isMoney
                ? `Tsh ${val.toLocaleString()}`
                : String(val)}
            </span>
          </div>
        )
      })}
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
  const [isPrintModalOpen, setIsPrintModalOpen] = useState(false)

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
                ? tab.id === 'overstay'
                  ? "bg-amber-500 text-white shadow-lg shadow-amber-500/20"
                  : "bg-primary text-white shadow-lg shadow-primary/20"
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
            <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6">
              <StatCard title="Total Revenue (30 Days)" value={`Tsh ${(overviewQuery.data?.keyMetrics?.totalRevenue ?? 0).toLocaleString()}`} icon="combo-chart" trend={{ value: 0, label: "Live data", isPositive: true }} delay={0.1} />
              <StatCard title="Total Fines Charged" value={`Tsh ${(overviewQuery.data?.keyMetrics?.totalFines ?? 0).toLocaleString()}`} icon="warning-shield" trend={{ value: 0, label: "Overstay penalties", isPositive: false }} delay={0.15} />
              <StatCard title="Avg Session Duration" value={overviewQuery.data?.keyMetrics?.avgSessionDuration ?? '—'} icon="monitor" trend={{ value: 0, label: "Live data", isPositive: true }} delay={0.2} />
              <StatCard title="Total Vehicles (30 Days)" value={(overviewQuery.data?.keyMetrics?.totalVehicles ?? 0).toLocaleString()} icon="car" trend={{ value: 0, label: "Live data", isPositive: true }} delay={0.3} />
            </div>

            <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
              <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.4 }} className="xl:col-span-2 glass border border-border rounded-3xl p-6 min-h-[380px] flex flex-col shadow-sm">
                <h3 className="text-[13px] font-black uppercase tracking-widest text-foreground mb-6">Revenue & Fines Trajectory (30 Days)</h3>
                <div className="flex-1 min-h-[280px]">
                  <ResponsiveContainer width="100%" height="100%">
                    <AreaChart data={overviewQuery.data?.revenueOverTime ?? []} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                      <defs>
                        <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="#10b981" stopOpacity={0.3} />
                          <stop offset="95%" stopColor="#10b981" stopOpacity={0} />
                        </linearGradient>
                        <linearGradient id="colorFines" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="#f59e0b" stopOpacity={0.3} />
                          <stop offset="95%" stopColor="#f59e0b" stopOpacity={0} />
                        </linearGradient>
                      </defs>
                      <CartesianGrid strokeDasharray="3 3" vertical={false} stroke={gridColor} />
                      <XAxis dataKey="date" tickFormatter={(val) => format(new Date(val), 'MMM dd')} axisLine={false} tickLine={false} tick={{ fontSize: 10, fill: tickColor, fontWeight: 900 }} dy={10} />
                      <YAxis axisLine={false} tickLine={false} tickFormatter={(val) => `${val >= 1000 ? (val / 1000) + 'k' : val}`} tick={{ fontSize: 10, fill: tickColor, fontWeight: 900 }} />
                      <Tooltip contentStyle={{ background: tooltipBg, border: `1px solid ${tooltipBorder}`, borderRadius: '12px', fontSize: '12px', fontWeight: 900 }} formatter={(v: any, name: any) => [`Tsh ${Number(v).toLocaleString()}`, name === 'revenue' ? 'Parking Revenue' : 'Fines']} labelFormatter={(l) => format(new Date(l), 'MMM dd, yyyy')} />
                      <Area type="monotone" dataKey="revenue" stroke="#10b981" strokeWidth={3} fillOpacity={1} fill="url(#colorRevenue)" dot={false} activeDot={{ r: 5, fill: '#10b981', strokeWidth: 0 }} />
                      <Area type="monotone" dataKey="fines" stroke="#f59e0b" strokeWidth={2} fillOpacity={1} fill="url(#colorFines)" dot={false} activeDot={{ r: 4, fill: '#f59e0b', strokeWidth: 0 }} />
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

            {/* Overstay banner */}
            {activeTab === 'overstay' && (
              <div className="flex items-center gap-3 p-4 rounded-2xl bg-amber-500/10 border border-amber-500/30">
                <Icons8 icon="warning-shield" className="w-6 h-6 shrink-0" />
                <div>
                  <p className="text-[12px] font-black text-amber-600 dark:text-amber-400">Overstay & Fines Report</p>
                  <p className="text-[11px] text-muted-foreground">Shows all sessions where a fine was charged due to vehicle overstay past the allowed time limit.</p>
                </div>
              </div>
            )}

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
                { label: '90 Days', days: 90 },
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
              {/* Header + Export bar */}
              <div className="px-6 py-4 border-b border-border/50 flex items-center gap-4 flex-wrap">
                <h3 className={cn(
                  "text-[13px] font-black uppercase tracking-widest",
                  activeTab === 'overstay' ? "text-amber-500" : "text-foreground"
                )}>
                  {activeConfig.label}
                </h3>
                <ExportBar
                  onPDF={handlePDF}
                  onCSV={handleCSV}
                  onPrint={() => setIsPrintModalOpen(true)}
                  isExporting={isExporting}
                  rowCount={rows.length}
                  filtered={rows.length}
                />
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
      <PrintOptionsModal
        open={isPrintModalOpen}
        onOpenChange={setIsPrintModalOpen}
        rows={rows}
        summary={summary}
        title={activeConfig.label}
      />
    </div>
  )
}

function PrintOptionsModal({ open, onOpenChange, rows, summary, title }: { open: boolean, onOpenChange: (open: boolean) => void, rows: any[], summary: any, title: string }) {
  const [printers, setPrinters] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (open) {
      const saved = localStorage.getItem('network_printers_list');
      if (saved) {
        try { setPrinters(JSON.parse(saved)); } catch (e) {}
      }
    }
  }, [open]);

  const handleSystemPrint = () => {
    onOpenChange(false);
    setTimeout(() => window.print(), 100);
  };

  const handleNetworkPrint = async (printer: any) => {
    setLoading(true);
    try {
      let text = `=== ${title.toUpperCase()} ===\n\n`;
      if (summary) {
        Object.entries(summary).forEach(([k, v]) => {
          text += `${k.replace(/([A-Z])/g, ' $1').toUpperCase()}: ${v}\n`;
        });
        text += "-----------------------\n";
      }
      text += `Total Records: ${rows.length}\n`;
      text += "=======================\n\n\n\n\n";

      await apiClient.post("/api/printer/print", {
        ip: printer.ip,
        port: printer.port || 9100,
        data: text,
      });
      onOpenChange(false);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[400px]">
        <DialogHeader>
          <DialogTitle>Print Options</DialogTitle>
        </DialogHeader>
        <div className="space-y-3 mt-4">
          <Button variant="outline" className="w-full justify-start h-12" onClick={handleSystemPrint}>
            <Icons8 icon="printer" className="w-5 h-5 mr-3" />
            Standard Print (A4)
          </Button>
          
          {printers.length > 0 && (
            <div className="pt-4 pb-2">
              <h4 className="text-xs font-bold text-muted-foreground uppercase tracking-widest mb-2">Network Thermal Printers</h4>
              <div className="space-y-2">
                {printers.map(p => (
                  <Button key={p.id} variant="secondary" className="w-full justify-start h-12 relative" disabled={loading} onClick={() => handleNetworkPrint(p)}>
                    <Icons8 icon="box" className="w-5 h-5 mr-3" />
                    <div className="flex flex-col items-start">
                      <span>{p.name}</span>
                      <span className="text-[10px] opacity-70 font-mono">{p.ip}:{p.port}</span>
                    </div>
                    {p.isDefault && <span className="absolute right-3 top-1/2 -translate-y-1/2 text-[9px] bg-primary/20 text-primary px-2 py-0.5 rounded-md">Default</span>}
                  </Button>
                ))}
              </div>
            </div>
          )}
          
          {printers.length === 0 && (
            <p className="text-xs text-muted-foreground mt-4 text-center">
              No thermal printers configured.<br/>Add them in Settings &gt; Printers.
            </p>
          )}
        </div>
      </DialogContent>
    </Dialog>
  );
}
