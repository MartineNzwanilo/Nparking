import { useEffect, useState } from 'react';
import { io, Socket } from 'socket.io-client';

export interface DetectionEvent {
  type: string;
  plate: string;
  confidence: number;
  cameraId: string;
  cameraName: string;
  site: string | null;
  status: 'CHECKED_IN' | 'NOT_CHECKED_IN' | 'BLACKLISTED' | 'UNKNOWN';
  vehicle: any;
  activeSession: any;
  snapshot: string;
  detectedAt: string;
}

export function useDetectionSocket() {
  const [socket, setSocket] = useState<Socket | null>(null);
  const [isConnected, setIsConnected] = useState(false);
  const [recentDetections, setRecentDetections] = useState<DetectionEvent[]>([]);

  useEffect(() => {
    // Connect to NestJS WebSocket gateway
    const baseUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';
    const socketInstance = io(`${baseUrl}/detections`);

    socketInstance.on('connect', () => {
      setIsConnected(true);
    });

    socketInstance.on('disconnect', () => {
      setIsConnected(false);
    });

    socketInstance.on('detection', (data: DetectionEvent) => {
      setRecentDetections((prev) => {
        // Prevent duplicate recent detections (same plate within short time)
        const isDuplicate = prev.some(
          (d) => d.plate === data.plate && new Date().getTime() - new Date(d.detectedAt).getTime() < 30000
        );
        if (isDuplicate) return prev;
        
        const newDetections = [data, ...prev].slice(0, 10); // Keep last 10
        return newDetections;
      });
    });

    setSocket(socketInstance);

    return () => {
      socketInstance.disconnect();
    };
  }, []);

  return { isConnected, recentDetections, socket };
}
