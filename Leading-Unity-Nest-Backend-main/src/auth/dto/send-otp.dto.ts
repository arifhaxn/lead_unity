import { IsEmail, IsNotEmpty } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class SendOtpDto {
  @ApiProperty({ example: 'student@example.com', description: 'User email for verification' })
  @IsEmail()
  @IsNotEmpty()
  email: string;
}