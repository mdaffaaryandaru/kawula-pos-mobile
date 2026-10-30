import '../../domain/entities/member.dart';
import '../../domain/entities/membership_program.dart';
import '../../domain/repositories/members_repository.dart';
import '../datasources/members_remote_data_source.dart';

class MembersRepositoryImpl implements MembersRepository {
  const MembersRepositoryImpl(this._remoteDataSource);

  final MembersRemoteDataSource _remoteDataSource;

  @override
  Future<List<Member>> getMembers() => _remoteDataSource.getMembers();

  @override
  Future<MembershipProgram> getMembershipProgram() =>
      _remoteDataSource.getMembershipProgram();

  @override
  Future<MembershipProgram> saveMembershipProgram({
    required int targetVisits,
    required String rewardType,
    required String? rewardId,
    required bool isActive,
  }) {
    return _remoteDataSource.saveMembershipProgram(
      targetVisits: targetVisits,
      rewardType: rewardType,
      rewardId: rewardId,
      isActive: isActive,
    );
  }

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
