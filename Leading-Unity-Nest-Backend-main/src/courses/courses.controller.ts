/* eslint-disable prettier/prettier */
import { Controller, Get, Post, Put, Delete, Body, Param, UseGuards } from '@nestjs/common';
import { CoursesService } from './courses.service';
import { CreateCourseDto } from './dto/create-course.dto';
import { UpdateCourseDto } from './dto/update-course.dto';
import { RolesGuard } from 'src/common/guards/roles.guard';
import { AuthGuard } from '@nestjs/passport'; // <--- IMPORT THIS

@Controller('courses')
export class CoursesController {
  constructor(private readonly coursesService: CoursesService) {}

  @Get()
  getAll() {
    return this.coursesService.getAll();
  }

  // 👇 ADD AuthGuard('jwt') HERE
  @UseGuards(AuthGuard('jwt'), new RolesGuard(['admin']))
  @Post()
  create(@Body() dto: CreateCourseDto) {
    return this.coursesService.create(dto);
  }

  // 👇 ADD AuthGuard('jwt') HERE
  @UseGuards(AuthGuard('jwt'), new RolesGuard(['admin']))
  @Put(':id')
  update(@Param('id') id: string, @Body() dto: UpdateCourseDto) {
    return this.coursesService.update(id, dto);
  }

  // 👇 ADD AuthGuard('jwt') HERE
  @UseGuards(AuthGuard('jwt'), new RolesGuard(['admin']))
  @Delete(':id')
  delete(@Param('id') id: string) {
    return this.coursesService.delete(id);
  }
}