class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.isActive,
  });

  final String id;
  final String name;
  final String code;
  final String description;
  final bool isActive;
}
