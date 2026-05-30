import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ReportService } from './report.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';

@Controller('api/reports')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ADMIN')
export class ReportController {
  constructor(private readonly reportService: ReportService) {}

  @Get('dashboard')
  getDashboardMetrics(@Query('siteId') siteId?: string) {
    return this.reportService.getDashboardMetrics(siteId);
  }

  @Get('main')
  getMainDashboard(@Query('siteId') siteId?: string) {
    return this.reportService.getMainDashboard(siteId);
  }

  @Get('daily-revenue')
  getDailyRevenue(
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('siteId') siteId?: string,
  ) {
    return this.reportService.getDailyRevenue(startDate, endDate, siteId);
  }

  @Get('sessions')
  getSessions(
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('siteId') siteId?: string,
  ) {
    return this.reportService.getSessions(startDate, endDate, siteId);
  }

  @Get('staff-performance')
  getStaffPerformance(
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('siteId') siteId?: string,
  ) {
    return this.reportService.getStaffPerformance(startDate, endDate, siteId);
  }

  @Get('vehicle-history')
  getVehicleHistory(
    @Query('plate') plate?: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    return this.reportService.getVehicleHistory(plate, startDate, endDate);
  }

  @Get('site-utilization')
  getSiteUtilization(
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('siteId') siteId?: string,
  ) {
    return this.reportService.getSiteUtilization(startDate, endDate, siteId);
  }

  @Get('security')
  getSecurityReport(
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('siteId') siteId?: string,
  ) {
    return this.reportService.getSecurityReport(startDate, endDate, siteId);
  }
}
