/* eslint-disable prettier/prettier */
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Schema as MongooseSchema } from 'mongoose';

@Schema()
export class StudentMark {
  @Prop({ required: true })
  studentId!: string;

  @Prop({ default: 0 })
  criteria1!: number;

  @Prop({ default: 0 })
  criteria2!: number;

  @Prop({ default: false })
  isAbsent!: boolean;

  @Prop({ required: true })
  supervisorId!: string; 

  @Prop({ required: true, enum: ['own', 'defense'] })
  type!: string; 
}

export const StudentMarkSchema = SchemaFactory.createForClass(StudentMark);

export type ProposalDocument = Proposal & Document;

@Schema({ timestamps: true })
export class Proposal {
  @Prop({ required: true })
  title!: string;

  @Prop({ required: true })
  description!: string;

  // Student Leader -> Points to 'User' (Correct)
  @Prop({ type: MongooseSchema.Types.ObjectId, ref: 'User', required: true })
  student!: any;

  // Preferred Supervisors -> Points to 'Supervisor' (UPDATED)
  @Prop({ type: [{ type: MongooseSchema.Types.ObjectId, ref: 'Supervisor' }], default: [] })
  supervisors!: any[];

  // Assigned Supervisor -> Points to 'Supervisor' (UPDATED)
  @Prop({ type: MongooseSchema.Types.ObjectId, ref: 'Supervisor', default: null })
  assignedSupervisor: any; 

  @Prop({ type: MongooseSchema.Types.ObjectId, ref: 'Course', required: true })
  course: any;

  @Prop({ default: [] })
  teamMembers: any[] = [];

  @Prop({ required: true, enum: ['approved', 'rejected'], default: 'approved' })
  status!: string;

  @Prop({ type: [StudentMarkSchema], default: [] })
  marks: StudentMark[] = [];

  @Prop({ type: Date, default: null })
  defenseDate!: Date;
}

export const ProposalSchema = SchemaFactory.createForClass(Proposal);