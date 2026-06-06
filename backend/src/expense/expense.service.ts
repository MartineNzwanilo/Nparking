import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ExpenseService {
  constructor(private prisma: PrismaService) {}

  async getCategories() {
    return this.prisma.expenseCategory.findMany({
      orderBy: { name: 'asc' },
    });
  }

  async createCategory(name: string) {
    return this.prisma.expenseCategory.create({
      data: { name },
    });
  }

  async getExpenses(startDate?: string, endDate?: string) {
    const where: any = {};
    if (startDate || endDate) {
      where.date = {};
      if (startDate) where.date.gte = new Date(startDate);
      if (endDate) where.date.lte = new Date(endDate);
    }

    return this.prisma.expense.findMany({
      where,
      include: {
        category: true,
        recordedBy: {
          select: { id: true, name: true, phone: true }
        },
        paidToUser: {
          select: { id: true, name: true, phone: true }
        }
      },
      orderBy: { date: 'desc' },
    });
  }

  async createExpense(data: {
    amount: number;
    description?: string;
    categoryId: string;
    recordedById: string;
    paidToUserId?: string;
    date?: string;
  }) {
    // Ensure category exists
    const category = await this.prisma.expenseCategory.findUnique({ where: { id: data.categoryId } });
    if (!category) {
      throw new NotFoundException('Expense category not found');
    }

    return this.prisma.expense.create({
      data: {
        amount: data.amount,
        description: data.description,
        categoryId: data.categoryId,
        recordedById: data.recordedById,
        paidToUserId: data.paidToUserId,
        date: data.date ? new Date(data.date) : new Date(),
      },
      include: {
        category: true,
        recordedBy: { select: { id: true, name: true } },
        paidToUser: { select: { id: true, name: true } },
      }
    });
  }
}

