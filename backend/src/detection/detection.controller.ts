import { Controller, Post, Body, Headers, UnauthorizedException } from '@nestjs/common';
import { DetectionService } from './detection.service';

const AI_TOKEN = process.env.AI_SERVICE_TOKEN || 'ai-service-internal-token';

@Controller('api/detections')
export class DetectionController {
  constructor(private readonly detectionService: DetectionService) {}

  @Post()
  async handleDetection(
    @Body() payload: any,
    @Headers('x-ai-token') token: string,
  ) {
    // Simple token guard — only accept from our Python AI service
    if (token !== AI_TOKEN) {
      throw new UnauthorizedException('Invalid AI service token');
    }
    return this.detectionService.handleDetection(payload);
  }
}
