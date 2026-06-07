import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma.service';

@Injectable()
export class BackupService {
  private readonly logger = new Logger(BackupService.name);

  constructor(private prisma: PrismaService) {}

  async exportData(): Promise<any> {
    this.logger.log('Starting full database export...');
    
    const data: any = {};
    
    data.systemSettings = await this.prisma.systemSettings.findMany();
    data.parkingSites = await this.prisma.parkingSite.findMany();
    data.vehicleCategories = await this.prisma.vehicleCategory.findMany();
    data.expenseCategories = await this.prisma.expenseCategory.findMany();
    data.users = await this.prisma.user.findMany();
    data.vehicles = await this.prisma.vehicle.findMany();
    data.cameras = await this.prisma.camera.findMany();
    data.parkingSessions = await this.prisma.parkingSession.findMany();
    data.payments = await this.prisma.payment.findMany();
    data.expenses = await this.prisma.expense.findMany();
    data.accessLogs = await this.prisma.accessLog.findMany();

    this.logger.log('Database export complete.');
    return data;
  }

  async importData(data: any): Promise<void> {
    this.logger.warn('Starting full database import (RESTORE)...');

    await this.prisma.$transaction(async (tx) => {
      // 1. DELETE EXISTING DATA (Reverse Dependency Order)
      await tx.accessLog.deleteMany();
      await tx.expense.deleteMany();
      await tx.payment.deleteMany();
      await tx.parkingSession.deleteMany();
      await tx.camera.deleteMany();
      await tx.vehicle.deleteMany();
      await tx.user.deleteMany();
      await tx.expenseCategory.deleteMany();
      await tx.vehicleCategory.deleteMany();
      await tx.parkingSite.deleteMany();
      await tx.systemSettings.deleteMany();

      this.logger.log('All existing data wiped successfully.');

      // 2. INSERT NEW DATA (Forward Dependency Order)
      if (data.systemSettings?.length) {
        await tx.systemSettings.createMany({ data: data.systemSettings });
      }
      if (data.parkingSites?.length) {
        await tx.parkingSite.createMany({ data: data.parkingSites });
      }
      if (data.vehicleCategories?.length) {
        await tx.vehicleCategory.createMany({ data: data.vehicleCategories });
      }
      if (data.expenseCategories?.length) {
        await tx.expenseCategory.createMany({ data: data.expenseCategories });
      }
      if (data.users?.length) {
        await tx.user.createMany({ data: data.users });
      }
      if (data.vehicles?.length) {
        await tx.vehicle.createMany({ data: data.vehicles });
      }
      if (data.cameras?.length) {
        await tx.camera.createMany({ data: data.cameras });
      }
      if (data.parkingSessions?.length) {
        await tx.parkingSession.createMany({ data: data.parkingSessions });
      }
      if (data.payments?.length) {
        await tx.payment.createMany({ data: data.payments });
      }
      if (data.expenses?.length) {
        await tx.expense.createMany({ data: data.expenses });
      }
      if (data.accessLogs?.length) {
        await tx.accessLog.createMany({ data: data.accessLogs });
      }

      this.logger.log('Data restore completed successfully.');
    });
  }
}
