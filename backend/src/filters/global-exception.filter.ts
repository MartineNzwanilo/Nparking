import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';

@Catch()
export class GlobalExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger('ExceptionFilter');

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    // Handle request aborted (client disconnected mid-upload) — do NOT log as error
    if (
      exception instanceof Error &&
      (exception.message === 'Request aborted' ||
        exception.message.includes('aborted') ||
        (exception as any).code === 'ECONNRESET')
    ) {
      // Client disconnected — silently ignore, don't crash
      if (!response.headersSent) {
        response.status(499).json({ message: 'Client disconnected' });
      }
      return;
    }

    // Handle multer file size exceeded
    if (
      exception instanceof Error &&
      (exception as any).code === 'LIMIT_FILE_SIZE'
    ) {
      this.logger.warn(`File too large: ${request.url}`);
      return response.status(413).json({
        statusCode: 413,
        message: 'File too large. Maximum size is 10MB.',
        error: 'Payload Too Large',
      });
    }

    // Handle standard HTTP exceptions
    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const exceptionResponse = exception.getResponse();
      return response.status(status).json(
        typeof exceptionResponse === 'object'
          ? exceptionResponse
          : { statusCode: status, message: exceptionResponse },
      );
    }

    // All other unexpected errors — log them
    this.logger.error(
      `Unhandled error on ${request.method} ${request.url}`,
      exception instanceof Error ? exception.stack : String(exception),
    );

    if (!response.headersSent) {
      response.status(HttpStatus.INTERNAL_SERVER_ERROR).json({
        statusCode: 500,
        message: 'Internal server error',
      });
    }
  }
}
