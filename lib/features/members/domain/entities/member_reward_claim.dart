import 'member.dart';

class MemberRewardClaim {
  const MemberRewardClaim({
    required this.member,
    required this.rewardType,
    required this.rewardName,
  });

  final Member member;
  final String rewardType;
  final String rewardName;
}
