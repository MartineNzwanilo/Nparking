import { Controller, Get, Post, Body, UseGuards } from '@nestjs/common';
import { AppService } from './app.service';
import { PrismaService } from './prisma/prisma.service';
import { JwtAuthGuard } from './auth/jwt-auth.guard';
import { RolesGuard } from './auth/roles.guard';
import { Roles } from './auth/roles.decorator';

@Controller('api')
export class AppController {
  constructor(
    private readonly appService: AppService,
    private readonly prisma: PrismaService,
  ) {}

  @Get()
  getHello(): string {
    return this.appService.getHello();
  }

  @Get('settings')
  async getSettings() {
    let settings = await this.prisma.systemSettings.findUnique({ where: { id: 'global' } });
    if (!settings) {
      settings = await this.prisma.systemSettings.create({
        data: { id: 'global' },
      });
    }
    return settings;
  }

  @Get('settings/parking')
  async getParkingSettings() {
    const settings = await this.prisma.systemSettings.findUnique({ where: { id: 'global' } });
    return {
      overstayTimeLimit: settings?.overstayTimeLimit ?? '08:00:00',
      overstayFineAmount: settings?.overstayFineAmount ?? 5000,
    };
  }

  @Post('settings')
  async updateSettings(@Body() data: any) {
    return this.prisma.systemSettings.upsert({
      where: { id: 'global' },
      update: {
        smtpHost: data.smtpHost,
        smtpPort: data.smtpPort ? parseInt(data.smtpPort, 10) : null,
        smtpUser: data.smtpUser,
        smtpPassword: data.smtpPassword,
        enableEmailAlerts: data.enableEmailAlerts,
        twilioAccountSid: data.twilioAccountSid,
        twilioAuthToken: data.twilioAuthToken,
        twilioWhatsappNum: data.twilioWhatsappNum,
        enableWhatsappAlerts: data.enableWhatsappAlerts,
        twilioSmsNum: data.twilioSmsNum,
        enableSmsAlerts: data.enableSmsAlerts,
        overstayTimeLimit: data.overstayTimeLimit,
        overstayFineAmount: data.overstayFineAmount ? parseFloat(data.overstayFineAmount) : undefined,
      },
      create: {
        id: 'global',
        smtpHost: data.smtpHost,
        smtpPort: data.smtpPort ? parseInt(data.smtpPort, 10) : null,
        smtpUser: data.smtpUser,
        smtpPassword: data.smtpPassword,
        enableEmailAlerts: data.enableEmailAlerts,
        twilioAccountSid: data.twilioAccountSid,
        twilioAuthToken: data.twilioAuthToken,
        twilioWhatsappNum: data.twilioWhatsappNum,
        enableWhatsappAlerts: data.enableWhatsappAlerts,
        twilioSmsNum: data.twilioSmsNum,
        enableSmsAlerts: data.enableSmsAlerts,
        overstayTimeLimit: data.overstayTimeLimit ?? '08:00:00',
        overstayFineAmount: data.overstayFineAmount ? parseFloat(data.overstayFineAmount) : 5000,
      },
    });
  }

  @Get('access-logs')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ADMIN')
  async getAccessLogs() {
    return this.prisma.accessLog.findMany({
      include: {
        user: {
          select: {
            id: true,
            name: true,
            phone: true,
            role: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
      take: 100,
    });
  }
}
