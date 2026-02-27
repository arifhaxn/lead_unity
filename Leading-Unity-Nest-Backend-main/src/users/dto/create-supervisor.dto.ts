import { IsNotEmpty, IsString, MinLength } from 'class-validator';

export class CreateSupervisorDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsNotEmpty()
  abbreviation: string;

  @IsString()
  @IsNotEmpty()
  designation: string;

  @IsString()
  @IsNotEmpty()
  @MinLength(6)
  password: string;
}