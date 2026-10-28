import '../../domain/entities/member.dart';

class MemberModel extends Member {
  const MemberModel({
    required super.id,
    required super.name,
    required super.phoneNumber,
    required super.currentStamps,
    required super.isActive,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? json['id'];
    final name = json['name'];
    final phoneNumber = json['phone_number'];
    final currentStamps = json['current_stamps'];
    final isActive = json['is_active'];
    if (id is! String ||
        name is! String ||
        phoneNumber is! String ||
        currentStamps is! num ||
        isActive is! bool) {
      throw const FormatException('Data member dari server tidak valid.');
    }
    return MemberModel(
      id: id,
      name: name,
      phoneNumber: phoneNumber,
      currentStamps: currentStamps.toInt(),
      isActive: isActive,
    );
  }
}
