import '../../domain/entities/catalog_product.dart';

class CatalogCategoryModel extends ProductCategory {
  const CatalogCategoryModel({
    required super.id,
    required super.name,
    required super.isActive,
  });

  factory CatalogCategoryModel.fromJson(Map<String, dynamic> json) {
    return CatalogCategoryModel(
      id: _categoryStringValue(json['_id'] ?? json['id'], 'kategori ID'),
      name: _categoryStringValue(json['name'], 'nama kategori'),
      isActive: json['is_active'] != false,
    );
  }

  static String _categoryStringValue(Object? value, String field) {
    if (value is String) return value;
    throw FormatException('Data katalog tidak memiliki $field yang valid.');
  }
}

class CatalogProductModel extends CatalogProduct {
  const CatalogProductModel({
    required super.id,
    required super.name,
    required super.price,
    required super.imageUrl,
    required super.isActive,
    required super.category,
    required super.variantGroups,
    super.images,
    super.stock,
    super.discount,
    super.discountId,
  });

  factory CatalogProductModel.fromJson(Map<String, dynamic> json) {
    final categoryJson = json['category_id'];
    final discountJson = json['discount_id'];
    final variantJson = json['variant_groups'];

    return CatalogProductModel(
      id: _stringValue(json['_id'] ?? json['id'], 'produk ID'),
      name: _stringValue(json['name'], 'nama produk'),
      price: _numberValue(json['price'], 'harga produk'),
      imageUrl: _optionalString(json['image_url']) ?? '',
      isActive: json['is_active'] != false,
      discountId: discountJson is String
          ? discountJson
          : discountJson is Map<String, dynamic>
          ? _optionalString(discountJson['_id'] ?? discountJson['id'])
          : null,
      category: categoryJson is Map<String, dynamic>
          ? CatalogCategoryModel.fromJson(categoryJson)
          : null,
      discount: discountJson is Map<String, dynamic>
          ? _parseDiscount(discountJson)
          : null,
      variantGroups: variantJson is List
          ? variantJson
                .whereType<Map<String, dynamic>>()
                .map(_parseVariantGroup)
                .toList()
          : const [],
      images: json['images'] is List
          ? (json['images'] as List)
                .whereType<Map<String, dynamic>>()
                .map((image) {
                  final url = image['url'];
                  if (url is! String) {
                    throw const FormatException(
                      'Data gambar produk tidak valid.',
                    );
                  }
                  return ProductImage(
                    url: url,
                    isMain: image['is_main'] == true,
                  );
                })
                .toList(growable: false)
          : const [],
      stock: json['stock'] is num ? json['stock'] as num : null,
    );
  }

  static ProductDiscount _parseDiscount(Map<String, dynamic> json) {
    return ProductDiscount(
      type: _stringValue(json['type'], 'jenis diskon'),
      value: _numberValue(json['value'], 'nilai diskon'),
    );
  }

  static ProductVariantGroup _parseVariantGroup(Map<String, dynamic> json) {
    final options = json['options'];
    return ProductVariantGroup(
      name: _stringValue(json['name'], 'nama grup varian'),
      isRequired: json['is_required'] == true,
      minSelection: _integerValue(json['min_selection'], 0),
      maxSelection: _integerValue(json['max_selection'], 1),
      options: options is List
          ? options
                .whereType<Map<String, dynamic>>()
                .map(_parseVariantOption)
                .toList()
          : const [],
    );
  }

  static ProductVariantOption _parseVariantOption(Map<String, dynamic> json) {
    return ProductVariantOption(
      id: _optionalString(json['_id'] ?? json['id']),
      name: _stringValue(json['name'], 'nama opsi varian'),
      priceAdjustment: _numberValue(
        json['price_adjustment'] ?? 0,
        'tambahan harga',
      ),
    );
  }

  static String _stringValue(Object? value, String field) {
    if (value is String) return value;
    throw FormatException('Data katalog tidak memiliki $field yang valid.');
  }

  static String? _optionalString(Object? value) {
    return value is String ? value : null;
  }

  static num _numberValue(Object? value, String field) {
    if (value is num) return value;
    throw FormatException('Data katalog tidak memiliki $field yang valid.');
  }

  static int _integerValue(Object? value, int fallback) {
    return value is num ? value.toInt() : fallback;
  }
}
