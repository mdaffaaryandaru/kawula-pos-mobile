class Member {
  const Member({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.currentStamps,
    required this.isActive,
    this.email = '',
  });

  final String id;
  final String name;
  final String phoneNumber;
  final int currentStamps;
  final bool isActive;
  final String email;
}
