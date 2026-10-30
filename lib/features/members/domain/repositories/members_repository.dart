import '../entities/member.dart';
import '../entities/membership_program.dart';

abstract interface class MembersRepository {
  Future<List<Member>> getMembers();

  Future<MembershipProgram> getMembershipProgram();

  Future<MembershipProgram> saveMembershipProgram({
    required int targetVisits,
    required String rewardType,
    required String? rewardId,
    required bool isActive,
  });

  Future<Member> createMember({
    required String name,
    required String phoneNumber,
    required String email,
  });

  Future<Member> updateMember({
    required String memberId,
    required String name,
    required String phoneNumber,
    required String email,
    required bool isActive,
  });

  Future<void> deleteMember(String memberId);
}
