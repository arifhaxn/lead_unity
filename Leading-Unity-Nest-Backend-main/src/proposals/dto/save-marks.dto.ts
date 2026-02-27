/* eslint-disable prettier/prettier */
import { IsBoolean, IsNotEmpty, IsNumber, IsString, Min } from 'class-validator';

export class SaveMarkDto {
  @IsString()
  @IsNotEmpty()
  studentId!: string;

  @IsNumber()
  @Min(0)
  criteria1!: number;

  @IsNumber()
  @Min(0)
  criteria2!: number;
  @IsBoolean()
  isAbsent!: boolean;
}