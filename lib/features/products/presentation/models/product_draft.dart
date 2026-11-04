// Dart imports:
import 'dart:typed_data';

// Package imports:
import 'package:image_picker/image_picker.dart';

class ProductDraft {
  const ProductDraft({
    required this.name,
    required this.price,
    required this.stock,
    required this.categoryId,
    required this.discountId,
    required this.variantGroupIds,
    required this.images,
    required this.isActive,
  });

  final String name;
  final num price;
  final num stock;
  final String categoryId;
  final String? discountId;
  final List<String> variantGroupIds;
  final List<ProductImageDraft> images;
  final bool isActive;
}

class ProductImageDraft {
  ProductImageDraft({this.url, this.file, this.bytes, required this.isMain});

  final String? url;
  final XFile? file;
  final Uint8List? bytes;
  bool isMain;
}
