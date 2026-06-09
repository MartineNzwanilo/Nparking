import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import * as nodemailer from 'nodemailer';
import { Twilio } from 'twilio';
import * as https from 'https';

@Injectable()
export class NotificationService {
  private readonly logger = new Logger(NotificationService.name);

  constructor(private readonly prisma: PrismaService) {}

  private async getTransporter() {
    const settings = await this.prisma.systemSettings.findUnique({
      where: { id: 'global' },
    });

    if (!settings || !settings.enableEmailAlerts || !settings.smtpHost) {
      return null;
    }

    return nodemailer.createTransport({
      host: settings.smtpHost,
      port: settings.smtpPort || 587,
      secure: settings.smtpPort === 465,
      auth: {
        user: settings.smtpUser,
        pass: settings.smtpPassword,
      },
    } as any);
  }

  async sendEmail(to: string, subject: string, html: string) {
    try {
      const transporter = await this.getTransporter();
      if (!transporter) {
        this.logger.warn('Email alerts disabled or SMTP not configured. Skipping email.');
        return false;
      }

      const settings = await this.prisma.systemSettings.findUnique({ where: { id: 'global' } });

      await transporter.sendMail({
        from: `"NGEWA PARKING SYSTEM(NPS)" <${settings?.smtpUser || 'noreply@ngewa.com'}>`,
        to,
        subject,
        html,
      });

      this.logger.log(`Email sent successfully to ${to}`);
      return true;
    } catch (error) {
      this.logger.error(`Failed to send email to ${to}: ${error.message}`);
      return false;
    }
  }

  async sendWhatsapp(to: string, message: string) {
    try {
      const settings = await this.prisma.systemSettings.findUnique({ where: { id: 'global' } });
      
      if (!settings?.enableWhatsappAlerts || !settings.twilioAccountSid || !settings.twilioAuthToken || !settings.twilioWhatsappNum) {
        this.logger.warn('WhatsApp alerts disabled or Twilio not configured. Skipping WhatsApp message.');
        return false;
      }

      const client = new Twilio(settings.twilioAccountSid, settings.twilioAuthToken);
      
      // Clean up numbers by removing spaces and dashes
      const cleanTo = to.replace(/[\s-]/g, '');
      const cleanFrom = settings.twilioWhatsappNum.replace(/[\s-]/g, '');

      // Ensure the 'to' number is formatted with E.164 (e.g. +1234567890)
      // and prepended with 'whatsapp:'
      const formattedTo = cleanTo.startsWith('+') ? `whatsapp:${cleanTo}` : `whatsapp:+${cleanTo}`;
      const fromNum = cleanFrom.startsWith('+') ? cleanFrom : `+${cleanFrom}`;
      const formattedFrom = `whatsapp:${fromNum}`;

      await client.messages.create({
        body: message,
        from: formattedFrom,
        to: formattedTo
      });

      this.logger.log(`WhatsApp message sent successfully to ${to}`);
      return true;
    } catch (error) {
      this.logger.error(`Failed to send WhatsApp message to ${to}: ${error.message}`);
      return false;
    }
  }

  /** Reliable HTTPS POST using Node's built-in https module (no fetch TLS issues) */
  private httpsPost(url: string, body: string, headers: Record<string, string>): Promise<{ status: number; data: string }> {
    return new Promise((resolve, reject) => {
      const parsed = new URL(url);
      const options = {
        hostname: parsed.hostname,
        port: parsed.port || 443,
        path: parsed.pathname + parsed.search,
        method: 'POST',
        headers: {
          ...headers,
          'Content-Length': Buffer.byteLength(body),
        },
      };
      const req = https.request(options, (res) => {
        let data = '';
        res.on('data', (chunk) => (data += chunk));
        res.on('end', () => resolve({ status: res.statusCode ?? 0, data }));
      });
      req.on('error', reject);
      req.setTimeout(10000, () => { req.destroy(); reject(new Error('HTTPS request timed out')); });
      req.write(body);
      req.end();
    });
  }

