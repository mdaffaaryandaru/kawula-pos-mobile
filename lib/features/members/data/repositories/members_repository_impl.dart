// Project imports:
import 'package:kawula_pos/features/members/data/datasources/members_remote_data_source.dart';
import 'package:kawula_pos/features/members/domain/entities/member.dart';
import 'package:kawula_pos/features/members/domain/entities/member_reward_claim.dart';
import 'package:kawula_pos/features/members/domain/repositories/members_repository.dart';

class MembersRepositoryImpl implements MembersRepository {
  const MembersRepositoryImpl(this._remoteDataSource);

  final MembersRemoteDataSource _remoteDataSource;

  @override
  Future<List<Member>> getMembers() => _remoteDataSource.getMembers();

  @override
  Future<MemberRewardClaim> claimReward(String memberId) =>
      _remoteDataSource.claimReward(memberId);

  @override
  Future<Member> createMember({
    required String name,
    required String phoneNumber,
    required String email,
  }) {
    return _remoteDataSource.createMember(
      name: name,
      phoneNumber: phoneNumber,
      email: email,
    );
  }

  @override
  Future<Member> updateMember({
    required String memberId,
    required String name,
    required String phoneNumber,
    required String email,
    required bool isActive,
  }) {
    return _remoteDataSource.updateMember(
      memberId: memberId,
      name: name,
      phoneNumber: phoneNumber,
      email: email,
      isActive: isActive,
    );
  }

  @override
  Future<void> deleteMember(String memberId) =>
      _remoteDataSource.deleteMember(memberId);
}
