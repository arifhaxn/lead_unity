/* eslint-disable @typescript-eslint/no-unsafe-call */
/* eslint-disable @typescript-eslint/no-unsafe-return */
/* eslint-disable prettier/prettier */
import { Controller, Get, Post, Delete, Body, Param, UseGuards } from '@nestjs/common';
import { UsersService } from './users.service';
import { AuthGuard } from '@nestjs/passport';
import { RolesGuard } from '../common/guards/roles.guard';
import { CreateSupervisorDto } from './dto/create-supervisor.dto'; // Updated Import

@Controller('users')
@UseGuards(AuthGuard('jwt')) // Protect all routes
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  getAllUsers() {
    return this.usersService.getAllUsers();
  }

  // Updated DTO
  @Post('supervisor')
  createSupervisor(@Body() dto: CreateSupervisorDto) {
    return this.usersService.createSupervisor(dto);
  }

  @Delete(':id')
  @UseGuards(new RolesGuard(['admin']))
  deleteUser(@Param('id') id: string) {
    return this.usersService.deleteUser(id);
  }

  @Delete() 
  @UseGuards(new RolesGuard(['admin']))
  deleteAllUsers() {
    return this.usersService.deleteAllUsers();
  }
}