import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

type SessionActor = {
  userId: string;
  role: string;
  siteId?: string | null;
};

@Injectable()
export class SessionService {
  constructor(private prisma: PrismaService) {}

  private async resolveOperatorContext(actor: SessionActor) {
    if (!actor?.userId) throw new UnauthorizedException('Missing user context');
    const user = await this.prisma.user.findUnique({
      where: { id: actor.userId },
    });
    if (!user) throw new UnauthorizedException('User not found');

    let siteId = user.siteId ?? actor.siteId ?? null;
    if (!siteId) {
      let defaultSite = await this.prisma.parkingSite.findFirst();
      if (!defaultSite) {
        defaultSite = await this.prisma.parkingSite.create({
          data: {
            name: 'Main Parking Zone',
            location: 'HQ',
            capacity: 100,
          },
        });
      }
      siteId = defaultSite.id;
      await this.prisma.user.update({
        where: { id: user.id },
        data: { siteId },
      });
    }

    return {
      user,
      siteId,
    };
  }

  async checkIn(
    data: {
      plateNumber: string;
      categoryName: string;
      amount?: number;
      driverName?: string;
      driverPhone?: string;
      driverCompany?: string;
      propertiesLeft?: string;
    },
    actor: SessionActor,
  ) {
    const plateNumber = data.plateNumber?.trim().toUpperCase();
    const categoryName = data.categoryName?.trim();
    if (!plateNumber || !categoryName) {
      throw new BadRequestException(
        'plateNumber and categoryName are required',
      );
    }

    const { user, siteId } = await this.resolveOperatorContext(actor);

    let category = await this.prisma.vehicleCategory.findUnique({
      where: { name: categoryName },
    });

    if (!category) {
      category = await this.prisma.vehicleCategory.create({
        data: { name: categoryName, price: 1000 },
      });
    }

    // Find or create vehicle
    let vehicle = await this.prisma.vehicle.findUnique({
      where: { plateNumber },
    });

    if (!vehicle) {
      vehicle = await this.prisma.vehicle.create({
        data: {
          plateNumber,
          categoryId: category.id,
        },
      });
    }

    if (vehicle.isBlacklisted) {
      throw new ForbiddenException('Blacklisted vehicle cannot be checked in');
    }

    const activeSession = await this.prisma.parkingSession.findFirst({
      where: { vehicleId: vehicle.id, status: 'INSIDE' },
    });
    if (activeSession) {
      throw new ConflictException('Vehicle is already checked in');
    }

    const amountDue = category.price;

    // Create the new Session
    const session = await this.prisma.parkingSession.create({
      data: {
        vehicleId: vehicle.id,
        siteId,
        watchmanId: user.id,
        amountDue,
        status: 'INSIDE',
        driverName: data.driverName?.trim() || null,
        driverPhone: data.driverPhone?.trim() || null,
        driverCompany: data.driverCompany?.trim() || null,
        propertiesLeft: data.propertiesLeft?.trim() || null,
      },
    });

    // Create the Payment if amount > 0 (or just record it)
    if (amountDue > 0) {
      await this.prisma.payment.create({
        data: {
          sessionId: session.id,
          amount: amountDue,
          method: 'CASH',
        },
      });
    }

    return session;
  }

  async findOne(id: string, actor: SessionActor) {
    await this.resolveOperatorContext(actor);
    const session = await this.prisma.parkingSession.findUnique({
      where: { id },
      include: {
        vehicle: {
          include: { category: true },
        },
        payment: true,
      },
    });
    if (!session) {
      throw new NotFoundException('Session not found');
    }
    return session;
  }

  async checkOut(
    sessionId: string,
    data: {
      fineAmount?: number;
      actualDepartureTime?: string;
      watchmanForgot?: boolean;
    },
    actor: SessionActor,
  ) {
    const { user } = await this.resolveOperatorContext(actor);
    const session = await this.prisma.parkingSession.findUnique({
      where: { id: sessionId },
    });
    if (!session) {
      throw new NotFoundException('Session not found');
    }
    if (session.status !== 'INSIDE') {
      throw new ConflictException('Session is already checked out');
    }
    if (user.role !== 'ADMIN' && session.watchmanId !== user.id) {
      throw new ForbiddenException(
        'You can only check out sessions created by you',
      );
    }

    return this.prisma.parkingSession.update({
      where: { id: sessionId },
      data: {
        status: 'CHECKED_OUT',
        checkOut: data.actualDepartureTime ? new Date(data.actualDepartureTime) : new Date(),
        fineAmount: data.fineAmount,
        actualDepartureTime: data.actualDepartureTime ? new Date(data.actualDepartureTime) : null,
        watchmanForgot: data.watchmanForgot || false,
      },
    });
  }

  async getActivityLog(actor: SessionActor, startDate?: string, endDate?: string) {
    const { user, siteId } = await this.resolveOperatorContext(actor);
    
    // Build date filter
    let dateFilter: any = {};
    if (startDate && endDate) {
      dateFilter = {
        gte: new Date(startDate),
        lte: new Date(endDate),
      };
    } else {
      // Default to today
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);
      
      dateFilter = {
        gte: today,
        lt: tomorrow,
      };
    }

    const sessions = await this.prisma.parkingSession.findMany({
      where: {
        ...(user.role === 'ADMIN' ? {} : { siteId }),
        checkIn: dateFilter,
      },
      orderBy: { checkIn: 'desc' },
      include: {
        vehicle: {
          include: { category: true },
        },
        payment: true,
      },
    });

    const activities = [];

    for (const s of sessions) {
      // Add Check-In event
      activities.push({
        id: `in_${s.id}`,
        type: 'Check-In',
        title: `${s.vehicle.plateNumber} Checked In`,
        subtitle: `${s.vehicle.category.name} - Collected TZS ${s.payment?.amount || 0}`,
        timestamp: s.checkIn.toISOString(),
        propertiesLeft: s.propertiesLeft,
      });

      // Add Check-Out event if applicable
      if (s.status === 'CHECKED_OUT' && s.checkOut) {
        // Calculate duration safely
        const diffMs = s.checkOut.getTime() - s.checkIn.getTime();
        const diffHrs = Math.floor(diffMs / 3600000);
        const diffMins = Math.floor((diffMs % 3600000) / 60000);

        activities.push({
          id: `out_${s.id}`,
          type: 'Check-Out',
          title: `${s.vehicle.plateNumber} Checked Out`,
          subtitle: `${s.vehicle.category.name} - Stay duration: ${diffHrs}h ${diffMins}m`,
          timestamp: s.checkOut.toISOString(),
        });
      }
    }

    // Sort all events globally descending by time
    activities.sort(
      (a, b) =>
        new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime(),
    );

    return activities;
  }

  async remove(id: string) {
    return this.prisma.$transaction([
      this.prisma.payment.deleteMany({ where: { sessionId: id } }),
      this.prisma.parkingSession.delete({ where: { id } }),
    ]);
  }

  async bulkRemove(ids: string[]) {
    return this.prisma.$transaction([
      this.prisma.payment.deleteMany({ where: { sessionId: { in: ids } } }),
      this.prisma.parkingSession.deleteMany({ where: { id: { in: ids } } }),
    ]);
  }
}
