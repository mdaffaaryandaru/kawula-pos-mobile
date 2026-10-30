import '../../domain/entities/outlet.dart';

class OutletModel extends Outlet {
  const OutletModel({
    required super.id,
    required super.name,
    required super.code,
    required super.address,
    required super.phone,
    required super.isActive,
  });

  factory OutletModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? json['id'];
    final name = json['name'];
    final code = json['code'];
    if (id is! String || name is! String || code is! String) {
      throw const FormatException('Data outlet dari server tidak valid.');
    }
    return OutletModel(
      id: id,
      name: name,
      code: code,
      address: json['address'] is String ? json['address'] as String : '',
      phone: json['phone'] is String ? json['phone'] as String : '',
      isActive: json['is_active'] != false,
    );
  }
}