  async sendSms(to: string, message: string) {
    try {
      const settings = await this.prisma.systemSettings.findUnique({ where: { id: 'global' } });
      
      // Format number to international format without '+'
      // If it starts with '0', assume Tanzanian and replace with '255'
      let cleanTo = to.replace(/[\s-]/g, '').replace(/^\+/, '');
      if (cleanTo.startsWith('0')) {
        cleanTo = '255' + cleanTo.substring(1);
      }

      // 1. BEEM AFRICA FLOW
      if (settings?.enableBeemSms && settings.beemApiKey && settings.beemSecretKey) {
        const payload = JSON.stringify({
          source_addr: settings.beemSenderId || 'INFO',
          schedule_time: '',
          encoding: 0,
          message: message,
          recipients: [{ recipient_id: 1, dest_addr: cleanTo }],
        });

        const authHeader = 'Basic ' + Buffer.from(`${settings.beemApiKey}:${settings.beemSecretKey}`).toString('base64');

        const { status, data } = await this.httpsPost(
          'https://apisms.beem.africa/v1/send',
          payload,
          { 'Content-Type': 'application/json', 'Authorization': authHeader },
        );

        if (status < 200 || status >= 300) {
          throw new Error(`Beem API returned status ${status}: ${data}`);
        }

        this.logger.log(`SMS sent to ${to} via Beem Africa. Response: ${data}`);
        return true;
      }

      // 2. TWILIO SMS FLOW
      if (!settings?.enableSmsAlerts || !settings.twilioAccountSid || !settings.twilioAuthToken || !settings.twilioSmsNum) {
        this.logger.warn('SMS alerts disabled, neither Twilio nor Beem Africa is fully configured. Skipping SMS.');
        return false;
      }

      const client = new Twilio(settings.twilioAccountSid, settings.twilioAuthToken);
      
      const cleanFrom = settings.twilioSmsNum.replace(/[\s-]/g, '');

      // Ensure the 'to' number is formatted with E.164
      const formattedTo = `+${cleanTo}`;
      
      const payload: any = {
        body: message,
        to: formattedTo
      };

      // If the sender starts with MG, it is a Messaging Service SID
      if (cleanFrom.startsWith('MG')) {
        payload.messagingServiceSid = cleanFrom;
      } else {
        // If the sender contains letters, it's an Alphanumeric Sender ID (do not prepend +)
        const isAlphanumeric = /[a-zA-Z]/.test(cleanFrom);
        payload.from = isAlphanumeric ? cleanFrom : (cleanFrom.startsWith('+') ? cleanFrom : `+${cleanFrom}`);
      }

      await client.messages.create(payload);

      this.logger.log(`SMS sent successfully to ${to} via Twilio`);
      return true;
    } catch (error) {
      this.logger.error(`Failed to send SMS to ${to}: ${error.message}`);
      return false;
    }
  }

  async getBeemBalance(): Promise<any> {
    try {
      const settings = await this.prisma.systemSettings.findUnique({ where: { id: 'global' } });
      if (!settings?.beemApiKey || !settings?.beemSecretKey) {
        return { error: 'Beem Africa is not configured' };
      }

      const authHeader = 'Basic ' + Buffer.from(`${settings.beemApiKey}:${settings.beemSecretKey}`).toString('base64');
      
      return new Promise((resolve) => {
        const req = https.get('https://apisms.beem.africa/public/v1/vendors/balance', {
          headers: {
            'Authorization': authHeader,
            'Content-Type': 'application/json'
          }
        }, (res) => {
          let data = '';
          res.on('data', chunk => data += chunk);
          res.on('end', () => {
            try {
              resolve(JSON.parse(data));
            } catch (e) {
              resolve({ error: 'Failed to parse Beem balance response', data });
            }
          });
        });
        
        req.on('error', (err) => resolve({ error: err.message }));
      });
    } catch (error) {
      return { error: error.message };
    }
  }
}
