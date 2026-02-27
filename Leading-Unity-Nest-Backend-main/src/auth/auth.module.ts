/* eslint-disable prettier/prettier */
import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport'; // <--- 1. Import this
import { MongooseModule } from '@nestjs/mongoose';
import { ConfigModule, ConfigService } from '@nestjs/config'; // <--- 2. Import this

import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtStrategy } from './jwt.strategy'; // <--- 3. Import your strategy
import { User, UserSchema } from 'src/users/schemas/student.schema';
import { AppSettings, AppSettingsSchema } from 'src/settings/schemas/app-settings.schema';
import { Otp, OtpSchema } from './schemas/otp.schema';
import { UsersModule } from 'src/users/users.module';

@Module({
  imports: [
     UsersModule,
    // 4. Initialize Passport
    PassportModule.register({ defaultStrategy: 'jwt' }), 

    MongooseModule.forFeature([
      { name: User.name, schema: UserSchema },
      { name: AppSettings.name, schema: AppSettingsSchema },
      { name: Otp.name, schema: OtpSchema }, // <--- REGISTER THIS
    ]),

    // 5. Use registerAsync to safely load JWT_SECRET from .env
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get<string>('JWT_SECRET'),
        signOptions: { expiresIn: '7d' },
      }),
    }),
  ],
  controllers: [AuthController],
  providers: [
    AuthService, 
    JwtStrategy // <--- 6. ESSENTIAL: Register the strategy here!
  ],
  exports: [AuthService, PassportModule],
})
export class AuthModule {}