import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import * as nodemailer from 'nodemailer';
import { Twilio } from 'twilio';

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
        from: `"Locomotors Parking" <${settings?.smtpUser || 'noreply@locomotors.com'}>`,
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

  async sendSms(to: string, message: string) {
    try {
      const settings = await this.prisma.systemSettings.findUnique({ where: { id: 'global' } });
      
      if (!settings?.enableSmsAlerts || !settings.twilioAccountSid || !settings.twilioAuthToken || !settings.twilioSmsNum) {
        this.logger.warn('SMS alerts disabled or Twilio SMS not configured. Skipping SMS message.');
        return false;
      }

      const client = new Twilio(settings.twilioAccountSid, settings.twilioAuthToken);
      
      // Clean up numbers by removing spaces and dashes
      const cleanTo = to.replace(/[\s-]/g, '');
      const cleanFrom = settings.twilioSmsNum.replace(/[\s-]/g, '');

      // Ensure the 'to' number is formatted with E.164
      const formattedTo = cleanTo.startsWith('+') ? cleanTo : `+${cleanTo}`;
      
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

      this.logger.log(`SMS sent successfully to ${to}`);
      return true;
    } catch (error) {
      this.logger.error(`Failed to send SMS to ${to}: ${error.message}`);
      return false;
    }
  }
}
