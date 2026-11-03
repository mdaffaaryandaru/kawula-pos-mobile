// Project imports:
import 'package:kawula_pos/features/outlets/data/datasources/outlets_remote_data_source.dart';
import 'package:kawula_pos/features/outlets/domain/entities/outlet.dart';
import 'package:kawula_pos/features/outlets/domain/repositories/outlets_repository.dart';

class OutletsRepositoryImpl implements OutletsRepository {
  const OutletsRepositoryImpl(this._remoteDataSource);

  final OutletsRemoteDataSource _remoteDataSource;

  @override
  Future<List<Outlet>> getOutlets() => _remoteDataSource.getOutlets();

  @override
  Future<Outlet> saveOutlet({
    String? outletId,
    required String name,
    required String code,
    required String address,
    required String phone,
    required bool isActive,
  }) {
    return _remoteDataSource.saveOutlet(
      outletId: outletId,
      name: name,
      code: code,
      address: address,
      phone: phone,
      isActive: isActive,
    );
  }

  @override
  Future<void> deleteOutlet(String outletId) =>
      _remoteDataSource.deleteOutlet(outletId);
}
