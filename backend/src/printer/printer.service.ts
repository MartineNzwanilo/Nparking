import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import * as net from 'net';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class PrinterService {
  private readonly logger = new Logger(PrinterService.name);

  constructor(private prisma: PrismaService) {}

  async printToIp(ip: string, port: number, data: string | Buffer): Promise<{ success: boolean; message: string }> {
    return new Promise((resolve) => {
      const socket = new net.Socket();
      let hasResponded = false;

      socket.setTimeout(5000); // 5 seconds timeout

      socket.on('error', (err) => {
        this.logger.error(`Error printing to ${ip}:${port} - ${err.message}`);
        if (!hasResponded) {
          hasResponded = true;
          socket.destroy();
          resolve({ success: false, message: `Connection error: ${err.message}` });
        }
      });

      socket.on('timeout', () => {
        this.logger.warn(`Timeout printing to ${ip}:${port}`);
        if (!hasResponded) {
          hasResponded = true;
          socket.destroy();
          resolve({ success: false, message: 'Connection timed out' });
        }
      });

      socket.connect(port, ip, () => {
        this.logger.log(`Connected to printer at ${ip}:${port}`);
        
        // Initialize printer command (ESC @)
        const initCmd = Buffer.from([0x1b, 0x40]);
        
        // Ensure data is sent properly
        const payload = Buffer.isBuffer(data) ? data : Buffer.from(data, 'utf-8');
        
        // Full cut command
        const cutCmd = Buffer.from([0x1d, 0x56, 0x42, 0x00]);
        
        socket.write(initCmd);
        socket.write(payload);
        socket.write(cutCmd);
        
        socket.end(() => {
          if (!hasResponded) {
            hasResponded = true;
            resolve({ success: true, message: 'Printed successfully' });
          }
        });
      });
    });
  }

  async getPrinters(siteId?: string) {
    if (siteId) {
      return this.prisma.printer.findMany({ where: { siteId }, orderBy: { createdAt: 'asc' } });
    }
    return this.prisma.printer.findMany({ orderBy: { createdAt: 'asc' } });
  }

  async createPrinter(data: { name: string; ip: string; siteId: string; isDefault?: boolean; printSimultaneously?: boolean }) {
    if (data.isDefault) {
      await this.prisma.printer.updateMany({
        where: { siteId: data.siteId },
        data: { isDefault: false },
      });
    }
    return this.prisma.printer.create({
      data: {
        name: data.name,
        ip: data.ip,
        siteId: data.siteId,
        isDefault: data.isDefault ?? false,
        printSimultaneously: data.printSimultaneously ?? true,
      },
    });
  }

  async updatePrinter(id: string, data: { name?: string; ip?: string; isDefault?: boolean; printSimultaneously?: boolean }) {
    const printer = await this.prisma.printer.findUnique({ where: { id } });
    if (!printer) throw new NotFoundException('Printer not found');

    if (data.isDefault) {
      await this.prisma.printer.updateMany({
        where: { siteId: printer.siteId, id: { not: id } },
        data: { isDefault: false },
      });
    }

    return this.prisma.printer.update({
      where: { id },
      data,
    });
  }

  async deletePrinter(id: string) {
    const printer = await this.prisma.printer.findUnique({ where: { id } });
    if (!printer) throw new NotFoundException('Printer not found');
    
    await this.prisma.printer.delete({ where: { id } });
    
    if (printer.isDefault) {
      const remaining = await this.prisma.printer.findFirst({ where: { siteId: printer.siteId } });
      if (remaining) {
        await this.prisma.printer.update({
          where: { id: remaining.id },
          data: { isDefault: true },
        });
      }
    }
    return { success: true };
  }
}
