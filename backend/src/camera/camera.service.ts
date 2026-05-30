import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class CameraService {
  constructor(private prisma: PrismaService) {}

  async findAll(siteId?: string) {
    const where: any = { isActive: true };
    if (siteId && siteId !== 'all') where.siteId = siteId;
    return this.prisma.camera.findMany({
      where,
      include: { site: true },
      orderBy: { createdAt: 'asc' },
    });
  }

  async create(data: any) {
    if (!data.name || !data.streamUrl) {
      throw new BadRequestException('Camera name and stream URL are required');
    }
    return this.prisma.camera.create({
      data: {
        name: data.name,
        streamUrl: data.streamUrl,
        siteId: data.siteId || null,
      },
      include: { site: true },
    });
  }

  async update(id: string, data: any) {
    const cam = await this.prisma.camera.findUnique({ where: { id } });
    if (!cam) throw new BadRequestException('Camera not found');
    return this.prisma.camera.update({
      where: { id },
      data: {
        name: data.name,
        streamUrl: data.streamUrl,
        siteId: data.siteId || null,
        isActive: data.isActive ?? true,
      },
      include: { site: true },
    });
  }

  async remove(id: string) {
    const cam = await this.prisma.camera.findUnique({ where: { id } });
    if (!cam) throw new BadRequestException('Camera not found');
    return this.prisma.camera.delete({ where: { id } });
  }
}
