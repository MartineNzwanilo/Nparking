import { Controller, Get, Post, Res, UploadedFile, UseInterceptors, UseGuards, HttpStatus } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { Response } from 'express';
import { BackupService } from './backup.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('api/backup')
@UseGuards(JwtAuthGuard)
export class BackupController {
  constructor(private readonly backupService: BackupService) {}

  @Get('export')
  async exportData(@Res() res: Response) {
    try {
      const data = await this.backupService.exportData();
      
      // Set headers for file download
      const dateStr = new Date().toISOString().split('T')[0];
      res.setHeader('Content-Type', 'application/json');
      res.setHeader('Content-Disposition', `attachment; filename="nparking-backup-${dateStr}.json"`);
      
      return res.status(HttpStatus.OK).send(JSON.stringify(data, null, 2));
    } catch (error) {
      return res.status(HttpStatus.INTERNAL_SERVER_ERROR).json({
        success: false,
        message: 'Failed to export backup',
        error: error instanceof Error ? error.message : String(error)
      });
    }
  }

  @Post('import')
  @UseInterceptors(FileInterceptor('file'))
  async importData(@UploadedFile() file: Express.Multer.File, @Res() res: Response) {
    if (!file) {
      return res.status(HttpStatus.BAD_REQUEST).json({ success: false, message: 'No backup file provided' });
    }

    try {
      const fileContent = file.buffer.toString('utf-8');
      const data = JSON.parse(fileContent);
      
      await this.backupService.importData(data);
      
      return res.status(HttpStatus.OK).json({ success: true, message: 'System restored successfully' });
    } catch (error) {
      return res.status(HttpStatus.INTERNAL_SERVER_ERROR).json({
        success: false,
        message: 'Failed to restore backup',
        error: error instanceof Error ? error.message : String(error)
      });
    }
  }
}
