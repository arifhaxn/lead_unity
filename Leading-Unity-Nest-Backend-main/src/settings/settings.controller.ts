/* eslint-disable prettier/prettier */
import { Body, Controller, Get, Patch, Post, UseGuards } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  AppSettings,
  AppSettingsDocument,
} from './schemas/app-settings.schema';
import { AuthGuard } from '@nestjs/passport';
import { RolesGuard } from '../common/guards/roles.guard';
import { UpdateEvaluationDto } from './dto/update-evaluation.dto';

@Controller('settings')
export class SettingsController {
  constructor(
    @InjectModel(AppSettings.name)
    private settingsModel: Model<AppSettingsDocument>,
  ) {}

  @Get()
  async getSettings() {
    let settings = await this.settingsModel.findOne();
    if (!settings) {
      settings = await this.settingsModel.create({
        isStudentRegistrationOpen: false,
      });
    }
    return settings;
  }

    // NEW ENDPOINT
  @Patch('toggle-submission')
  @UseGuards(AuthGuard('jwt'), new RolesGuard(['admin']))
  async toggleSubmission() {
    const settings = await this.settingsModel.findOne();
    if (settings) {
      settings.isSubmissionOpen = !settings.isSubmissionOpen;
      return settings.save();
    } else {
      // Create with default true if not exists
      return this.settingsModel.create({ isSubmissionOpen: true });
    }
  }

  @Patch('toggle-registration')
  @UseGuards(AuthGuard('jwt'), new RolesGuard(['admin']))
  async toggleRegistration() {
    const settings = await this.settingsModel.findOne();
    if (settings) {
      settings.isStudentRegistrationOpen = !settings.isStudentRegistrationOpen;
      return settings.save();
    } else {
      return this.settingsModel.create({ isStudentRegistrationOpen: true });
    }
  }

  @Post('evaluation')
  @UseGuards(AuthGuard('jwt'), new RolesGuard(['admin']))
  async updateEvaluationSettings(@Body() dto: UpdateEvaluationDto) {
    const settings = (await this.settingsModel.findOne()) ?? new this.settingsModel();
    
    // --- Defense Board Criteria ---
    settings.criteria1Name = dto.criteria1Name;
    settings.criteria1Max = dto.criteria1Max;
    settings.criteria2Name = dto.criteria2Name;
    settings.criteria2Max = dto.criteria2Max;

    // --- Supervisor Own Team Criteria (ADDED) ---
    settings.ownTeamCriteria1Name = dto.ownTeamCriteria1Name;
    settings.ownTeamCriteria1Max = dto.ownTeamCriteria1Max;
    settings.ownTeamCriteria2Name = dto.ownTeamCriteria2Name;
    settings.ownTeamCriteria2Max = dto.ownTeamCriteria2Max;
    
    return settings.save();
  }
}