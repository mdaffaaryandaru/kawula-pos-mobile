enum DiscountType {
  percentage('percentage'),
  nominal('nominal');

  const DiscountType(this.apiValue);

  final String apiValue;

  String get label => switch (this) {
    DiscountType.percentage => 'Persentase',
    DiscountType.nominal => 'Nominal',
  };

  static DiscountType fromApiValue(String value) => switch (value) {
    'percentage' => DiscountType.percentage,
    'nominal' => DiscountType.nominal,
    _ => throw FormatException('Tipe diskon tidak valid: $value.'),
  };
}

class DiscountDefinition {
  const DiscountDefinition({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.description,
    required this.isActive,
  });

  final String id;
  final String name;
  final DiscountType type;
  final num value;
  final String description;
  final bool isActive;
}
