import '../../domain/entities/membership_program.dart';
import '../../domain/repositories/membership_programs_repository.dart';
import '../datasources/membership_programs_remote_data_source.dart';

class MembershipProgramsRepositoryImpl
    implements MembershipProgramsRepository {
  const MembershipProgramsRepositoryImpl(this._remoteDataSource);

  final MembershipProgramsRemoteDataSource _remoteDataSource;

  @override
  Future<MembershipProgram> getCurrentProgram() =>
      _remoteDataSource.getCurrentProgram();

  @override
  Future<MembershipProgram> updateCurrentProgram({
    required int targetVisits,
    required String rewardType,
    required String? rewardId,
    required bool isActive,
  }) {
    return _remoteDataSource.updateCurrentProgram(
      targetVisits: targetVisits,
      rewardType: rewardType,
      rewardId: rewardId,
      isActive: isActive,
    );
  }
}
