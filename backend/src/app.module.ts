import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { VehicleModule } from './vehicle/vehicle.module';
import { SessionModule } from './session/session.module';
import { AuthModule } from './auth/auth.module';
import { SiteModule } from './site/site.module';
import { UserModule } from './user/user.module';
import { ReportModule } from './report/report.module';
import { CameraModule } from './camera/camera.module';
import { DetectionModule } from './detection/detection.module';

import { NotificationService } from './notification/notification.service';
import { NotificationGateway } from './notification/notification.gateway';
import { ServeStaticModule } from '@nestjs/serve-static';
import { join } from 'path';
import { UploadModule } from './upload/upload.module';
import { ExpenseModule } from './expense/expense.module';
import { PrinterModule } from './printer/printer.module';
import { BackupModule } from './backup/backup.module';

@Module({
  imports: [
    PrismaModule, AuthModule, VehicleModule, SessionModule, SiteModule, UserModule, ReportModule, CameraModule, DetectionModule, UploadModule,
    ServeStaticModule.forRoot({
      rootPath: join(process.cwd(), 'uploads'),
      serveRoot: '/uploads',
    }),
    ExpenseModule,
    PrinterModule,
    BackupModule,
  ],
  controllers: [AppController],
  providers: [AppService, NotificationService, NotificationGateway],
})
export class AppModule {}
