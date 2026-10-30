class MembershipProgram {
  const MembershipProgram({
    required this.targetVisits,
    required this.rewardType,
    required this.rewardId,
    required this.rewardName,
    required this.isActive,
  });

  final int targetVisits;
  final String rewardType;
  final String? rewardId;
  final String rewardName;
  final bool isActive;

  String get displayName {
    if (!isActive) return 'Tidak aktif';
    final reward = rewardName.isNotEmpty
        ? rewardName
        : rewardType == 'discount'
        ? 'Diskon'
        : 'Produk gratis';
    return '$reward · $targetVisits kunjungan';
  }
}
