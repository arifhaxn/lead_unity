/* eslint-disable prettier/prettier */
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type AppSettingsDocument = AppSettings & Document;

@Schema()
export class AppSettings {
  @Prop({ type: Boolean, default: false })
  isStudentRegistrationOpen!: boolean;

  // New Fields for Evaluation
  @Prop({ default: 'Criteria 1' })
  criteria1Name!: string;

  @Prop({ default: 30 })
  criteria1Max!: number;

  @Prop({ default: 'Criteria 2' })
  criteria2Name!: string;

  @Prop({ default: 30 })
  criteria2Max!: number;

    // NEW FIELD
  @Prop({ type: Boolean, default: true }) 
  isSubmissionOpen!: boolean;

  // --- NEW: Supervisor's Own Team Criteria ---
  @Prop({ default: 'Project Implementation' })
  ownTeamCriteria1Name!: string;
  @Prop({ default: 40 })
  ownTeamCriteria1Max!: number;
  @Prop({ default: 'Continuous Assessment' })
  ownTeamCriteria2Name!: string;
  @Prop({ default: 40 })
  ownTeamCriteria2Max!: number;
}

export const AppSettingsSchema = SchemaFactory.createForClass(AppSettings);
