import { ExtractJwt, Strategy } from 'passport-jwt';
import { PassportStrategy } from '@nestjs/passport';
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';

// Corrected Imports (Using relative paths)
// Changed from student.schema if you renamed it, otherwise keep student.schema

import { Admin, AdminDocument } from '../users/schemas/admin.schema';
import { Supervisor, SupervisorDocument } from 'src/users/schemas/supervisor.schema';
import { User, UserDocument } from 'src/users/schemas/student.schema';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    @InjectModel(Supervisor.name) private supervisorModel: Model<SupervisorDocument>,
    @InjectModel(Admin.name) private adminModel: Model<AdminDocument>,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKey: process.env.JWT_SECRET || 'secret',
    });
  }

  async validate(payload: { id: string }): Promise<UserDocument | SupervisorDocument | AdminDocument> {
    // 1. Check Student
    let user: UserDocument | SupervisorDocument | AdminDocument | null = await this.userModel.findById(payload.id);
    
    // 2. Check Supervisor
    if (!user) {
      user = await this.supervisorModel.findById(payload.id);
    }

    // 3. Check Admin
    if (!user) {
      user = await this.adminModel.findById(payload.id);
    }

    if (!user) throw new UnauthorizedException('Token invalid');
    
    return user; 
  }
}