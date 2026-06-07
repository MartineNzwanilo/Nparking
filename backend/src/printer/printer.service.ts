import { Injectable, Logger } from '@nestjs/common';
import * as net from 'net';

@Injectable()
export class PrinterService {
  private readonly logger = new Logger(PrinterService.name);

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
        
        // Ensure data is sent properly
        const buffer = Buffer.isBuffer(data) ? data : Buffer.from(data, 'utf-8');
        
        // Full cut command
        const cutCmd = Buffer.from([0x1d, 0x56, 0x42, 0x00]);
        
        socket.write(buffer);
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
}
