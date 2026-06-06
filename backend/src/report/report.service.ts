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

    // Calculate Total Revenue (payments collected)
    const totalRevenue = payments.reduce((sum, p) => sum + p.amount, 0);

    // Calculate Total Fines charged in the period
    const totalFines = sessions.reduce((sum, s) => sum + (s.fineAmount ?? 0), 0);

    // Calculate Total Vehicles
    const totalVehicles = sessions.length;

    // Overstay count
    const overstayCount = sessions.filter(s => (s.fineAmount ?? 0) > 0).length;

    // Calculate Avg Session Duration
    let totalDurationMs = 0;
    let completedSessions = 0;
    sessions.forEach(s => {
      if (s.checkOut) {
        totalDurationMs += s.checkOut.getTime() - s.checkIn.getTime();
        completedSessions++;
      }
    });
    
    const avgDurationHours = completedSessions > 0 ? (totalDurationMs / completedSessions / (1000 * 60 * 60)) : 0;
    const avgHours = Math.floor(avgDurationHours);
    const avgMinutes = Math.floor((avgDurationHours - avgHours) * 60);
    const avgSessionDuration = `${avgHours}h ${avgMinutes}m`;

    // Calculate Revenue Over Time (Daily) — includes fines
    const revenueMap: Record<string, { parking: number; fines: number }> = {};
    
    for (let i = 29; i >= 0; i--) {
        const d = new Date();
        d.setDate(now.getDate() - i);
        const dateStr = d.toISOString().split('T')[0];
        revenueMap[dateStr] = { parking: 0, fines: 0 };
    }

    payments.forEach(p => {
      const dateStr = p.collectedAt.toISOString().split('T')[0];
      if (revenueMap[dateStr] !== undefined) {
        revenueMap[dateStr].parking += p.amount;
      }
    });

    sessions.forEach(s => {
      if (s.fineAmount && s.fineAmount > 0) {
        const dateStr = (s.checkOut ?? s.checkIn).toISOString().split('T')[0];
        if (revenueMap[dateStr] !== undefined) {
          revenueMap[dateStr].fines += s.fineAmount;
        }
      }
    });

    const revenueOverTime = Object.entries(revenueMap).map(([date, d]) => ({
      date,
      revenue: d.parking,
      fines: d.fines,
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
        totalFines,
        overstayCount,
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

    // Yesterday's Revenue
    const yesterdayStart = new Date();
    yesterdayStart.setDate(yesterdayStart.getDate() - 1);
    yesterdayStart.setHours(0, 0, 0, 0);

    const yesterdayEnd = new Date();
    yesterdayEnd.setHours(0, 0, 0, 0);

    const yesterdayPaymentWhere: any = {
      collectedAt: {
        gte: yesterdayStart,
        lt: yesterdayEnd,
      },
    };
    if (siteId && siteId !== 'all') {
      yesterdayPaymentWhere.session = { siteId };
    }
    const yesterdaysPayments = await this.prisma.payment.findMany({
      where: yesterdayPaymentWhere,
    });
    const yesterdaysRevenue = yesterdaysPayments.reduce((sum, p) => sum + p.amount, 0);

    let revenueChangePercent = 0.0;
    if (yesterdaysRevenue > 0) {
      revenueChangePercent = ((todaysRevenue - yesterdaysRevenue) / yesterdaysRevenue) * 100;
    } else if (todaysRevenue > 0) {
      revenueChangePercent = 100.0;
    }

    // Today's Fines
    const todaysFineWhere: any = { checkIn: { gte: today }, fineAmount: { gt: 0 } };
    if (siteId && siteId !== 'all') todaysFineWhere.siteId = siteId;
    const todaysFinesSessions = await this.prisma.parkingSession.findMany({
      where: todaysFineWhere,
      select: { fineAmount: true },
    });
    const todaysFines = todaysFinesSessions.reduce((sum, s) => sum + (s.fineAmount ?? 0), 0);

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
      fineAmount: s.fineAmount ?? 0,
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
      todaysFines,
      activeStaff: activeStaffCount,
      securityAlerts: securityAlertsCount,
      recentActivity,
      hourlyTraffic,
      revenueChangePercent,
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

    // Also fetch fines in this period
    const fineWhere: any = { checkIn: range, fineAmount: { gt: 0 } };
    if (siteId && siteId !== 'all') fineWhere.siteId = siteId;
    const fineSessions = await this.prisma.parkingSession.findMany({
      where: fineWhere,
      select: { fineAmount: true },
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
    const totalFines = fineSessions.reduce((s, r) => s + (r.fineAmount ?? 0), 0);
    const grandTotal = totalRevenue + totalFines;

    return {
      rows,
      summary: {
        totalRevenue,
        totalFines,
        grandTotal,
        cashRevenue,
        mobileRevenue,
        totalTransactions: rows.length,
      },
    };
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
        fineAmount: s.fineAmount ?? 0,
        paid: s.payment ? 'Yes' : 'No',
        paymentMethod: s.payment?.method ?? '—',
      };
    });

    const totalSessions = rows.length;
    const totalParkingRevenue = sessions.reduce((s, r) => s + r.amountDue, 0);
    const totalFines = sessions.reduce((s, r) => s + (r.fineAmount ?? 0), 0);
    const totalRevenue = totalParkingRevenue + totalFines;
    const stillInside = sessions.filter(s => !s.checkOut).length;
    const overstayCount = sessions.filter(s => (s.fineAmount ?? 0) > 0).length;

    return {
      rows,
      summary: {
        totalSessions,
        totalParkingRevenue,
        totalFines,
        totalRevenue,
        overstayCount,
        stillInside,
      },
    };
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

    const staffMap: Record<string, { name: string; sessions: number; revenue: number; fines: number; checkouts: number }> = {};

    sessions.forEach(s => {
      const id = s.watchmanId;
      if (!staffMap[id]) staffMap[id] = { name: s.watchman?.name ?? '—', sessions: 0, revenue: 0, fines: 0, checkouts: 0 };
      staffMap[id].sessions++;
      if (s.payment) staffMap[id].revenue += s.payment.amount;
      if (s.fineAmount && s.fineAmount > 0) staffMap[id].fines += s.fineAmount;
      if (s.checkOut) staffMap[id].checkouts++;
    });

    const rows = Object.values(staffMap).sort((a, b) => b.revenue - a.revenue).map(r => ({
      watchman: r.name,
      totalSessions: r.sessions,
      completedCheckouts: r.checkouts,
      totalRevenue: r.revenue,
      totalFinesCharged: r.fines,
    }));

    return {
      rows,
      summary: {
        totalStaff: rows.length,
        totalRevenue: rows.reduce((s, r) => s + r.totalRevenue, 0),
        totalFinesCharged: rows.reduce((s, r) => s + r.totalFinesCharged, 0),
      },
    };
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
      fineAmount: s.fineAmount ?? 0,
      method: s.payment?.method ?? '—',
      blacklisted: s.vehicle.isBlacklisted ? 'YES' : 'No',
    }));

    return {
      rows,
      summary: {
        totalVisits: rows.length,
        totalPaid: rows.reduce((s, r) => s + r.amountPaid, 0),
        totalFines: rows.reduce((s, r) => s + r.fineAmount, 0),
      },
    };
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

    const siteMap: Record<string, { name: string; vehicles: number; revenue: number; fines: number; categories: Record<string, number> }> = {};

    sessions.forEach(s => {
      const id = s.siteId;
      if (!siteMap[id]) siteMap[id] = { name: s.site?.name ?? '—', vehicles: 0, revenue: 0, fines: 0, categories: {} };
      siteMap[id].vehicles++;
      if (s.payment) siteMap[id].revenue += s.payment.amount;
      if (s.fineAmount && s.fineAmount > 0) siteMap[id].fines += s.fineAmount;
      const cat = s.vehicle.category?.name ?? 'Unknown';
      siteMap[id].categories[cat] = (siteMap[id].categories[cat] || 0) + 1;
    });

    const rows = Object.values(siteMap).sort((a, b) => b.vehicles - a.vehicles).map(r => ({
      site: r.name,
      totalVehicles: r.vehicles,
      totalRevenue: r.revenue,
      totalFines: r.fines,
      topCategory: Object.entries(r.categories).sort((a, b) => b[1] - a[1])[0]?.[0] ?? '—',
      categoryBreakdown: Object.entries(r.categories).map(([k, v]) => `${k}: ${v}`).join(', '),
    }));

    return {
      rows,
      summary: {
        totalSites: rows.length,
        totalVehicles: rows.reduce((s, r) => s + r.totalVehicles, 0),
        totalRevenue: rows.reduce((s, r) => s + r.totalRevenue, 0),
        totalFines: rows.reduce((s, r) => s + r.totalFines, 0),
      },
    };
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

    return {
      rows,
      summary: {
        totalIncidents: rows.length,
        stillInside: rows.filter(r => r.status === 'STILL INSIDE').length,
      },
    };
  }

  // ─── 7. Overstay / Fines Report ───────────────────────────────────────────────
  async getOverstayReport(startDate?: string, endDate?: string, siteId?: string) {
    const range = this.dateRange(startDate, endDate);
    const where: any = { checkIn: range, fineAmount: { gt: 0 } };
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
        parkingCharge: s.amountDue,
        fineAmount: s.fineAmount ?? 0,
        totalCharged: s.amountDue + (s.fineAmount ?? 0),
        paid: s.payment ? 'Yes' : 'No',
        watchmanForgot: s.watchmanForgot ? 'YES' : 'No',
      };
    });

    const totalFines = rows.reduce((s, r) => s + r.fineAmount, 0);
    const totalCharged = rows.reduce((s, r) => s + r.totalCharged, 0);
    const watchmanForgotCount = sessions.filter(s => s.watchmanForgot).length;

    return {
      rows,
      summary: {
        totalOverstays: rows.length,
        totalFines,
        totalCharged,
        watchmanForgotCount,
      },
    };
  }
}
