/* eslint-disable prettier/prettier */
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type CourseDocument = Course & Document;

@Schema({ timestamps: true })
export class Course {
  @Prop({ required: true, unique: true })
  courseCode: string;

  @Prop({ required: true })
  courseTitle: string;
}

export const CourseSchema = SchemaFactory.createForClass(Course);