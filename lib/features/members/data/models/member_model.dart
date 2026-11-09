// Project imports:
import 'package:kawula_pos/features/members/domain/entities/member.dart';

class MemberModel extends Member {
  const MemberModel({
    required super.id,
    required super.name,
    required super.phoneNumber,
    required super.currentStamps,
    required super.isActive,
    super.email,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? json['id'];
    final name = json['name'];
    final phoneNumber = json['phone_number'];
    final currentStamps = json['current_stamps'];
    final isActive = json['is_active'];
    final email = json['email'];
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
      email: email is String ? email : '',
    );
  }

  factory MemberModel.fromEntity(Member member) => MemberModel(
    id: member.id,
    name: member.name,
    phoneNumber: member.phoneNumber,
    currentStamps: member.currentStamps,
    isActive: member.isActive,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'phone_number': phoneNumber,
    'current_stamps': currentStamps,
    'is_active': isActive,
  };
}
