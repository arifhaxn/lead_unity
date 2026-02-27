import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';

import { Supervisor, SupervisorSchema } from './schemas/supervisor.schema';
import { Admin, AdminSchema } from './schemas/admin.schema';
import { User, UserSchema } from './schemas/student.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: User.name, schema: UserSchema },
      { name: Supervisor.name, schema: SupervisorSchema },
      { name: Admin.name, schema: AdminSchema },
    ]),
  ],
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService, MongooseModule], // 👈 CRITICAL: Export MongooseModule
})
export class UsersModule {}