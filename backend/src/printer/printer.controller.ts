import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { PrinterService } from './printer.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('api/printer')
export class PrinterController {
  constructor(private readonly printerService: PrinterService) {}

  @UseGuards(JwtAuthGuard)
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
}
