import '../../domain/entities/member_reward_claim.dart';
import 'member_model.dart';

class MemberRewardClaimModel extends MemberRewardClaim {
  const MemberRewardClaimModel({
    required super.member,
    required super.rewardType,
    required super.rewardName,
  });

  factory MemberRewardClaimModel.fromJson(Map<String, dynamic> json) {
    final memberJson = json['member'];
    final rewardJson = json['reward'];
    if (memberJson is! Map<String, dynamic> ||
        rewardJson is! Map<String, dynamic> ||
        rewardJson['type'] is! String) {
      throw const FormatException('Respons klaim reward member tidak valid.');
    }

    final rewardType = rewardJson['type'] as String;
    final rewardData = rewardType == 'discount'
        ? rewardJson['discount']
        : rewardJson['product'];
    return MemberRewardClaimModel(
      member: MemberModel.fromJson(memberJson),
      rewardType: rewardType,
      rewardName: _rewardName(rewardData, rewardType),
    );
  }

  static String _rewardName(Object? value, String rewardType) {
    if (value is Map<String, dynamic> && value['name'] is String) {
      return value['name'] as String;
    }
    if (value is String && value.isNotEmpty) return value;
    return rewardType == 'discount' ? 'Diskon' : 'Produk gratis';
  }
}
