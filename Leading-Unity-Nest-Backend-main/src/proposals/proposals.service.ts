/* eslint-disable prettier/prettier */
import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Proposal, ProposalDocument, StudentMark } from './schemas/proposal.schema';
import { User, UserDocument } from '../users/schemas/student.schema';
import { CreateProposalDto } from './dto/create-proposal.dto';
import { SaveMarkDto } from './dto/save-marks.dto'; // Ensure this DTO exists
import { AppSettings, AppSettingsDocument } from 'src/settings/schemas/app-settings.schema';

@Injectable()
export class ProposalsService {
  constructor(
    @InjectModel(Proposal.name) private proposalModel: Model<ProposalDocument>,
    @InjectModel(User.name) private userModel: Model<UserDocument>,
      @InjectModel(AppSettings.name) private settingsModel: Model<AppSettingsDocument>,
  ) {}

// ... imports

  async create(dto: CreateProposalDto, leaderUser: UserDocument): Promise<Proposal> {
    const { title, description, supervisorIds, courseId, teamMembers } = dto;
    const leaderStudentId = leaderUser.studentId;

    const memberStudentIds: string[] = teamMembers ? teamMembers.map((m) => m.studentId) : [];
    const allInvolvedStudentIds: string[] = leaderStudentId ? [leaderStudentId, ...memberStudentIds] : [...memberStudentIds];
    const uniqueIdsToCheck: string[] = [...new Set(allInvolvedStudentIds.filter((id) => id))];

    // --- 1. Check if members are already in a team FOR THIS COURSE ---
    const existingMemberConflict = await this.proposalModel.findOne({
      course: courseId, // <--- Add Course Filter Here
      'teamMembers.studentId': { $in: uniqueIdsToCheck },
      status: { $ne: 'rejected' },
    });

     // 1. Check if submissions are open
    const settings = await this.settingsModel.findOne();
    if (settings && !settings.isSubmissionOpen) {
       throw new BadRequestException('Project submissions are currently closed.');
    }

    if (existingMemberConflict) {
      throw new BadRequestException('One or more students are already in a team for this course.');
    }

    // --- 2. Check if Leader is already a Leader FOR THIS COURSE ---
    // Note: We need to find User Object IDs first because 'student' field is a Ref
    const users = await this.userModel.find({ studentId: { $in: uniqueIdsToCheck } });
    const userObjectIds = users.map((user) => user._id);

    const existingLeaderConflict = await this.proposalModel.findOne({
      course: courseId, // <--- Add Course Filter Here
      student: { $in: userObjectIds },
      status: { $ne: 'rejected' },
    });

    if (existingLeaderConflict) {
      throw new BadRequestException('One or more students (or leader) are already leading a team for this course.');
    }

    // --- Create ---
    const proposal = new this.proposalModel({
      title,
      description,
      student: leaderUser._id,
      supervisors: supervisorIds,
      course: courseId,
      teamMembers: teamMembers || [],
    });

    return proposal.save();
  }

  async assignSupervisor(proposalId: string, supervisorId: string): Promise<Proposal> {
    const proposal = await this.proposalModel.findById(proposalId);
    if (!proposal) throw new NotFoundException('Proposal not found');
    
    proposal.assignedSupervisor = supervisorId; // <--- Is this line executing?
    return proposal.save(); // <--- Is this actually saving to MongoDB?
  }

  async getAll(): Promise<Proposal[]> {
    return this.proposalModel
      .find({})
      .populate('student', 'name studentId email')
      .populate('supervisors', 'name email')
      .populate('assignedSupervisor', 'name email')
      .populate('course', 'courseCode courseTitle')
      .sort({ createdAt: -1 })
      .exec();
  }

  async updateStatus(id: string, status: string): Promise<Proposal> {
    const proposal = await this.proposalModel.findById(id);
    if (!proposal) throw new NotFoundException('Proposal not found');
    
    proposal.status = status;
    return proposal.save();
  }

  async getMyProposals(userId: string): Promise<Proposal[]> {
    return this.proposalModel
      .find({ student: userId })
      .populate('course', 'courseCode courseTitle')
      .exec();
  }

  // --- Strict Typing Implementation ---
  async saveMarks(
    proposalId: string, 
    supervisorId: string, 
    marksData: SaveMarkDto[], // Strict input type
    type: 'own' | 'defense'   // Strict string literal type
  ): Promise<Proposal> {
    const proposal = await this.proposalModel.findById(proposalId);
    if (!proposal) throw new NotFoundException('Proposal not found');

    // 1. Remove ANY previous marks made by THIS supervisor (regardless of type, to avoid duplication/confusion)
    // proposal.marks is typed as StudentMark[] in the schema
    const otherMarks = proposal.marks.filter((m) => m.supervisorId !== supervisorId);

    // 2. Transform the DTOs into the Schema format
    const newMarks: StudentMark[] = marksData.map((markDto) => ({
      studentId: markDto.studentId,
      criteria1: markDto.criteria1,
      criteria2: markDto.criteria2,
      isAbsent: markDto.isAbsent,
      supervisorId: supervisorId, // Injected from controller (JWT)
      type: type,                 // Injected from controller (Body)
    }));

    // 3. Save
    proposal.marks = [...otherMarks, ...newMarks];
    return proposal.save();
  }

  async deleteAll() {
    return this.proposalModel.deleteMany({});
  }

  

   async setDefenseDate(id: string, date: Date, endDate: Date) {
    const proposal = await this.proposalModel.findById(id);
    if (!proposal) throw new NotFoundException('Proposal not found');
    
    proposal.defenseDate = date;
    proposal.defenseEndDate = endDate; // Save End Time
    return proposal.save();
  }
}