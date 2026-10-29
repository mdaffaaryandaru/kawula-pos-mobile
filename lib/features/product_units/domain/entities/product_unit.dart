class ProductUnit {
  const ProductUnit({
    required this.id,
    required this.name,
    required this.abbreviation,
    this.isActive = true,
    this.description = '',
  });

  final String id;
  final String name;
  final String abbreviation;
  final bool isActive;
  final String description;

  String get label => '$name (${abbreviation.toLowerCase()})';
}
