import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationService } from '../notification/notification.service';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly notificationService: NotificationService,
  ) {}

  private async ensureBootstrapUsers() {
    const usersCount = await this.prisma.user.count();
    if (usersCount > 0) return;

    let site = await this.prisma.parkingSite.findFirst();
    if (!site) {
      site = await this.prisma.parkingSite.create({
        data: {
          name: 'Main Parking Zone',
          location: 'HQ',
          capacity: 100,
        },
      });
    }

    const adminPhone = process.env.BOOTSTRAP_ADMIN_PHONE ?? '0999000000';
    const adminPassword = process.env.BOOTSTRAP_ADMIN_PASSWORD ?? 'admin123';
    const watchmanPhone = process.env.BOOTSTRAP_WATCHMAN_PHONE ?? '0000000000';
    const watchmanPassword =
      process.env.BOOTSTRAP_WATCHMAN_PASSWORD ?? 'watch123';

    await this.prisma.user.createMany({
      data: [
        {
          phone: adminPhone,
          password: adminPassword,
          name: 'System Admin',
          role: 'ADMIN',
          siteId: site.id,
        },
        {
          phone: watchmanPhone,
          password: watchmanPassword,
          name: 'Default Watchman',
          role: 'WATCHMAN',
          siteId: site.id,
        },
      ],
    });
  }

  async login(identifierInput: string, passwordInput: string) {
    await this.ensureBootstrapUsers();

    const identifier = identifierInput?.trim();
    const password = passwordInput?.trim();
    if (!identifier || !password) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const user = await this.prisma.user.findFirst({
      where: { 
        OR: [
          { phone: identifier },
          { email: identifier }
        ]
      },
      include: { site: true },
    });

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }
    
    // Check if password matches (bcrypt or plain text fallback for bootstrap users)
    const isMatch = await import('bcrypt').then(bcrypt => bcrypt.compare(password, user.password).catch(() => false));
    if (!isMatch && user.password !== password) {
       throw new UnauthorizedException('Invalid credentials');
    }

    const payload = {
      sub: user.id,
      phone: user.phone,
      role: user.role,
      siteId: user.siteId,
    };
    const accessToken = await this.jwtService.signAsync(payload);

    // Record Access Log
    try {
      await this.prisma.accessLog.create({
        data: {
          userId: user.id,
          action: 'LOGIN',
          details: user.site ? `Logged in at ${user.site.name}` : 'Logged in globally',
        },
      });
    } catch (e) {
      // Fail-safe to ensure logs don't block actual authentication if any DB anomaly occurs
      console.error('Failed to write access log:', e);
    }

    return {
      accessToken,
      user: {
        id: user.id,
        name: user.name,
        phone: user.phone,
        role: user.role,
        siteId: user.siteId,
        autoPrint: user.autoPrint,
        autoSendEmail: user.autoSendEmail,
        autoSendSms: user.autoSendSms,
        avatarUrl: user.avatarUrl,
      },
    };
  }

  async me(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        name: true,
        phone: true,
        email: true,
        role: true,
        siteId: true,
        autoPrint: true,
        autoSendEmail: true,
        autoSendSms: true,
        avatarUrl: true,
      },
    });
    if (!user) throw new UnauthorizedException('User not found');
    return user;
  }

  private otps = new Map<string, { code: string; expires: number }>();

  async forgotPassword(email: string) {
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user) throw new UnauthorizedException('User not found');

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    this.otps.set(email, { code: otp, expires: Date.now() + 15 * 60 * 1000 });
    
    // Send email using notification service
    await this.notificationService.sendEmail(
      email,
      'Password Reset OTP',
      `<p>Hello ${user.name},</p><p>Your password reset code is <b>${otp}</b>. It is valid for 15 minutes.</p>`
    );
    
    return { message: 'OTP sent to email', otp_for_testing: otp };
  }

  async resetPassword(email: string, otp: string, newPassword: string) {
    const record = this.otps.get(email);
    if (!record || record.code !== otp || record.expires < Date.now()) {
      throw new UnauthorizedException('Invalid or expired OTP');
    }

    const bcrypt = await import('bcrypt');
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    await this.prisma.user.update({
      where: { email },
      data: { password: hashedPassword },
    });

    this.otps.delete(email);
    return { message: 'Password updated successfully' };
  }

  async logout(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { site: true },
    });
    if (user) {
      try {
        await this.prisma.accessLog.create({
          data: {
            userId: user.id,
            action: 'LOGOUT',
            details: user.site ? `Logged out from ${user.site.name}` : 'Logged out globally',
          },
        });
      } catch (e) {
        console.error('Failed to write logout access log:', e);
      }
    }
    return { message: 'Logged out successfully' };
  }
}
