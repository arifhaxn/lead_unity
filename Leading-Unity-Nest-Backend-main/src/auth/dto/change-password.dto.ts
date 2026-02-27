/* eslint-disable prettier/prettier */
import { IsNotEmpty, IsString, MinLength } from 'class-validator';

export class ChangePasswordDto {
  // 🟢 Remove @IsEmail()
  // Just ensure it is a non-empty string.
  // We keep the variable name 'email' to avoid refactoring the entire frontend,
  // but it now acts as a generic identifier (Email OR Abbreviation).
  @IsString()
  @IsNotEmpty()
  email: string;

  @IsString()
  @IsNotEmpty()
  oldPassword: string;

  @IsString()
  @IsNotEmpty()
  @MinLength(6)
  newPassword: string;
}