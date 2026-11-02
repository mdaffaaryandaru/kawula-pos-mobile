import '../entities/member.dart';
import '../entities/member_reward_claim.dart';

abstract interface class MembersRepository {
  Future<List<Member>> getMembers();

  Future<MemberRewardClaim> claimReward(String memberId);

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
