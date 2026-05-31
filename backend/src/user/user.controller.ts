import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards, Query, Req } from '@nestjs/common';
import { UserService } from './user.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';

@Controller('api/users')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ADMIN')
export class UserController {
  constructor(private readonly userService: UserService) {}

  @Get()
  findAll(@Query('siteId') siteId?: string) {
    return this.userService.findAll(siteId);
  }

  @Patch('profile/settings')
  @Roles('ADMIN', 'WATCHMAN')
  updateProfileSettings(
    @Req() req: { user: { userId: string } },
    @Body() data: { autoPrint?: boolean; autoSendEmail?: boolean; autoSendSms?: boolean }
  ) {
    return this.userService.update(req.user.userId, data);
  }

  @Post()
  create(@Body() data: any) {
    return this.userService.create(data);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() data: any) {
    return this.userService.update(id, data);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.userService.remove(id);
  }
}
