import '../../domain/entities/membership_program.dart';

class MembershipProgramModel extends MembershipProgram {
  const MembershipProgramModel({
    required super.targetVisits,
    required super.rewardType,
    required super.rewardId,
    required super.rewardName,
    required super.isActive,
  });

  factory MembershipProgramModel.fromJson(Map<String, dynamic> json) {
    final targetVisits = json['target_visits'];
    final rewardType = json['reward_type'];
    final rewardProduct = json['reward_product_id'];
    final rewardDiscount = json['reward_discount_id'];
    if (targetVisits is! num || rewardType is! String) {
      throw const FormatException(
        'Data program membership dari server tidak valid.',
      );
    }
    final rewardData = rewardType == 'discount'
        ? rewardDiscount
        : rewardProduct;
    final rewardName = _nameFrom(rewardData);
    final rewardId = _idFrom(rewardData);
    return MembershipProgramModel(
      targetVisits: targetVisits.toInt(),
      rewardType: rewardType,
      rewardId: rewardId,
      rewardName: rewardName,
      isActive: json['is_active'] == true,
    );
  }

  static String _nameFrom(Object? value) {
    if (value is Map<String, dynamic> && value['name'] is String) {
      return value['name'] as String;
    }
    return '';
  }

  static String? _idFrom(Object? value) {
    if (value is String) return value;
    if (value is Map<String, dynamic>) {
      final id = value['_id'] ?? value['id'];
      return id is String ? id : null;
    }
    return null;
  }
}
