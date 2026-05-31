import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Query,
  UseGuards,
} from '@nestjs/common';
import { VehicleService } from './vehicle.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';

@Controller('api/vehicles')
@UseGuards(JwtAuthGuard)
export class VehicleController {
  constructor(private readonly vehicleService: VehicleService) {}

  @Post()
  create(
    @Body()
    data: {
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
    },
  ) {
    return this.vehicleService.create(data);
  }

  @Get('categories')
  getCategories() {
    return this.vehicleService.getCategories();
  }

  @Post('categories')
  @UseGuards(RolesGuard)
  @Roles('ADMIN')
  createCategory(@Body() data: { name: string; price: number }) {
    return this.vehicleService.createCategory(data);
  }

  @Patch('categories/:id')
  @UseGuards(RolesGuard)
  @Roles('ADMIN')
  updateCategory(@Param('id') id: string, @Body() data: { name?: string; price?: number }) {
    return this.vehicleService.updateCategory(id, data);
  }

  @Delete('categories/:id')
  @UseGuards(RolesGuard)
  @Roles('ADMIN')
  deleteCategory(@Param('id') id: string) {
    return this.vehicleService.deleteCategory(id);
  }

  @Get()
  findAll(@Query('plate') plate?: string) {
    if (plate) {
      return this.vehicleService.search(plate);
    }
    return this.vehicleService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.vehicleService.findOne(id);
  }

  @Patch(':id')
  @UseGuards(RolesGuard)
  @Roles('ADMIN')
  update(
    @Param('id') id: string,
    @Body() data: { 
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
    return this.vehicleService.update(id, data);
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles('ADMIN', 'WATCHMAN')
  remove(@Param('id') id: string) {
    return this.vehicleService.remove(id);
  }
}
