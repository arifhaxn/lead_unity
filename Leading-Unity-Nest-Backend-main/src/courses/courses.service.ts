/* eslint-disable prettier/prettier */
import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Course, CourseDocument } from './schemas/course.schema';
import { CreateCourseDto } from './dto/create-course.dto';
import { UpdateCourseDto } from './dto/update-course.dto';

@Injectable()
export class CoursesService {
  constructor(@InjectModel(Course.name) private courseModel: Model<CourseDocument>) {}

  async getAll() {
    return this.courseModel.find({});
  }

  async create(dto: CreateCourseDto) {
    const exists = await this.courseModel.findOne({ courseCode: dto.courseCode });
    if (exists) throw new BadRequestException('Course with this code already exists');
    
    const course = new this.courseModel(dto);
    return course.save();
  }

  async update(id: string, dto: UpdateCourseDto) {
    const course = await this.courseModel.findById(id);
    if (!course) throw new NotFoundException('Course not found');
    
    course.courseCode = dto.courseCode;
    course.courseTitle = dto.courseTitle;
    return course.save();
  }

  async delete(id: string) {
    const course = await this.courseModel.findByIdAndDelete(id);
    if (!course) throw new NotFoundException('Course not found');
    return { message: 'Course removed' };
  }
}