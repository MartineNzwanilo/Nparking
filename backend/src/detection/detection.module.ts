import { Module } from '@nestjs/common';
import { DetectionService } from './detection.service';
import { DetectionController } from './detection.controller';
import { DetectionGateway } from './detection.gateway';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [DetectionController],
  providers: [DetectionService, DetectionGateway],
})
export class DetectionModule {}
