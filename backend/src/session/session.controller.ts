import {
  Controller,
  Post,
  Body,
  Param,
  Patch,
  Get,
  Req,
  Delete,
  UseGuards,
  Query,
} from '@nestjs/common';
import { SessionService } from './session.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';

@Controller('api/sessions')
@UseGuards(JwtAuthGuard)
export class SessionController {
  constructor(private readonly sessionService: SessionService) {}

  @Get('activity')
  getActivity(
    @Req() req: { user: { userId: string; role: string; siteId?: string | null } },
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    return this.sessionService.getActivityLog(req.user, startDate, endDate);
  }

  @Get(':id')
  findOne(
    @Req()
    req: { user: { userId: string; role: string; siteId?: string | null } },
    @Param('id') id: string,
  ) {
    return this.sessionService.findOne(id, req.user);
  }

  @Post('checkin')
  checkIn(
    @Req()
    req: { user: { userId: string; role: string; siteId?: string | null } },
    @Body()
    data: {
      plateNumber: string;
      categoryName: string;
      amount?: number;
      driverName?: string;
      driverPhone?: string;
      driverCompany?: string;
      propertiesLeft?: string;
      siteId?: string;
    },
  ) {
    return this.sessionService.checkIn(data, req.user);
  }

  @Patch('checkout/:id')
  checkOut(
    @Req()
    req: { user: { userId: string; role: string; siteId?: string | null } },
    @Param('id') id: string,
    @Body()
    data: {
      fineAmount?: number;
      actualDepartureTime?: string;
      watchmanForgot?: boolean;
    },
  ) {
    return this.sessionService.checkOut(id, data, req.user);
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles('ADMIN')
  remove(@Param('id') id: string) {
    return this.sessionService.remove(id);
  }

  @Post('bulk-delete')
  @UseGuards(RolesGuard)
  @Roles('ADMIN')
  bulkRemove(@Body('ids') ids: string[]) {
    return this.sessionService.bulkRemove(ids);
  }
}
