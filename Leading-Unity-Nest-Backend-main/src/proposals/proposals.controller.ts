/* eslint-disable prettier/prettier */
import { Controller, Get, Post, Put, Body, UseGuards, Param, Delete } from '@nestjs/common';
import { ProposalsService } from './proposals.service';
import { AuthGuard } from '@nestjs/passport';
import { RolesGuard } from '../common/guards/roles.guard';
import { GetUser } from '../common/decorators/get-user.decorator';
import { CreateProposalDto } from './dto/create-proposal.dto';
import type { UserDocument } from 'src/users/schemas/student.schema';
import type { SupervisorDocument } from 'src/users/schemas/supervisor.schema';
import { SaveMarkDto } from './dto/save-marks.dto';


@Controller('proposals')
@UseGuards(AuthGuard('jwt'))
export class ProposalsController {
  constructor(private readonly proposalsService: ProposalsService) {}

  @Post()
  createProposal(@Body() dto: CreateProposalDto, @GetUser() user: UserDocument) {
    return this.proposalsService.create(dto, user);
  }

  @Get()
  @UseGuards(new RolesGuard(['admin','supervisor']))
  getAllProposals() {
    return this.proposalsService.getAll();
  }

  @Get('my')
getMyProposals(@GetUser() user: UserDocument) {
  return this.proposalsService.getMyProposals(user._id.toString());
}


  @Put(':id')
  @UseGuards(new RolesGuard(['admin']))
  updateStatus(@Param('id') id: string, @Body('status') status: string) {
    return this.proposalsService.updateStatus(id, status);
  }


  @Post(':id/marks')
  @UseGuards(new RolesGuard(['supervisor']))
  saveMarks(
    @Param('id') id: string,
    @GetUser() user: UserDocument | SupervisorDocument,
    // ✅ CORRECT: Accept the whole body object
    @Body() body: { marks: SaveMarkDto[], type: 'own' | 'defense' } 
  ) {
    // Optionally Validate body.marks manually if needed, or trust strict types.
    return this.proposalsService.saveMarks(id, user._id.toString(), body.marks, body.type);
  }


   @Put(':id/assign-supervisor')
  @UseGuards(new RolesGuard(['admin']))
  assignSupervisor(
    @Param('id') id: string,
    @Body('supervisorId') supervisorId: string, // Expects { supervisorId: "..." }
  ) {
    return this.proposalsService.assignSupervisor(id, supervisorId);
  }



  @Put(':id/defense-date')
  @UseGuards(new RolesGuard(['admin']))
  setDefenseDate(
    @Param('id') id: string,
    @Body('date') date: string,
    @Body('endDate') endDate: string, // Accept End Date
  ) {
    return this.proposalsService.setDefenseDate(id, new Date(date), new Date(endDate));
  }


  // ... inside ProposalsController class
  @Delete() // DELETE /api/proposals
  @UseGuards(new RolesGuard(['admin']))
  deleteAllProposals() {
    return this.proposalsService.deleteAll();
  }
}
