import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { DetectionGateway } from './detection.gateway';

@Injectable()
export class DetectionService {
  private readonly logger = new Logger(DetectionService.name);

  constructor(
    private prisma: PrismaService,
    private gateway: DetectionGateway,
  ) {}

  async handleDetection(payload: {
    plate: string;
    cameraId: string;
    vehicleType: string;
    confidence: number;
    snapshot: string;
    detectedAt: string;
  }) {
    const { plate, cameraId, confidence, snapshot, detectedAt } = payload;

    this.logger.log(`Plate detected: ${plate} (conf: ${confidence}) @ camera ${cameraId}`);

    // 1. Look up vehicle in DB
    const vehicle = await this.prisma.vehicle.findUnique({
      where: { plateNumber: plate },
      include: { category: true },
    });

    // 2. Look up camera info
    const camera = await this.prisma.camera.findUnique({
      where: { id: cameraId },
      include: { site: true },
    });

    let status: 'CHECKED_IN' | 'NOT_CHECKED_IN' | 'BLACKLISTED' | 'UNKNOWN';
    let activeSession = null;

    if (!vehicle) {
      // Unknown plate — not in database
      status = 'UNKNOWN';
    } else if (vehicle.isBlacklisted) {
      status = 'BLACKLISTED';
    } else {
      // Check if there is an active (open) session for this vehicle
      activeSession = await this.prisma.parkingSession.findFirst({
        where: { vehicleId: vehicle.id, checkOut: null },
        include: { site: true, watchman: true },
      });
      status = activeSession ? 'CHECKED_IN' : 'NOT_CHECKED_IN';
    }

    // 3. Build the event to broadcast to frontend via WebSocket
    const event = {
      type: 'plate_detected',
      plate,
      confidence,
      cameraId,
      cameraName: camera?.name ?? 'Unknown Camera',
      site: camera?.site?.name ?? null,
      status,
      vehicle: vehicle
        ? {
            id: vehicle.id,
            plateNumber: vehicle.plateNumber,
            ownerName: vehicle.ownerName,
            category: vehicle.category?.name,
            isBlacklisted: vehicle.isBlacklisted,
          }
        : null,
      activeSession: activeSession
        ? {
            id: activeSession.id,
            checkIn: activeSession.checkIn,
            site: activeSession.site?.name,
          }
        : null,
      snapshot,          // base64 image of detected vehicle
      detectedAt,
    };

    // 4. Push to all connected frontend WebSocket clients
    this.gateway.broadcast(event);

    // 5. Return result to Python service
    return { status, vehicle: event.vehicle };
  }
}
