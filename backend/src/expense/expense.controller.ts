import { Controller, Get, Post, Body, UseGuards, Request, Query } from '@nestjs/common';
import { ExpenseService } from './expense.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('api/expenses')
@UseGuards(JwtAuthGuard)
export class ExpenseController {
  constructor(private readonly expenseService: ExpenseService) {}

  @Get('categories')
  async getCategories() {
    return this.expenseService.getCategories();
  }

  @Post('categories')
  async createCategory(@Body() body: { name: string }) {
    return this.expenseService.createCategory(body.name);
  }

  @Get()
  async getExpenses(@Query('startDate') startDate?: string, @Query('endDate') endDate?: string) {
    return this.expenseService.getExpenses(startDate, endDate);
  }

  @Post()
  async createExpense(@Request() req: any, @Body() body: any) {
    return this.expenseService.createExpense({
      ...body,
      recordedById: req.user.userId,
    });
  }
}

