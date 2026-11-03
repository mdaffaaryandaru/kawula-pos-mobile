// Project imports:
import 'package:kawula_pos/features/membership_programs/domain/entities/membership_program.dart';

abstract interface class MembershipProgramsRepository {
  Future<MembershipProgram> getCurrentProgram();

  Future<MembershipProgram> updateCurrentProgram({
    required int targetVisits,
    required String rewardType,
    required String? rewardId,
    required bool isActive,
  });
}
