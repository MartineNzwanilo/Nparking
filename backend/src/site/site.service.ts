import {
  BadRequestException,
  ConflictException,
  Injectable,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

type CreateSiteInput = {
  name: string;
  location: string;
  capacity?: number;
};

type UpdateSiteInput = Partial<CreateSiteInput>;

@Injectable()
export class SiteService {
  constructor(private prisma: PrismaService) {}

  async create(data: CreateSiteInput) {
    const name = data.name?.trim();
    if (!name) throw new BadRequestException('Site name is required');
    if (!data.location?.trim()) throw new BadRequestException('Site location is required');

    return this.prisma.parkingSite.create({
      data: {
        name,
        location: data.location.trim(),
        capacity: data.capacity ?? 0,
      },
    });
  }

  async findAll() {
    const sites = await this.prisma.parkingSite.findMany({
      include: {
        _count: {
          select: { users: true, sessions: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    const activeSessions = await this.prisma.parkingSession.findMany({
      where: { checkOut: null },
      include: { vehicle: { include: { category: true } } },
    });

    return sites.map(site => {
      const siteSessions = activeSessions.filter(s => s.siteId === site.id);
      const occupancy: Record<string, number> = {};
      siteSessions.forEach(session => {
        const catName = session.vehicle.category.name;
        occupancy[catName] = (occupancy[catName] || 0) + 1;
      });

      return {
        ...site,
        occupancy: Object.entries(occupancy).map(([name, count]) => ({ name, count })),
      };
    });
  }

  async findOne(id: string) {
    const site = await this.prisma.parkingSite.findUnique({
      where: { id },
      include: {
        _count: {
          select: { users: true, sessions: true },
        },
      },
    });

    if (!site) throw new BadRequestException('Site not found');

    const activeSessions = await this.prisma.parkingSession.findMany({
      where: { siteId: id, checkOut: null },
      include: { vehicle: { include: { category: true } } },
    });

    const occupancy: Record<string, number> = {};
    activeSessions.forEach(session => {
      const catName = session.vehicle.category.name;
      occupancy[catName] = (occupancy[catName] || 0) + 1;
    });

    return {
      ...site,
      occupancy: Object.entries(occupancy).map(([name, count]) => ({ name, count })),
    };
  }

  async update(id: string, data: UpdateSiteInput) {
    return this.prisma.parkingSite.update({
      where: { id },
      data: {
        name: data.name?.trim(),
        location: data.location?.trim(),
        capacity: data.capacity,
      },
    });
  }

  async remove(id: string) {
    // Option A: Prevent deletion if users or sessions are linked
    const site = await this.prisma.parkingSite.findUnique({
      where: { id },
      include: {
        _count: {
          select: { users: true, sessions: true },
        },
      },
    });

    if (!site) throw new BadRequestException('Site not found');

    if (site._count.users > 0 || site._count.sessions > 0) {
      throw new BadRequestException(
        `Cannot delete site. It currently contains ${site._count.users} user(s) and ${site._count.sessions} historical parking session(s).`,
      );
    }

    await this.prisma.printer.deleteMany({ where: { siteId: id } });
    await this.prisma.camera.deleteMany({ where: { siteId: id } });

    return this.prisma.parkingSite.delete({
      where: { id },
    });
  }
}
