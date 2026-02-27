/* eslint-disable prettier/prettier */
import { IsNotEmpty, IsNumber, IsString, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class UpdateEvaluationDto {
  // --- Defense Board Criteria ---
  @IsString()
  @IsNotEmpty()
  criteria1Name!: string;

  @IsNumber()
  @Min(1)
  @Type(() => Number) 
  criteria1Max!: number;

  @IsString()
  @IsNotEmpty()
  criteria2Name!: string;

  @IsNumber()
  @Min(1)
  @Type(() => Number)
  criteria2Max!: number;

  // --- Supervisor Own Team Criteria (NEW) ---
  @IsString()
  @IsNotEmpty()
  ownTeamCriteria1Name!: string;

  @IsNumber()
  @Min(1)
  @Type(() => Number)
  ownTeamCriteria1Max!: number;

  @IsString()
  @IsNotEmpty()
  ownTeamCriteria2Name!: string;

  @IsNumber()
  @Min(1)
  @Type(() => Number)
  ownTeamCriteria2Max!: number;
}