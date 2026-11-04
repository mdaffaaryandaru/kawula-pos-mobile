// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Project imports:
import 'package:kawula_pos/features/categories/domain/entities/managed_category.dart';
import 'package:kawula_pos/features/discounts/domain/entities/discount_definition.dart';
import 'package:kawula_pos/features/products/domain/entities/catalog_product.dart';
import 'package:kawula_pos/features/products/domain/entities/product_management.dart';
import 'package:kawula_pos/features/products/presentation/models/product_draft.dart';
import 'package:kawula_pos/features/products/presentation/pages/product_formatters.dart';
import 'package:kawula_pos/features/products/presentation/widgets/product_management_helpers.dart';
import 'package:kawula_pos/features/products/presentation/widgets/product_image_gallery.dart';
import 'package:kawula_pos/theme/app_colors.dart';

class ProductDialog extends StatefulWidget {
  const ProductDialog({
    super.key,
    required this.categories,
    required this.variantGroups,
    this.discounts = const [],
    this.product,
  });

  final List<ManagedCategory> categories;
  final List<ManagedVariantGroup> variantGroups;
  final List<DiscountDefinition> discounts;
  final ManagedProduct? product;

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late String? _categoryId;
  late String? _discountId;
  late bool _isActive;
  late final Set<String> _selectedVariantGroupIds;
  late List<ProductImageDraft> _images;

