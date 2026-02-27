/* eslint-disable prettier/prettier */
import {
  Injectable,
  UnauthorizedException,
  BadRequestException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import * as nodemailer from 'nodemailer';
import { Transporter } from 'nodemailer';

// Schemas // Changed 'student.schema' back to 'user.schema' as per standard naming
import { Supervisor, SupervisorDocument } from '../users/schemas/supervisor.schema';
import { Admin, AdminDocument } from '../users/schemas/admin.schema';
import { AppSettings, AppSettingsDocument } from '../settings/schemas/app-settings.schema';
import { Otp, OtpDocument } from './schemas/otp.schema';

// DTOs
import { RegisterStudentDto } from './dto/register-student.dto';
import { LoginDto } from './dto/login.dto';
import { RegisterAdminDto } from './dto/register-admin.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { User, UserDocument } from 'src/users/schemas/student.schema';

// Define Interface for BuildResponse
// This covers fields from all 3 schemas (Admin, Student, Supervisor)
interface UserLike {
  _id: any;
  name: string;
  password?: string;
  email?: string;
  studentId?: string;
  abbreviation?: string;
  designation?: string;
  batch?: string;
  section?: string;
  role?: string;
}

@Injectable()
export class AuthService {
  private transporter: Transporter;

  constructor(
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    @InjectModel(Supervisor.name) private supervisorModel: Model<SupervisorDocument>,
    @InjectModel(Admin.name) private adminModel: Model<AdminDocument>,
    @InjectModel(AppSettings.name) private settingsModel: Model<AppSettingsDocument>,
    @InjectModel(Otp.name) private otpModel: Model<OtpDocument>,
    private jwtService: JwtService,
  ) {
    this.transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: process.env.MAIL_USER,
        pass: process.env.MAIL_PASS,
      },
    });
  }

  // --- 1. LOGIN ---
  async login(loginDto: LoginDto) {
    const { identifier, password } = loginDto;
    console.log('Login attempt for:', identifier);

    let user: any = null;
    let role = '';

    const isEmail = identifier.includes('@');

    if (isEmail) {
      // 1. Check Admin (Priority)
      user = await this.adminModel.findOne({ email: identifier }).select('+password');
      if (user) {
        role = 'admin';
      } else {
        // 2. Check Student
        user = await this.userModel.findOne({ email: identifier }).select('+password');
        if (user) role = 'student';
      }
    } else {
      // 3. Check Student (by ID)
      user = await this.userModel.findOne({ studentId: identifier }).select('+password');
      if (user) {
        role = 'student';
      } else {
        // 4. Check Supervisor (by Abbreviation)
        user = await this.supervisorModel.findOne({ abbreviation: identifier }); 
        if (user) role = 'supervisor';
      }
    }

    if (!user) throw new UnauthorizedException('Invalid Credentials');

    // Password Check
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) throw new UnauthorizedException('Invalid Credentials');

    return this.buildResponse(user, role);
  }

  // --- 2. SEND OTP ---
  async sendRegistrationOtp(email: string) {
    const settings = await this.settingsModel.findOne();
    if (!settings || !settings.isStudentRegistrationOpen) {
      throw new BadRequestException('Student registration is currently closed.');
    }

    // Check duplication in Student & Admin
    const userExists = await this.userModel.findOne({ email });
    const adminExists = await this.adminModel.findOne({ email });
    
    if (userExists || adminExists) throw new BadRequestException('User with this email already exists');

    const otpCode = Math.floor(100000 + Math.random() * 900000).toString();

    await this.otpModel.findOneAndUpdate(
      { email },
      { email, otp: otpCode },
      { upsert: true, new: true }
    );

    try {
      await this.transporter.sendMail({
        from: '"LeadUnity Admin" <no-reply@leadunity.com>',
        to: email,
        subject: 'Your Verification Code',
        text: `Your verification code is: ${otpCode}`,
        html: `<b>Your verification code is: ${otpCode}</b><br>Expires in 5 minutes.`,
      });
      return { message: 'OTP sent successfully' };
    } catch (error) {
      console.error('Email error:', error);
      throw new BadRequestException('Failed to send email.');
    }
  }

  // --- 3. REGISTER STUDENT ---
  async registerStudent(dto: RegisterStudentDto) {
    // Verify OTP
    const validOtp = await this.otpModel.findOne({ email: dto.email, otp: dto.otp });
    if (!validOtp) throw new BadRequestException('Invalid or expired OTP');

    // Check Settings
    const settings = await this.settingsModel.findOne();
    if (!settings || !settings.isStudentRegistrationOpen) {
      throw new BadRequestException('Student registration is currently closed.');
    }

    // Check Duplicates (Email OR ID)
    const emailExists = await this.userModel.findOne({ email: dto.email });
    const idExists = await this.userModel.findOne({ studentId: dto.studentId });
    
    if (emailExists) throw new BadRequestException('Email already registered.');
    if (idExists) throw new BadRequestException('Student ID already registered.');

    // Create User
    const user = await this.userModel.create({
      ...dto,
      role: 'student',
    });

    // Cleanup OTP
    await this.otpModel.deleteOne({ _id: validOtp._id });

    return this.buildResponse(user, 'student');
  }

  // --- 4. REGISTER ADMIN ---
  async registerAdmin(dto: RegisterAdminDto) {
    const adminExists = await this.adminModel.findOne({ email: dto.email });
    if (adminExists) throw new BadRequestException('Admin already exists.');

    const user = await this.adminModel.create({ ...dto, role: 'admin' });
    return this.buildResponse(user, 'admin');
  }

  // --- 5. CHANGE PASSWORD ---
  async changePassword(dto: ChangePasswordDto) {
    const identifier = dto.email; // Reuse DTO field
    const isEmail = identifier.includes('@');
    
    let user: any = null;

    if (isEmail) {
       // Check Admin
       user = await this.adminModel.findOne({ email: identifier }).select('+password');
       // If not Admin, check Student
       if (!user) user = await this.userModel.findOne({ email: identifier }).select('+password');
    } else {
       // Check Supervisor (Abbreviation)
       user = await this.supervisorModel.findOne({ abbreviation: identifier });
    }

    if (!user) throw new BadRequestException('User not found');

    const isMatch = await bcrypt.compare(dto.oldPassword, user.password);
    if (!isMatch) throw new BadRequestException('Invalid temporary/old password');

    user.password = dto.newPassword; 
    await user.save();

    return { message: 'Password updated successfully' };
  }

  // --- Helpers ---
  private generateToken(id: string) {
    return this.jwtService.sign({ id });
  }

  private buildResponse(user: UserLike, role: string) {
    return {
      _id: user._id,
      name: user.name,
      role: role,
      token: this.generateToken(user._id.toString()),
      
      // Conditional Fields (Only include if they exist)
      ...(user.email && { email: user.email }),
      ...(user.studentId && { studentId: user.studentId }),
      ...(user.abbreviation && { abbreviation: user.abbreviation }),
      ...(user.designation && { designation: user.designation }),
      ...(user.batch && { batch: user.batch }),
      ...(user.section && { section: user.section }),
    };
  }
}