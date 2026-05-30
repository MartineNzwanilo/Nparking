import { Module } from '@nestjs/common';
import { UserService } from './user.service';
import { UserController } from './user.controller';
import { PrismaModule } from '../prisma/prisma.module';
import { AuthModule } from '../auth/auth.module';
import { NotificationService } from '../notification/notification.service';

@Module({
  imports: [PrismaModule, AuthModule],
  providers: [UserService, NotificationService],
  controllers: [UserController],
})
export class UserModule {}
