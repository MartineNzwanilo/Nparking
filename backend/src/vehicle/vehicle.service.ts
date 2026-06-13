import {
  BadRequestException,
  ConflictException,
  Injectable,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

type CreateVehicleInput = {
  plateNumber: string;
  categoryName: string;
  ownerName?: string;
  phone?: string;
  email?: string;
  company?: string;
  color?: string;
  makeModel?: string;
  frontImage?: string;
  plateImage?: string;
  sideImage?: string;
};

@Injectable()
export class VehicleService {
  constructor(private prisma: PrismaService) {}

  async create(data: CreateVehicleInput) {
    const plateNumber = data.plateNumber?.trim().toUpperCase();
    const categoryName = data.categoryName?.trim();
    if (!plateNumber || !categoryName) {
      throw new BadRequestException(
        'plateNumber and categoryName are required',
      );
    }

    const existing = await this.prisma.vehicle.findUnique({
      where: { plateNumber },
    });
    if (existing) {
      throw new ConflictException('Vehicle already exists');
    }

    let category = await this.prisma.vehicleCategory.findUnique({
      where: { name: categoryName },
    });

    if (!category) {
      category = await this.prisma.vehicleCategory.create({
        data: { name: categoryName, price: 1000 },
      });
    }

    return this.prisma.vehicle.create({
      data: {
        plateNumber,
        ownerName: data.ownerName?.trim() ?? null,
        phone: data.phone?.trim() ?? null,
        email: data.email?.trim() ?? null,
        company: data.company?.trim() ?? null,
        color: data.color?.trim() ?? null,
        makeModel: data.makeModel?.trim() ?? null,
        frontImage: data.frontImage?.trim() ?? null,
        plateImage: data.plateImage?.trim() ?? null,
        sideImage: data.sideImage?.trim() ?? null,
        categoryId: category.id,
      },
      include: { category: true },
    });
  }

  async getCategories() {
    return this.prisma.vehicleCategory.findMany({
      orderBy: { createdAt: 'desc' }
    });
  }

  async createCategory(data: { name: string; price: number }) {
    const name = data.name?.trim();
    if (!name) throw new BadRequestException('Category name is required');
    
    const existing = await this.prisma.vehicleCategory.findUnique({ where: { name } });
    if (existing) throw new ConflictException('Category already exists');

    return this.prisma.vehicleCategory.create({
      data: { name, price: data.price ?? 0 },
    });
  }

  async updateCategory(id: string, data: { name?: string; price?: number }) {
    if (data.name) {
      const existing = await this.prisma.vehicleCategory.findUnique({ where: { name: data.name } });
      if (existing && existing.id !== id) {
        throw new ConflictException('Category name already exists');
      }
    }

    return this.prisma.vehicleCategory.update({
      where: { id },
      data,
    });
  }

  async deleteCategory(id: string) {
    // Option A: Prevent deletion if vehicles are linked
    const vehiclesCount = await this.prisma.vehicle.count({
      where: { categoryId: id },
    });

    if (vehiclesCount > 0) {
      throw new BadRequestException(
        `Cannot delete category. It is currently assigned to ${vehiclesCount} vehicle(s).`
      );
    }

    return this.prisma.vehicleCategory.delete({
      where: { id },
    });
  }

  async findAll() {
    return this.prisma.vehicle.findMany({
      include: {
        category: true,
        sessions: {
          take: 5,
          orderBy: { checkIn: 'desc' },
          include: { site: true, payment: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async search(plate: string) {
    return this.prisma.vehicle.findMany({
      where: { plateNumber: { contains: plate } },
      include: {
        category: true,
        sessions: {
          take: 5,
          orderBy: { checkIn: 'desc' },
          include: { site: true, payment: true },
        },
      },
    });
  }

  async findOne(id: string) {
    return this.prisma.vehicle.findUnique({
      where: { id },
      include: { category: true },
    });
  }

  async update(
    id: string,
    data: { 
      isBlacklisted?: boolean; 
      ownerName?: string;
      categoryName?: string;
      phone?: string;
      email?: string;
      company?: string;
      color?: string;
      makeModel?: string;
      frontImage?: string;
      plateImage?: string;
      sideImage?: string;
    },
  ) {
    const updateData: any = {
      isBlacklisted: data.isBlacklisted,
      ownerName: data.ownerName?.trim(),
      phone: data.phone?.trim(),
      email: data.email?.trim(),
      company: data.company?.trim(),
      color: data.color?.trim(),
      makeModel: data.makeModel?.trim(),
      frontImage: data.frontImage?.trim(),
      plateImage: data.plateImage?.trim(),
      sideImage: data.sideImage?.trim(),
    };

    if (data.categoryName?.trim()) {
      let category = await this.prisma.vehicleCategory.findUnique({
        where: { name: data.categoryName.trim() },
      });

      if (!category) {
        category = await this.prisma.vehicleCategory.create({
          data: { name: data.categoryName.trim(), price: 1000 },
        });
      }
      updateData.categoryId = category.id;
    }

    // Remove undefined fields
    Object.keys(updateData).forEach(key => updateData[key] === undefined && delete updateData[key]);

    return this.prisma.vehicle.update({
      where: { id },
      data: updateData,
      include: { category: true },
    });
  }

  async remove(id: string) {
    const sessions = await this.prisma.parkingSession.findMany({
      where: { vehicleId: id },
      select: { id: true },
    });
    const sessionIds = sessions.map((s) => s.id);

    return this.prisma.$transaction([
      this.prisma.payment.deleteMany({
        where: { sessionId: { in: sessionIds } },
      }),
      this.prisma.parkingSession.deleteMany({
        where: { vehicleId: id },
      }),
      this.prisma.vehicle.delete({
        where: { id },
      }),
    ]);
  }
}
