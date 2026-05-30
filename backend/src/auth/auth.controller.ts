import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './jwt-auth.guard';

@Controller('api/auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('login')
  login(@Body() data: { identifier: string; password: string }) {
    return this.authService.login(data.identifier, data.password);
  }

  @Post('forgot-password')
  forgotPassword(@Body() data: { email: string }) {
    return this.authService.forgotPassword(data.email);
  }

  @Post('reset-password')
  resetPassword(@Body() data: { email: string; otp: string; newPassword: string }) {
    return this.authService.resetPassword(data.email, data.otp, data.newPassword);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  me(@Req() req: { user: { userId: string } }) {
    return this.authService.me(req.user.userId);
  }

  @Post('logout')
  @UseGuards(JwtAuthGuard)
  logout(@Req() req: { user: { userId: string } }) {
    return this.authService.logout(req.user.userId);
  }
}
