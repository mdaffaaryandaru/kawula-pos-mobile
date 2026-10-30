import '../entities/outlet.dart';

abstract interface class OutletsRepository {
  Future<List<Outlet>> getOutlets();

  Future<Outlet> saveOutlet({
    String? outletId,
    required String name,
    required String code,
    required String address,
    required String phone,
    required bool isActive,
  });

  Future<void> deleteOutlet(String outletId);
}
