import { Injectable, BadRequestException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationService } from '../notification/notification.service';
import * as bcrypt from 'bcrypt';

@Injectable()
export class UserService {
  constructor(
    private prisma: PrismaService,
    private notificationService: NotificationService,
  ) {}

  async findAll(siteId?: string) {
    const whereClause: any = { isActive: true };
    if (siteId && siteId !== 'all') {
      whereClause.siteId = siteId;
    }

    return this.prisma.user.findMany({
      where: whereClause,
      include: { site: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async create(data: any) {
    if (!data.phone || !data.name || !data.role) {
      throw new BadRequestException('Phone, name, and role are required');
    }

    const existing = await this.prisma.user.findUnique({
      where: { phone: data.phone },
    });

    if (existing) {
      throw new ConflictException('User with this phone already exists');
    }
    
    if (data.email) {
      const existingEmail = await this.prisma.user.findUnique({ where: { email: data.email }});
      if (existingEmail) throw new ConflictException('User with this email already exists');
    }

    const rawPassword = data.password || Math.random().toString(36).slice(-8);
    const hashedPassword = await bcrypt.hash(rawPassword, 10);

    const user = await this.prisma.user.create({
      data: {
        phone: data.phone,
        email: data.email || null,
        password: hashedPassword,
        name: data.name,
        role: data.role,
        siteId: data.siteId || null,
        isActive: true,
      },
      select: { id: true, name: true, phone: true, email: true, role: true, site: true, createdAt: true },
    });
    
    if (data.email) {
       await this.notificationService.sendEmail(
         data.email, 
         'Welcome to Smart Parking!', 
         `<h3>Hello ${data.name},</h3><p>Your account has been created.</p><p><b>Phone:</b> ${data.phone}</p><p><b>Password:</b> ${rawPassword}</p><p>Please log in and change your password.</p>`
       );
    }
    return user;
  }

  async update(id: string, data: any) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) throw new BadRequestException('User not found');

    const updateData: any = {
      name: data.name,
      role: data.role,
      siteId: data.siteId || null,
    };

    if ('email' in data) {
      if (data.email && data.email !== user.email) {
        const existingEmail = await this.prisma.user.findUnique({ where: { email: data.email } });
        if (existingEmail) throw new ConflictException('Email is already taken');
      }
      updateData.email = data.email || null;
    }

    if (data.phone && data.phone !== user.phone) {
      const existing = await this.prisma.user.findUnique({ where: { phone: data.phone } });
      if (existing) throw new ConflictException('Phone number is already taken');
      updateData.phone = data.phone;
    }

    if (data.password) {
      updateData.password = await bcrypt.hash(data.password, 10);
    }

    const updatedUser = await this.prisma.user.update({
      where: { id },
      data: updateData,
      select: { id: true, name: true, phone: true, email: true, role: true, site: true, createdAt: true },
    });

    if (data.password) {
      await this.notificationService.sendWhatsapp(
        updatedUser.phone,
        `Hello ${updatedUser.name}, your Locomotors Parking account password has been updated. Your new password is: ${data.password}`
      );
      
      await this.notificationService.sendSms(
        updatedUser.phone,
        `Locomotors Parking: Hello ${updatedUser.name}, your password has been updated to: ${data.password}`
      );
    }

    return updatedUser;
  }

  async remove(id: string) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) throw new BadRequestException('User not found');

    // Option C: Soft Delete
    return this.prisma.user.update({
      where: { id },
      data: { isActive: false },
    });
  }
}
