/* eslint-disable @typescript-eslint/no-unused-vars */
/* eslint-disable prettier/prettier */

import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';

import { Supervisor, SupervisorDocument } from './schemas/supervisor.schema';
import { CreateSupervisorDto } from './dto/create-supervisor.dto';
import { User, UserDocument } from './schemas/student.schema';

@Injectable()
export class UsersService {
  constructor(
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    @InjectModel(Supervisor.name) private supervisorModel: Model<SupervisorDocument>,
  ) {}

  // 1. Create Supervisor (Strict Schema)
  async createSupervisor(dto: CreateSupervisorDto): Promise<Omit<Supervisor & { _id: any }, 'password'>> {
    // Check duplication by Abbreviation
    const exists = await this.supervisorModel.findOne({ abbreviation: dto.abbreviation });
    if (exists) throw new BadRequestException('Supervisor with this abbreviation already exists');

    const user = await this.supervisorModel.create({ ...dto, role: 'supervisor' });
    return this.sanitizeResponse(user);
  }

  // 2. Get All Users (Merge Students + Supervisors for Admin List)
  async getAllUsers() {
    const students = await this.userModel.find(); // All students
    const supervisors = await this.supervisorModel.find(); // All supervisors
    
    // Merge arrays
    return [...students, ...supervisors];
  }

  // 3. Delete User (Check both collections)
  async deleteUser(id: string) {
    // Try deleting Student first
    let deleted = await this.userModel.findByIdAndDelete(id);
    
    // If not found, try deleting Supervisor
    if (!deleted) {
      deleted = await this.supervisorModel.findByIdAndDelete(id);
    }

    if (!deleted) throw new NotFoundException('User not found');
    
    return { message: 'User removed successfully' };
  }

  // 4. Delete All (Danger Zone - Deletes Students and Supervisors)
  // Admins are in a separate collection/logic now, so they are safe.
  async deleteAllUsers() {
    await this.userModel.deleteMany({});
    await this.supervisorModel.deleteMany({});
    return { message: 'All students and supervisors deleted' };
  }

  // Helper to remove password
  private sanitizeResponse<T extends { toObject: () => any }>(doc: T): Omit<ReturnType<T['toObject']>, 'password'> {
    const obj = doc.toObject() as { [key: string]: any };
    delete obj.password;
    return obj as Omit<ReturnType<T['toObject']>, 'password'>;
  }
}