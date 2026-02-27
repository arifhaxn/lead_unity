/* eslint-disable prettier/prettier */
import { IsString, IsNotEmpty, IsArray, IsMongoId, ValidateNested, IsOptional, IsEmail } from 'class-validator';
import { Type } from 'class-transformer';

class TeamMemberDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsNotEmpty()
  studentId: string;

  @IsString()
  @IsNotEmpty()
  cgpa: string;

  @IsEmail()
  @IsNotEmpty()
  email: string;

  @IsString()
  @IsNotEmpty()
  mobile: string;
}

export class CreateProposalDto {
  @IsString()
  @IsNotEmpty()
  title: string;

  @IsString()
  @IsNotEmpty()
  description: string;
  
  // Validates that it is an array of MongoDB ObjectIds
  @IsArray()
  @IsMongoId({ each: true }) 
  supervisorIds: string[];

  // Validates that it is a single MongoDB ObjectId
  @IsMongoId() 
  courseId: string;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => TeamMemberDto)
  teamMembers: TeamMemberDto[];
}