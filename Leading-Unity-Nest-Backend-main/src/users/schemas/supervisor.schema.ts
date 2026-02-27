import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';
import * as bcrypt from 'bcryptjs';

export type SupervisorDocument = Supervisor & Document;

@Schema({ timestamps: true })
export class Supervisor {
  @Prop({ required: true })
  name: string;

  @Prop({ required: true, unique: true })
  abbreviation: string;

  @Prop({ required: true })
  designation: string;

  @Prop({ required: true })
  password: string;

  @Prop({ default: 'supervisor' })
  role: string;

  async matchPassword(enteredPassword: string): Promise<boolean> {
    return bcrypt.compare(enteredPassword, this.password);
  }
}

export const SupervisorSchema = SchemaFactory.createForClass(Supervisor);

SupervisorSchema.pre<SupervisorDocument>('save', async function () {
  if (!this.isModified('password')) return;
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
});