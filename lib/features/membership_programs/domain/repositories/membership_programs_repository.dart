import '../entities/membership_program.dart';

abstract interface class MembershipProgramsRepository {
  Future<MembershipProgram> getCurrentProgram();

  Future<MembershipProgram> updateCurrentProgram({
    required int targetVisits,
    required String rewardType,
    required String? rewardId,
    required bool isActive,
  });
}
