import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ReportService {
  constructor(private prisma: PrismaService) {}

  async getDashboardMetrics(siteId?: string) {
    const now = new Date();
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(now.getDate() - 30);

    const sessionWhere: any = { checkIn: { gte: thirtyDaysAgo } };
    if (siteId && siteId !== 'all') {
      sessionWhere.siteId = siteId;
    }

    // Fetch all sessions and payments from the last 30 days
    const sessions = await this.prisma.parkingSession.findMany({
      where: sessionWhere,
      include: { vehicle: { include: { category: true } } }
    });

    const paymentWhere: any = { collectedAt: { gte: thirtyDaysAgo } };
    if (siteId && siteId !== 'all') {
      paymentWhere.session = { siteId };
    }

    const payments = await this.prisma.payment.findMany({
      where: paymentWhere
    });

    // Calculate Total Revenue
    const totalRevenue = payments.reduce((sum, p) => sum + p.amount, 0);

    // Calculate Total Vehicles
    const totalVehicles = sessions.length;

    // Calculate Avg Session Duration
    let totalDurationMs = 0;
    let completedSessions = 0;
    sessions.forEach(s => {
      if (s.checkOut) {
        totalDurationMs += s.checkOut.getTime() - s.checkIn.getTime();
        completedSessions++;
      }
    });
    
    // Default to 0 if no completed sessions
    const avgDurationHours = completedSessions > 0 ? (totalDurationMs / completedSessions / (1000 * 60 * 60)) : 0;
    const avgHours = Math.floor(avgDurationHours);
    const avgMinutes = Math.floor((avgDurationHours - avgHours) * 60);
    const avgSessionDuration = `${avgHours}h ${avgMinutes}m`;

    // Calculate Revenue Over Time (Daily)
    const revenueMap: Record<string, number> = {};
    
    // Initialize last 30 days with 0 to ensure the chart looks continuous
    for (let i = 29; i >= 0; i--) {
        const d = new Date();
        d.setDate(now.getDate() - i);
        const dateStr = d.toISOString().split('T')[0];
        revenueMap[dateStr] = 0;
    }

    payments.forEach(p => {
      const dateStr = p.collectedAt.toISOString().split('T')[0];
      if (revenueMap[dateStr] !== undefined) {
        revenueMap[dateStr] += p.amount;
      }
    });

    const revenueOverTime = Object.entries(revenueMap).map(([date, revenue]) => ({
      date,
      revenue
    }));

    // Calculate Vehicle Distribution
    const distributionMap: Record<string, number> = {};
    sessions.forEach(s => {
      const catName = s.vehicle?.category?.name || 'Unknown';
      distributionMap[catName] = (distributionMap[catName] || 0) + 1;
    });

    const vehicleDistribution = Object.entries(distributionMap).map(([name, value]) => ({
      name,
      value
    }));

    return {
      keyMetrics: {
        totalRevenue,
        totalVehicles,
        avgSessionDuration
      },
      revenueOverTime,
      vehicleDistribution
    };
  }

  async getMainDashboard(siteId?: string) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const sessionWhere: any = {};
    const paymentWhere: any = { collectedAt: { gte: today } };
    const userWhere: any = { isActive: true };

    if (siteId && siteId !== 'all') {
      sessionWhere.siteId = siteId;
      paymentWhere.session = { siteId };
      userWhere.siteId = siteId;
    }

    // Active Vehicles (currently inside)
    const activeVehiclesCount = await this.prisma.parkingSession.count({
      where: { ...sessionWhere, checkOut: null },
    });

    // Today's Revenue
    const todaysPayments = await this.prisma.payment.findMany({
      where: paymentWhere,
    });
    const todaysRevenue = todaysPayments.reduce((sum, p) => sum + p.amount, 0);

    // Active Staff
    const activeStaffCount = await this.prisma.user.count({
      where: userWhere,
    });

    // Security Alerts (Blacklisted vehicles currently inside)
    const securityAlertsCount = await this.prisma.parkingSession.count({
      where: { ...sessionWhere, checkOut: null, vehicle: { isBlacklisted: true } },
    });

    // Recent Activity (Last 10 sessions created)
    const recentActivityRaw = await this.prisma.parkingSession.findMany({
      where: sessionWhere,
      orderBy: { checkIn: 'desc' },
      take: 10,
      include: {
        vehicle: true,
        watchman: true,
      },
    });

    const recentActivity = recentActivityRaw.map(s => ({
      id: s.id,
      action: s.checkOut ? 'CHECK_OUT' : 'CHECK_IN',
      time: s.checkOut || s.checkIn,
      plateNumber: s.vehicle.plateNumber,
      watchmanName: s.watchman.name,
      amountDue: s.amountDue,
    }));

    // Hourly Traffic (Today)
    const sessionsToday = await this.prisma.parkingSession.findMany({
      where: { ...sessionWhere, checkIn: { gte: today } },
    });

    const hourlyMap: Record<number, number> = {};
    for (let i = 0; i < 24; i++) {
      hourlyMap[i] = 0;
    }

    sessionsToday.forEach(s => {
      const hour = s.checkIn.getHours();
      hourlyMap[hour]++;
    });

    const hourlyTraffic = Object.entries(hourlyMap).map(([hour, count]) => ({
      hour: `${hour.padStart(2, '0')}:00`,
      count,
    }));

    return {
      activeVehicles: activeVehiclesCount,
      todaysRevenue,
      activeStaff: activeStaffCount,
      securityAlerts: securityAlertsCount,
      recentActivity,
      hourlyTraffic,
    };
  }

  // ─── Helper to build date where clause ───────────────────────────────────────
  private dateRange(startDate?: string, endDate?: string) {
    const gte = startDate ? new Date(startDate) : new Date(new Date().setDate(new Date().getDate() - 30));
    const lte = endDate ? new Date(new Date(endDate).setHours(23, 59, 59, 999)) : new Date();
    return { gte, lte };
  }

  // ─── 1. Daily Revenue Report ──────────────────────────────────────────────────
  async getDailyRevenue(startDate?: string, endDate?: string, siteId?: string) {
    const range = this.dateRange(startDate, endDate);
    const where: any = { collectedAt: range };
    if (siteId && siteId !== 'all') where.session = { siteId };

    const payments = await this.prisma.payment.findMany({
      where,
      include: { session: { include: { site: true, vehicle: { include: { category: true } } } } },
      orderBy: { collectedAt: 'asc' },
    });

    const rows = payments.map(p => ({
      date: p.collectedAt.toISOString().split('T')[0],
      time: p.collectedAt.toTimeString().slice(0, 5),
      site: p.session?.site?.name ?? '—',
      plate: p.session?.vehicle?.plateNumber ?? '—',
      vehicleType: p.session?.vehicle?.category?.name ?? '—',
      method: p.method,
      amount: p.amount,
      reference: p.reference ?? '—',
    }));

    const totalRevenue = rows.reduce((s, r) => s + r.amount, 0);
    const cashRevenue = rows.filter(r => r.method === 'CASH').reduce((s, r) => s + r.amount, 0);
    const mobileRevenue = rows.filter(r => r.method === 'MOBILE_MONEY').reduce((s, r) => s + r.amount, 0);

    return { rows, summary: { totalRevenue, cashRevenue, mobileRevenue, totalTransactions: rows.length } };
  }

  // ─── 2. Parking Sessions Report ──────────────────────────────────────────────
  async getSessions(startDate?: string, endDate?: string, siteId?: string) {
    const range = this.dateRange(startDate, endDate);
    const where: any = { checkIn: range };
    if (siteId && siteId !== 'all') where.siteId = siteId;

    const sessions = await this.prisma.parkingSession.findMany({
      where,
      include: {
        vehicle: { include: { category: true } },
        site: true,
        watchman: true,
        payment: true,
      },
      orderBy: { checkIn: 'desc' },
    });

    const rows = sessions.map(s => {
      const durationMs = s.checkOut ? s.checkOut.getTime() - s.checkIn.getTime() : null;
      const durationHrs = durationMs ? durationMs / (1000 * 60 * 60) : null;
      const durationStr = durationHrs
        ? `${Math.floor(durationHrs)}h ${Math.floor((durationHrs % 1) * 60)}m`
        : 'Still Inside';
      return {
        checkIn: s.checkIn.toISOString().replace('T', ' ').slice(0, 16),
        checkOut: s.checkOut ? s.checkOut.toISOString().replace('T', ' ').slice(0, 16) : '—',
        plate: s.vehicle.plateNumber,
        vehicleType: s.vehicle.category?.name ?? '—',
        site: s.site?.name ?? '—',
        watchman: s.watchman?.name ?? '—',
        duration: durationStr,
        status: s.status,
        amountDue: s.amountDue,
        paid: s.payment ? 'Yes' : 'No',
        paymentMethod: s.payment?.method ?? '—',
      };
    });

    const totalSessions = rows.length;
    const totalRevenue = sessions.reduce((s, r) => s + r.amountDue, 0);
    const stillInside = sessions.filter(s => !s.checkOut).length;

    return { rows, summary: { totalSessions, totalRevenue, stillInside } };
  }

  // ─── 3. Staff Performance Report ─────────────────────────────────────────────
  async getStaffPerformance(startDate?: string, endDate?: string, siteId?: string) {
    const range = this.dateRange(startDate, endDate);
    const where: any = { checkIn: range };
    if (siteId && siteId !== 'all') where.siteId = siteId;

    const sessions = await this.prisma.parkingSession.findMany({
      where,
      include: { watchman: true, payment: true },
    });

    const staffMap: Record<string, { name: string; sessions: number; revenue: number; checkouts: number }> = {};

    sessions.forEach(s => {
      const id = s.watchmanId;
      if (!staffMap[id]) staffMap[id] = { name: s.watchman?.name ?? '—', sessions: 0, revenue: 0, checkouts: 0 };
      staffMap[id].sessions++;
      if (s.payment) staffMap[id].revenue += s.payment.amount;
      if (s.checkOut) staffMap[id].checkouts++;
    });

    const rows = Object.values(staffMap).sort((a, b) => b.revenue - a.revenue).map(r => ({
      watchman: r.name,
      totalSessions: r.sessions,
      completedCheckouts: r.checkouts,
      totalRevenue: r.revenue,
    }));

    return { rows, summary: { totalStaff: rows.length, totalRevenue: rows.reduce((s, r) => s + r.totalRevenue, 0) } };
  }

  // ─── 4. Vehicle History Report ────────────────────────────────────────────────
  async getVehicleHistory(plate?: string, startDate?: string, endDate?: string) {
    const range = this.dateRange(startDate, endDate);
    const where: any = { checkIn: range };
    if (plate) where.vehicle = { plateNumber: { contains: plate.toUpperCase() } };

    const sessions = await this.prisma.parkingSession.findMany({
      where,
      include: { vehicle: { include: { category: true } }, site: true, watchman: true, payment: true },
      orderBy: { checkIn: 'desc' },
    });

    const rows = sessions.map(s => ({
      plate: s.vehicle.plateNumber,
      vehicleType: s.vehicle.category?.name ?? '—',
      ownerName: s.vehicle.ownerName ?? '—',
      site: s.site?.name ?? '—',
      checkIn: s.checkIn.toISOString().replace('T', ' ').slice(0, 16),
      checkOut: s.checkOut ? s.checkOut.toISOString().replace('T', ' ').slice(0, 16) : 'Still Inside',
      amountPaid: s.payment?.amount ?? 0,
      method: s.payment?.method ?? '—',
      blacklisted: s.vehicle.isBlacklisted ? 'YES' : 'No',
    }));

    return { rows, summary: { totalVisits: rows.length, totalPaid: rows.reduce((s, r) => s + r.amountPaid, 0) } };
  }

  // ─── 5. Site Utilization Report ───────────────────────────────────────────────
  async getSiteUtilization(startDate?: string, endDate?: string, siteId?: string) {
    const range = this.dateRange(startDate, endDate);
    const where: any = { checkIn: range };
    if (siteId && siteId !== 'all') where.siteId = siteId;

    const sessions = await this.prisma.parkingSession.findMany({
      where,
      include: { site: true, vehicle: { include: { category: true } }, payment: true },
    });

    const siteMap: Record<string, { name: string; vehicles: number; revenue: number; categories: Record<string, number> }> = {};

    sessions.forEach(s => {
      const id = s.siteId;
      if (!siteMap[id]) siteMap[id] = { name: s.site?.name ?? '—', vehicles: 0, revenue: 0, categories: {} };
      siteMap[id].vehicles++;
      if (s.payment) siteMap[id].revenue += s.payment.amount;
      const cat = s.vehicle.category?.name ?? 'Unknown';
      siteMap[id].categories[cat] = (siteMap[id].categories[cat] || 0) + 1;
    });

    const rows = Object.values(siteMap).sort((a, b) => b.vehicles - a.vehicles).map(r => ({
      site: r.name,
      totalVehicles: r.vehicles,
      totalRevenue: r.revenue,
      topCategory: Object.entries(r.categories).sort((a, b) => b[1] - a[1])[0]?.[0] ?? '—',
      categoryBreakdown: Object.entries(r.categories).map(([k, v]) => `${k}: ${v}`).join(', '),
    }));

    return { rows, summary: { totalSites: rows.length, totalVehicles: rows.reduce((s, r) => s + r.totalVehicles, 0), totalRevenue: rows.reduce((s, r) => s + r.totalRevenue, 0) } };
  }

  // ─── 6. Security / Blacklist Report ──────────────────────────────────────────
  async getSecurityReport(startDate?: string, endDate?: string, siteId?: string) {
    const range = this.dateRange(startDate, endDate);
    const where: any = { checkIn: range, vehicle: { isBlacklisted: true } };
    if (siteId && siteId !== 'all') where.siteId = siteId;

    const sessions = await this.prisma.parkingSession.findMany({
      where,
      include: { vehicle: { include: { category: true } }, site: true, watchman: true },
      orderBy: { checkIn: 'desc' },
    });

    const rows = sessions.map(s => ({
      plate: s.vehicle.plateNumber,
      vehicleType: s.vehicle.category?.name ?? '—',
      ownerName: s.vehicle.ownerName ?? '—',
      site: s.site?.name ?? '—',
      watchman: s.watchman?.name ?? '—',
      checkIn: s.checkIn.toISOString().replace('T', ' ').slice(0, 16),
      checkOut: s.checkOut ? s.checkOut.toISOString().replace('T', ' ').slice(0, 16) : 'Still Inside',
      status: s.checkOut ? 'EXITED' : 'STILL INSIDE',
    }));

    return { rows, summary: { totalIncidents: rows.length, stillInside: rows.filter(r => r.status === 'STILL INSIDE').length } };
  }
}
