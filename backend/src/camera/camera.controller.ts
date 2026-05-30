import { Controller, Get, Post, Body, Patch, Param, Delete, Query, UseGuards } from '@nestjs/common';
import { CameraService } from './camera.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';

@Controller('api/cameras')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ADMIN')
export class CameraController {
  constructor(private readonly cameraService: CameraService) {}

  @Get()
  findAll(@Query('siteId') siteId?: string) {
    return this.cameraService.findAll(siteId);
  }

  @Post()
  create(@Body() data: any) {
    return this.cameraService.create(data);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() data: any) {
    return this.cameraService.update(id, data);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.cameraService.remove(id);
  }
}
