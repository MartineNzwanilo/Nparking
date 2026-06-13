import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationService } from '../notification/notification.service';

type SessionActor = {
  userId: string;
  role: string;
  siteId?: string | null;
};

@Injectable()
export class SessionService {
  private readonly logger = new Logger(SessionService.name);

  constructor(
    private prisma: PrismaService,
    private notificationService: NotificationService,
  ) {}

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

  private async triggerCheckInNotifications(
    sessionId: string,
    shouldSendSms: boolean,
    shouldSendEmail: boolean,
  ) {
    try {
      const session = await this.prisma.parkingSession.findUnique({
        where: { id: sessionId },
        include: {
          vehicle: {
            include: { category: true },
          },
          site: true,
        },
      });

      if (!session) return;

      // 1. BEEM AFRICA SMS TRIGGER
      if (shouldSendSms && (session.driverPhone || session.vehicle.phone)) {
        const recipientPhone = session.driverPhone || session.vehicle.phone;
        if (recipientPhone) {
          const settings = await this.prisma.systemSettings.findUnique({ where: { id: 'global' } });
          const template = settings?.smsTemplate ?? "Nparking: Vehicle {plateNumber} ({categoryName}) checked in at {siteName} by {driverName}. Date: {checkInTime}. Fee: TZS {amountDue}. Code: {ticketCode}. Thank you!";
          
          const formattedTime = new Date(session.checkIn).toLocaleString('en-GB', {
            timeZone: 'Africa/Dar_es_Salaam',
            day: '2-digit',
            month: '2-digit',
            year: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            hour12: false,
          }).replace(',', '');
          const shortCode = session.id.substring(0, 8).toUpperCase();
          
          const propertiesText = session.propertiesLeft ? `Items left: ${session.propertiesLeft}. ` : '';
          const message = template
            .replace(/{plateNumber}/g, session.vehicle.plateNumber)
            .replace(/{categoryName}/g, session.vehicle.category.name)
            .replace(/{siteName}/g, session.site.name)
            .replace(/{driverName}/g, session.driverName || 'Customer')
            .replace(/{checkInTime}/g, formattedTime)
            .replace(/{amountDue}/g, session.amountDue.toString())
            .replace(/{ticketCode}/g, shortCode)
            .replace(/{propertiesLeft}/g, propertiesText);

          const smsResult = await this.notificationService.sendSms(recipientPhone, message);
          if (smsResult) {
            await this.prisma.parkingSession.update({
              where: { id: sessionId },
              data: { smsSent: true },
            });
          }
        }
      }

      // 2. SMTP EMAIL RECEIPT TICKET TRIGGER
      if (shouldSendEmail && (session.driverEmail || session.vehicle.phone)) {
        const recipientEmail = session.driverEmail;
        if (recipientEmail) {
          const shortCode = session.id.substring(0, 8).toUpperCase();
          const formattedTime = new Date(session.checkIn).toLocaleString('en-US', {
            timeZone: 'Africa/Dar_es_Salaam',
            hour12: true,
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
          });

          const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Parking Entry Ticket</title>
  <style>
    body {
      font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
      background-color: #f5f6f8;
      margin: 0;
      padding: 0;
      -webkit-font-smoothing: antialiased;
    }
    .container {
      max-width: 500px;
      margin: 40px auto;
      background-color: #ffffff;
      border-radius: 24px;
      overflow: hidden;
      box-shadow: 0 10px 30px rgba(0,0,0,0.05);
      border: 1px solid #eef0f3;
    }
    .header {
      background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
      color: #ffffff;
      padding: 40px 20px;
      text-align: center;
    }
    .logo-text {
      font-size: 13px;
      font-weight: 900;
      letter-spacing: 2px;
      text-transform: uppercase;
      opacity: 0.8;
      margin-bottom: 8px;
    }
    .title {
      font-size: 24px;
      font-weight: 800;
      margin: 0;
      letter-spacing: 0.5px;
    }
    .content {
      padding: 40px 30px;
    }
    .ticket-card {
      background-color: #f8fafc;
      border: 1px dashed #cbd5e1;
      border-radius: 16px;
      padding: 24px;
      margin-bottom: 30px;
      position: relative;
    }
    .ticket-row {
      display: flex;
      justify-content: space-between;
      margin-bottom: 12px;
      font-size: 14px;
    }
    .ticket-row:last-child {
      margin-bottom: 0;
      padding-top: 12px;
      border-top: 1px solid #e2e8f0;
    }
    .label {
      color: #64748b;
      font-weight: 500;
    }
    .value {
      color: #0f172a;
      font-weight: 700;
    }
    .value.highlight {
      color: #3b82f6;
    }
    .value.success {
      color: #10b981;
      font-size: 16px;
    }
    .qr-placeholder {
      text-align: center;
      margin: 20px 0;
      padding: 15px;
      background: #ffffff;
      border-radius: 12px;
      display: inline-block;
      border: 1px solid #e2e8f0;
    }
    .qr-text {
      font-size: 11px;
      color: #94a3b8;
      margin-top: 6px;
      font-weight: bold;
      letter-spacing: 0.5px;
      text-transform: uppercase;
    }
    .footer {
      text-align: center;
      padding: 0 30px 40px 30px;
      font-size: 12px;
      color: #94a3b8;
      line-height: 1.5;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo-text">Nparking System</div>
      <h1 class="title">ENTRY TICKET</h1>
    </div>
    <div class="content">
      <div class="ticket-card">
        <div style="text-align: center; margin-bottom: 20px;">
          <div class="qr-placeholder">
            <div style="font-size: 18px; font-weight: 900; color: #000; letter-spacing: 1px; font-family: monospace;">[ NPS TICKET ]</div>
            <div class="qr-text">${shortCode}</div>
          </div>
        </div>
        <div class="ticket-row">
          <span class="label">Ticket ID</span>
          <span class="value">${shortCode}</span>
        </div>
        <div class="ticket-row">
          <span class="label">Plate Number</span>
          <span class="value highlight">${session.vehicle.plateNumber}</span>
        </div>
        <div class="ticket-row">
          <span class="label">Vehicle Category</span>
          <span class="value">${session.vehicle.category.name}</span>
        </div>
        <div class="ticket-row">
          <span class="label">Parking Site</span>
          <span class="value">${session.site.name}</span>
        </div>
        <div class="ticket-row">
          <span class="label">Date & Time</span>
          <span class="value">${formattedTime}</span>
        </div>
        <div class="ticket-row">
          <span class="label">Driver Name</span>
          <span class="value">${session.driverName || 'N/A'}</span>
        </div>
        <div class="ticket-row">
          <span class="label">Amount Paid</span>
          <span class="value success">TZS ${session.amountDue.toFixed(0)}</span>
        </div>
      </div>
      <p style="color: #64748b; font-size: 13px; line-height: 1.6; margin: 0; text-align: center;">
        Please keep this email safe. You will need the ticket code <b>${shortCode}</b> or your license plate number to check out and calculate your parking duration.
      </p>
    </div>
    <div class="footer">
      This is an automated parking receipt from NGEWA PARKING SYSTEM(NPS).<br>
      © 2026 NGEWA PARKING SYSTEM(NPS). All rights reserved.
    </div>
  </div>
</body>
</html>
          `;

          const emailResult = await this.notificationService.sendEmail(
            recipientEmail,
            `NGEWA PARKING SYSTEM(NPS) Entry Ticket - ${session.vehicle.plateNumber}`,
            html,
          );

          if (emailResult) {
            await this.prisma.parkingSession.update({
              where: { id: sessionId },
              data: { emailSent: true },
            });
          }
        }
      }
    } catch (err) {
      this.logger.error(`Failed to execute background notifications: ${err.message}`);
    }
  }

  async checkIn(
    data: {
      plateNumber: string;
      categoryName: string;
      amount?: number;
      driverName?: string;
      driverPhone?: string;
      driverCompany?: string;
      driverEmail?: string;
      autoSendEmail?: boolean;
      autoSendSms?: boolean;
      propertiesLeft?: string;
      siteId?: string;
      isPreCheckIn?: boolean;
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

    const { user, siteId: defaultSiteId } = await this.resolveOperatorContext(actor);
    const siteId = data.siteId || defaultSiteId;

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

    const shouldSendSms = data.autoSendSms !== undefined ? data.autoSendSms : user.autoSendSms;
    const shouldSendEmail = data.autoSendEmail !== undefined ? data.autoSendEmail : user.autoSendEmail;

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
        driverEmail: data.driverEmail?.trim() || null,
        propertiesLeft: data.propertiesLeft?.trim() || null,
        isPreCheckIn: data.isPreCheckIn || false,
      },
    });

    // Create the Payment if amount > 0 (or just record it), unless it's a pre-checkin
    if (amountDue > 0 && !data.isPreCheckIn) {
      await this.prisma.payment.create({
        data: {
          sessionId: session.id,
          amount: amountDue,
          method: 'CASH',
        },
      });
    }

    // Trigger check-in notifications asynchronously in background
    if ((shouldSendSms || shouldSendEmail) && !data.isPreCheckIn) {
      this.triggerCheckInNotifications(session.id, shouldSendSms, shouldSendEmail)
        .catch(err => {
          this.logger.error(`Error processing check-in notifications for session ${session.id}: ${err.message}`);
        });
    }

    const populatedSession = await this.prisma.parkingSession.findUnique({
      where: { id: session.id },
      include: {
        vehicle: {
          include: { category: true },
        },
        payment: true,
        watchman: { select: { name: true } },
      },
    });

    return populatedSession;
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
        watchman: { select: { name: true } },
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
      driverName?: string;
      driverPhone?: string;
      driverCompany?: string;
      driverEmail?: string;
      paymentAmount?: number;
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

    const isPreCheckIn = session.isPreCheckIn;
    const isLodgeApproved = session.lodgeRequestStatus === 'APPROVED';

    // Create payment if this was a pre-check-in, UNLESS it's lodge approved
    if (isPreCheckIn && !isLodgeApproved && data.paymentAmount && data.paymentAmount > 0) {
      const existingPayment = await this.prisma.payment.findUnique({
        where: { sessionId },
      });
      if (!existingPayment) {
        await this.prisma.payment.create({
          data: {
            sessionId: session.id,
            amount: data.paymentAmount,
            method: 'CASH',
          },
        });
      }
    }

    // Update vehicle details if provided during checkout (common for pre-check-in)
    if (data.driverName || data.driverPhone || data.driverEmail || data.driverCompany) {
      await this.prisma.vehicle.update({
        where: { id: session.vehicleId },
        data: {
          ownerName: data.driverName?.trim() || undefined,
          phone: data.driverPhone?.trim() || undefined,
          email: data.driverEmail?.trim() || undefined,
          company: data.driverCompany?.trim() || undefined,
        },
      });
    }

    const updatedSession = await this.prisma.parkingSession.update({
      where: { id: sessionId },
      data: {
        status: 'CHECKED_OUT',
        checkOut: data.actualDepartureTime ? new Date(data.actualDepartureTime) : new Date(),
        fineAmount: data.fineAmount,
        actualDepartureTime: data.actualDepartureTime ? new Date(data.actualDepartureTime) : null,
        watchmanForgot: data.watchmanForgot || false,
        driverName: data.driverName?.trim() || session.driverName,
        driverPhone: data.driverPhone?.trim() || session.driverPhone,
        driverEmail: data.driverEmail?.trim() || session.driverEmail,
        driverCompany: data.driverCompany?.trim() || session.driverCompany,
      },
    });

    // Optionally send notifications here for pre-check-ins, since they weren't sent at check-in
    if (isPreCheckIn && (user.autoSendSms || user.autoSendEmail)) {
      this.triggerCheckInNotifications(session.id, user.autoSendSms, user.autoSendEmail).catch(err => {
        this.logger.error(`Error processing late check-in notifications for session ${session.id}: ${err.message}`);
      });
    }

    return updatedSession;
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
        watchman: { select: { name: true } },
      },
    });

    const activities = [];

    for (const s of sessions) {
      let checkInSubtitle = `${s.vehicle.category.name} - Collected TZS ${s.payment?.amount || 0}`;
      let activityType = 'Check-In';
      
      if (s.isPreCheckIn && !s.payment) {
        checkInSubtitle = `${s.vehicle.category.name} - Payment Pending (Not Ready)`;
        activityType = 'Early Check-In';
      } else if (s.isPreCheckIn && s.payment) {
        checkInSubtitle = `${s.vehicle.category.name} - Paid (Ready)`;
        activityType = 'Early Check-In';
      }

      // Add Check-In event
      activities.push({
        id: `in_${s.id}`,
        type: activityType,
        title: `${s.vehicle.plateNumber} Checked In`,
        subtitle: checkInSubtitle,
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
    await this.prisma.payment.deleteMany({
      where: { sessionId: { in: ids } },
    });
    return this.prisma.parkingSession.deleteMany({
      where: { id: { in: ids } },
    });
  }

  // --- Lodge Parking Logic ---

  async requestLodgeParking(sessionId: string, actor: SessionActor) {
    const { user } = await this.resolveOperatorContext(actor);
    const session = await this.prisma.parkingSession.findUnique({
      where: { id: sessionId },
    });
    if (!session) throw new NotFoundException('Session not found');
    if (session.status !== 'INSIDE') throw new BadRequestException('Vehicle is already checked out');

    return this.prisma.parkingSession.update({
      where: { id: sessionId },
      data: { lodgeRequestStatus: 'PENDING' },
    });
  }

  async getLodgeRequests(actor: SessionActor, status?: string) {
    const { siteId } = await this.resolveOperatorContext(actor);
    
    const where: any = {};
    
    if (status) {
      where.lodgeRequestStatus = status;
    } else {
      where.lodgeRequestStatus = 'PENDING';
    }

    if (where.lodgeRequestStatus === 'PENDING') {
      where.status = 'INSIDE';
    }

    if (siteId && siteId !== 'all') {
      where.siteId = siteId;
    }

    return this.prisma.parkingSession.findMany({
      where,
      include: {
        vehicle: { include: { category: true } },
        watchman: { select: { name: true } },
      },
      orderBy: { checkIn: 'desc' },
    });
  }

  async approveLodgeRequest(sessionId: string, roomNumber: string, actor: SessionActor) {
    const { user } = await this.resolveOperatorContext(actor);
    if (user.role !== 'LODGEMAN' && user.role !== 'ADMIN') {
      throw new ForbiddenException('Only Lodgeman or Admin can approve requests');
    }

    const session = await this.prisma.parkingSession.findUnique({
      where: { id: sessionId },
    });
    if (!session) throw new NotFoundException('Session not found');

    return this.prisma.parkingSession.update({
      where: { id: sessionId },
      data: {
        lodgeRequestStatus: 'APPROVED',
        lodgeRoomNumber: roomNumber,
        amountDue: 0,
      },
    });
  }

  async rejectLodgeRequest(sessionId: string, actor: SessionActor) {
    const { user } = await this.resolveOperatorContext(actor);
    if (user.role !== 'LODGEMAN' && user.role !== 'ADMIN') {
      throw new ForbiddenException('Only Lodgeman or Admin can reject requests');
    }

    const session = await this.prisma.parkingSession.findUnique({
      where: { id: sessionId },
    });
    if (!session) throw new NotFoundException('Session not found');

    return this.prisma.parkingSession.update({
      where: { id: sessionId },
      data: { lodgeRequestStatus: 'REJECTED' },
    });
  }
}
