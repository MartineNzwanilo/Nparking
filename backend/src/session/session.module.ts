import { Module } from '@nestjs/common';
import { SessionController } from './session.controller';
import { SessionService } from './session.service';
import { PrismaModule } from '../prisma/prisma.module';
import { AuthModule } from '../auth/auth.module';
import { NotificationService } from '../notification/notification.service';
import { NotificationGateway } from '../notification/notification.gateway';

@Module({
  imports: [PrismaModule, AuthModule],
  controllers: [SessionController],
  providers: [SessionService, NotificationService, NotificationGateway],
})
export class SessionModule {}
