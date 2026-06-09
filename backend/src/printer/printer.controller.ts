import { Controller, Get, Post, Patch, Delete, Param, Body, UseGuards, Query } from '@nestjs/common';
import { PrinterService } from './printer.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';

@Controller('api/printer')
@UseGuards(JwtAuthGuard)
export class PrinterController {
  constructor(private readonly printerService: PrinterService) {}

  @Post('print')
  async print(@Body() body: { ip: string; port?: number; data: string }) {
    const { ip, port = 9100, data } = body;
    if (!ip || !data) {
      return { success: false, message: 'IP address and data are required' };
    }
    let finalIp = ip;
    let finalPort = port;
    if (ip.includes(':')) {
      const parts = ip.split(':');
      finalIp = parts[0];
      if (parts.length > 1) {
        finalPort = parseInt(parts[1], 10) || finalPort;
      }
    }
    return this.printerService.printToIp(finalIp, finalPort, data);
  }

  @Get()
  async getPrinters(@Query('siteId') siteId?: string) {
    return this.printerService.getPrinters(siteId);
  }

  @Post()
  @UseGuards(RolesGuard)
  @Roles('ADMIN')
  async createPrinter(
    @Body() data: { name: string; ip: string; siteId: string; isDefault?: boolean; printSimultaneously?: boolean }
  ) {
    return this.printerService.createPrinter(data);
  }

  @Patch(':id')
  @UseGuards(RolesGuard)
  @Roles('ADMIN')
  async updatePrinter(
    @Param('id') id: string,
    @Body() data: { name?: string; ip?: string; isDefault?: boolean; printSimultaneously?: boolean }
  ) {
    return this.printerService.updatePrinter(id, data);
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles('ADMIN')
  async deletePrinter(@Param('id') id: string) {
    return this.printerService.deletePrinter(id);
  }
}