  @override
  void initState() {
    super.initState();
    final product = widget.product?.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _priceController = TextEditingController(
      text: product == null ? '' : product.price.toString(),
    );
    _stockController = TextEditingController(
      text: product?.stock?.toString() ?? '0',
    );
    _categoryId =
        widget.categories.any(
          (category) => category.id == product?.category?.id,
        )
        ? product!.category!.id
        : widget.categories.firstOrNull?.id;
    _isActive = product?.isActive ?? true;
    _discountId = product?.discountId;
    _selectedVariantGroupIds = {...?widget.product?.variantGroupIds};
    final productImages = product?.images.isNotEmpty == true
        ? product!.images
        : product?.imageUrl.isNotEmpty == true
        ? [ProductImage(url: product!.imageUrl, isMain: true)]
        : const <ProductImage>[];
    _images = productImages
        .map((image) => ProductImageDraft(url: image.url, isMain: image.isMain))
        .toList();
    if (_images.isNotEmpty && !_images.any((image) => image.isMain)) {
      _images.first.isMain = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    final screenSize = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 680,
          maxHeight: screenSize.height * .9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(22, 20, 14, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEEF4FF), Color(0xFFFFFFFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      isEditing
                          ? Icons.edit_note_rounded
                          : Icons.add_box_outlined,
                      color: AppColors.primary,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Ubah produk' : 'Tambah produk',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isEditing
                              ? 'Perbarui informasi dan pengaturan produk.'
                              : 'Lengkapi detail menu baru untuk toko.',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _formSection(
                      icon: Icons.receipt_long_outlined,
                      title: 'Informasi produk',
                      subtitle: 'Nama, kategori, harga, dan stok menu.',
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final priceAndStock = [
                            Expanded(child: _priceField()),
                            const SizedBox(width: 12),
                            Expanded(child: _stockField()),
                          ];
                          return Column(
                            children: [
                              TextFormField(
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Nama produk',
                                  hintText: 'Contoh: Cappuccino',
                                  prefixIcon: Icon(
                                    Icons.local_cafe_outlined,
                                    size: 19,
                                  ),
                                ),
                                validator: (value) =>
                                    (value?.trim().length ?? 0) < 2
                                    ? 'Nama minimal 2 karakter.'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                initialValue: _categoryId,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Kategori',
                                  prefixIcon: Icon(
                                    Icons.category_outlined,
                                    size: 19,
                                  ),
                                ),
                                items: widget.categories
                                    .map(
                                      (category) => DropdownMenuItem(
                                        value: category.id,
                                        child: Text(
                                          category.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) =>
                                    setState(() => _categoryId = value),
                                validator: (value) => value == null
                                    ? 'Pilih kategori produk.'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              if (constraints.maxWidth >= 460)
                                Row(children: priceAndStock)
                              else ...[
                                _priceField(),
                                const SizedBox(height: 12),
                                _stockField(),
                              ],
                              const SizedBox(height: 12),
                              _discountField(),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    _formSection(
                      icon: Icons.photo_library_outlined,
                      title: 'Galeri produk',
                      subtitle: 'Pilih foto utama dan foto tambahan.',
                      child: ProductImageGallery(
                        images: _images,
                        onChanged: (images) => setState(() => _images = images),
                      ),
                    ),
                    if (widget.variantGroups.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _formSection(
                        icon: Icons.tune_rounded,
                        title: 'Grup varian',
                        subtitle: 'Pilih opsi tambahan yang tersedia untuk produk ini.',
                        child: Column(
                          children: widget.variantGroups
                              .map(
                                (variantGroup) => CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  title: Text(
                                    variantGroup.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    variantGroup.group.options
                                        .map((option) => option.name)
                                        .join(', '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  value: _selectedVariantGroupIds.contains(
                                    variantGroup.id,
                                  ),
                                  onChanged: (selected) {
                                    setState(() {
                                      if (selected == true) {
                                        _selectedVariantGroupIds.add(
                                          variantGroup.id,
                                        );
                                      } else {
                                        _selectedVariantGroupIds.remove(
                                          variantGroup.id,
                                        );
                                      }
                                    });
                                  },
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Material(
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: AppColors.border),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          secondary: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _isActive
                                  ? const Color(0xFFE8FBF3)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              _isActive
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.pause_circle_outline_rounded,
                              color: _isActive
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                            ),
                          ),
                          title: const Text(
                            'Produk aktif',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            _isActive
                                ? 'Produk dapat ditampilkan di kasir.'
                                : 'Produk disembunyikan dari kasir.',
                          ),
                          value: _isActive,
                          onChanged: (value) =>
                              setState(() => _isActive = value),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 13, 20, 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final actions = Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Batal'),
                      ),
                      FilledButton.icon(
                        onPressed: _save,
                        icon: Icon(
                          isEditing ? Icons.save_outlined : Icons.add_rounded,
                          size: 18,
                        ),
                        label: Text(
                          isEditing ? 'Simpan perubahan' : 'Simpan produk',
                        ),
                      ),
                    ],
                  );
                  if (constraints.maxWidth >= 500) {
                    return Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Pastikan informasi produk sudah benar.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        actions,
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Pastikan informasi produk sudah benar.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      actions,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF4FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _priceField() => TextFormField(
    controller: _priceController,
    decoration: const InputDecoration(
      labelText: 'Harga jual',
      prefixText: 'Rp ',
      prefixIcon: Icon(Icons.payments_outlined, size: 19),
    ),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
    validator: (value) => parseNonNegativeNumber(value) == null
        ? 'Masukkan harga yang valid.'
        : null,
  );

  Widget _stockField() => TextFormField(
    controller: _stockController,
    decoration: const InputDecoration(
      labelText: 'Stok produk',
      prefixIcon: Icon(Icons.inventory_2_outlined, size: 19),
    ),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
    validator: (value) => parseNonNegativeNumber(value) == null
        ? 'Masukkan stok yang valid.'
        : null,
  );

  Widget _discountField() {
    final availableDiscounts = widget.discounts
        .where((discount) => discount.isActive || discount.id == _discountId)
        .toList(growable: false);
    final selectedDiscountId =
        availableDiscounts.any((discount) => discount.id == _discountId)
        ? _discountId
        : null;

    return DropdownButtonFormField<String>(
      initialValue: selectedDiscountId ?? '',
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Diskon',
        prefixIcon: Icon(Icons.percent_outlined, size: 19),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: '',
          child: Text('Tanpa Discounts'),
        ),
        ...availableDiscounts.map((discount) {
          final valueLabel = discount.type == DiscountType.percentage
              ? '${discount.value}%'
              : formatRupiah(discount.value);
          return DropdownMenuItem<String>(
            value: discount.id,
            child: Text(
              '${discount.name} ($valueLabel)',
              overflow: TextOverflow.ellipsis,
            ),
          );
        }),
      ],
      onChanged: (value) => setState(
        () => _discountId = value == null || value.isEmpty ? null : value,
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final categoryId = _categoryId;
    if (categoryId == null) return;
    Navigator.pop(
      context,
      ProductDraft(
        name: _nameController.text.trim(),
        price: parseNonNegativeNumber(_priceController.text)!,
        stock: parseNonNegativeNumber(_stockController.text)!,
        categoryId: categoryId,
        discountId: _discountId,
        variantGroupIds: _selectedVariantGroupIds.toList(growable: false),
        images: List.unmodifiable(_images),
        isActive: _isActive,
      ),
    );
  }
}
