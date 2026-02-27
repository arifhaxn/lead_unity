/* eslint-disable prettier/prettier */
import { IsNotEmpty, IsString } from 'class-validator';

export class LoginDto {
  // We removed @IsEmail to allow student IDs (e.g. "123456")
  // We just validate that it is a non-empty string.
  @IsString()
  @IsNotEmpty({ message: 'Email or Student ID is required' })
  identifier: string; // Renamed from 'email' to 'identifier' for clarity

  @IsString()
  @IsNotEmpty()
  password: string;
}