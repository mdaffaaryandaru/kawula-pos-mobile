import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../config/api_config.dart';
import '../../../categories/domain/entities/managed_category.dart';
import '../../../products/domain/entities/catalog_product.dart';
import '../../domain/entities/product_management.dart';
import '../../domain/repositories/product_management_repository.dart';
import '../bloc/product_management_cubit.dart';

class ProductsManagementPage extends StatelessWidget {
  const ProductsManagementPage({super.key, required this.repository});

  final ProductManagementRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductManagementCubit(repository)..load(),
      child: BlocBuilder<ProductManagementCubit, ProductManagementState>(
        builder: (context, state) => switch (state) {
          ProductManagementLoading() => const Scaffold(
            appBar: _ProductManagementAppBar(),
            body: Center(child: CircularProgressIndicator()),
          ),
          ProductManagementFailure() => Scaffold(
            appBar: const _ProductManagementAppBar(),
            body: _loadFailure(context, state.message),
          ),
          ProductManagementLoaded() => _ProductManagementTabs(state: state),
        },
      ),
    );
  }

  Widget _loadFailure(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Data belum dapat dimuat',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: context.read<ProductManagementCubit>().load,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductManagementAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _ProductManagementAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) =>
      AppBar(title: const Text('Pengelolaan produk'));
}

class _ProductManagementTabs extends StatelessWidget {
  const _ProductManagementTabs({required this.state});

  final ProductManagementLoaded state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produk')),
      body: Column(
        children: [
          if (state.errorMessage != null)
            MaterialBanner(
              content: Text(state.errorMessage!),
              actions: [
                TextButton(
                  onPressed: context.read<ProductManagementCubit>().load,
                  child: const Text('Muat ulang'),
                ),
              ],
            ),
          Expanded(child: _ProductsTab(state: state)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.categories.isEmpty
            ? null
            : () => _editProduct(context, state),
        icon: const Icon(Icons.add),
        label: const Text('Tambah produk'),
      ),
    );
  }
}

class _ProductsTab extends StatelessWidget {
  const _ProductsTab({required this.state});

  final ProductManagementLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProductManagementCubit>();
    return RefreshIndicator(
      onRefresh: cubit.load,
      child: state.products.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 100),
                Center(child: Text('Belum ada produk.')),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: state.products.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = state.products[index];
                return _ProductCard(
                  item: item,
                  onEdit: () => _editProduct(context, state, item),
                  onDelete: () => _deleteProduct(context, item),
                );
              },
            ),
    );
  }
}

Future<void> _editProduct(
  BuildContext context,
  ProductManagementLoaded state, [
  ManagedProduct? item,
]) async {
  final draft = await showDialog<_ProductDraft>(
    context: context,
    builder: (_) => _ProductDialog(
      categories: state.categories,
      variantGroups: state.variantGroups,
      product: item,
    ),
  );
  if (draft == null || !context.mounted) return;
  final cubit = context.read<ProductManagementCubit>();
  final uploadedUrls = await cubit.uploadProductImages(
    draft.images
        .where((image) => image.file != null)
        .map((image) => image.file!)
        .toList(growable: false),
  );
  if (uploadedUrls == null || !context.mounted) {
    if (context.mounted) _showResult(context, false, '');
    return;
  }
  var uploadedIndex = 0;
  final images = draft.images
      .map((image) {
        final url = image.file == null
            ? image.url!
            : uploadedUrls[uploadedIndex++];
        return ProductImage(url: url, isMain: image.isMain);
      })
      .toList(growable: false);
  final success = await context.read<ProductManagementCubit>().saveProduct(
    productId: item?.product.id,
    name: draft.name,
    price: draft.price,
    stock: draft.stock,
    categoryId: draft.categoryId,
    variantGroupIds: draft.variantGroupIds,
    images: images,
    isActive: draft.isActive,
  );
  if (!context.mounted) return;
  _showResult(context, success, 'Produk berhasil disimpan.');
}

Future<void> _deleteProduct(BuildContext context, ManagedProduct item) async {
  final confirmed = await _confirmDelete(
    context,
    title: 'Hapus produk?',
    message: 'Produk "${item.product.name}" akan dihapus.',
  );
  if (!confirmed || !context.mounted) return;
  final success = await context.read<ProductManagementCubit>().deleteProduct(
    item.product.id,
  );
  if (!context.mounted) return;
  _showResult(context, success, 'Produk berhasil dihapus.');
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final ManagedProduct item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final imageUrl =
        product.images.where((image) => image.isMain).firstOrNull?.url ??
        product.imageUrl;
    return Card(
      child: ListTile(
        leading: imageUrl.isEmpty
            ? const CircleAvatar(child: Icon(Icons.image_outlined))
            : CircleAvatar(
                backgroundImage: NetworkImage(_resolveImageUrl(imageUrl)),
              ),
        title: Text(product.name),
        subtitle: Text(
          '${_rupiah(product.price)} · Stok ${_formatNumber(product.stock ?? 0)}'
          '\n${product.category?.name ?? 'Kategori tidak tersedia'}'
          ' · ${product.isActive ? 'Aktif' : 'Nonaktif'}'
          '${item.variantGroupIds.isEmpty ? '' : '\n${item.variantGroupIds.length} grup varian'}',
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Ubah')),
            PopupMenuItem(value: 'delete', child: Text('Hapus')),
          ],
        ),
      ),
    );
  }
}

class _ProductDialog extends StatefulWidget {
  const _ProductDialog({
    required this.categories,
    required this.variantGroups,
    this.product,
  });

  final List<ManagedCategory> categories;
  final List<ManagedVariantGroup> variantGroups;
  final ManagedProduct? product;

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late String? _categoryId;
  late bool _isActive;
  late final Set<String> _selectedVariantGroupIds;
  late final List<_ProductImageDraft> _images;

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
    _selectedVariantGroupIds = {...?widget.product?.variantGroupIds};
    final productImages = product?.images.isNotEmpty == true
        ? product!.images
        : product?.imageUrl.isNotEmpty == true
        ? [ProductImage(url: product!.imageUrl, isMain: true)]
        : const <ProductImage>[];
    _images = productImages
        .map(
          (image) => _ProductImageDraft(url: image.url, isMain: image.isMain),
        )
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
    return AlertDialog(
      title: Text(widget.product == null ? 'Tambah produk' : 'Ubah produk'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nama produk'),
                  validator: (value) => (value?.trim().length ?? 0) < 2
                      ? 'Nama minimal 2 karakter.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Harga'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  validator: (value) => _nonNegativeNumber(value) == null
                      ? 'Masukkan harga yang valid.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _stockController,
                  decoration: const InputDecoration(labelText: 'Stok produk'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  validator: (value) => _nonNegativeNumber(value) == null
                      ? 'Masukkan stok yang valid.'
                      : null,
                ),
                const SizedBox(height: 12),
                _productImagesSection(),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: widget.categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _categoryId = value),
                  validator: (value) =>
                      value == null ? 'Pilih kategori produk.' : null,
                ),
                if (widget.variantGroups.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Grup varian',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  ...widget.variantGroups.map(
                    (variantGroup) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(variantGroup.name),
                      subtitle: Text(
                        variantGroup.group.options
                            .map((option) => option.name)
                            .join(', '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      value: _selectedVariantGroupIds.contains(variantGroup.id),
                      onChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedVariantGroupIds.add(variantGroup.id);
                          } else {
                            _selectedVariantGroupIds.remove(variantGroup.id);
                          }
                        });
                      },
                    ),
                  ),
                ],
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Produk aktif'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _save, child: const Text('Simpan')),
      ],
    );
  }

  Widget _productImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Foto produk (${_images.length}/5)',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextButton.icon(
              onPressed: _images.length == 5 ? null : _pickImages,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Pilih foto'),
            ),
          ],
        ),
        if (_images.isEmpty)
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Belum ada foto. Pilih foto JPG, PNG, WEBP, atau GIF.'),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final image in _images)
                _ProductImageTile(
                  image: image,
                  onSetMain: () => setState(() {
                    for (final entry in _images) {
                      entry.isMain = identical(entry, image);
                    }
                  }),
                  onRemove: () => setState(() {
                    final wasMain = image.isMain;
                    _images.remove(image);
                    if (wasMain && _images.isNotEmpty) {
                      _images.first.isMain = true;
                    }
                  }),
                ),
            ],
          ),
        const SizedBox(height: 4),
        const Text(
          'Maksimal 5 foto, 2 MB per foto. Tandai salah satu sebagai foto utama.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _pickImages() async {
    final remaining = 5 - _images.length;
    if (remaining <= 0) return;
    try {
      final selected = await ImagePicker().pickMultiImage(limit: remaining);
      if (!mounted || selected.isEmpty) return;
      final invalidFiles = selected.where((file) {
        final extension = file.name.contains('.')
            ? file.name.split('.').last.toLowerCase()
            : '';
        return !const {'jpg', 'jpeg', 'png', 'webp', 'gif'}.contains(extension);
      });
      if (invalidFiles.isNotEmpty) {
        _showDialogMessage(
          'Format yang didukung: JPG, JPEG, PNG, WEBP, dan GIF.',
        );
        return;
      }
      final additions = <_ProductImageDraft>[];
      for (final file in selected.take(remaining)) {
        final bytes = Uint8List.fromList(await file.readAsBytes());
        if (bytes.length > 2 * 1024 * 1024) {
          _showDialogMessage('Setiap foto harus berukuran maksimal 2 MB.');
          return;
        }
        additions.add(
          _ProductImageDraft(
            file: file,
            bytes: bytes,
            isMain: _images.isEmpty && additions.isEmpty,
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        _images.addAll(additions);
      });
    } on PlatformException catch (error) {
      _showDialogMessage(
        'Foto tidak dapat dipilih: ${error.message ?? error.code}',
      );
    }
  }

  void _showDialogMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final categoryId = _categoryId;
    if (categoryId == null) return;
    Navigator.pop(
      context,
      _ProductDraft(
        name: _nameController.text.trim(),
        price: _nonNegativeNumber(_priceController.text)!,
        stock: _nonNegativeNumber(_stockController.text)!,
        categoryId: categoryId,
        variantGroupIds: _selectedVariantGroupIds.toList(growable: false),
        images: List.unmodifiable(_images),
        isActive: _isActive,
      ),
    );
  }
}

class _ProductDraft {
  const _ProductDraft({
    required this.name,
    required this.price,
    required this.stock,
    required this.categoryId,
    required this.variantGroupIds,
    required this.images,
    required this.isActive,
  });

  final String name;
  final num price;
  final num stock;
  final String categoryId;
  final List<String> variantGroupIds;
  final List<_ProductImageDraft> images;
  final bool isActive;
}

class _ProductImageDraft {
  _ProductImageDraft({this.url, this.file, this.bytes, required this.isMain});

  final String? url;
  final XFile? file;
  final Uint8List? bytes;
  bool isMain;
}

class _ProductImageTile extends StatelessWidget {
  const _ProductImageTile({
    required this.image,
    required this.onSetMain,
    required this.onRemove,
  });

  final _ProductImageDraft image;
  final VoidCallback onSetMain;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final borderColor = image.isMain
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.outlineVariant;
    return SizedBox(
      width: 104,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 96,
                height: 84,
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: _imagePreview(),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: IconButton.filledTonal(
                  visualDensity: VisualDensity.compact,
                  onPressed: onRemove,
                  tooltip: 'Hapus foto',
                  icon: const Icon(Icons.close, size: 16),
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: image.isMain ? null : onSetMain,
            child: Text(image.isMain ? 'Foto utama' : 'Jadikan utama'),
          ),
        ],
      ),
    );
  }

  Widget _imagePreview() {
    final file = image.file;
    if (file != null) {
      return Image.memory(
        image.bytes ?? Uint8List.fromList([]),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const Center(child: Icon(Icons.broken_image_outlined)),
      );
    }
    return Image.network(
      _resolveImageUrl(image.url!),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) =>
          const Center(child: Icon(Icons.broken_image_outlined)),
    );
  }
}

num? _nonNegativeNumber(String? value) {
  final number = num.tryParse(value ?? '');
  if (number == null || !number.isFinite || number < 0) return null;
  return number;
}

String _rupiah(num value) {
  final digits = value.toInt().toString();
  final result = StringBuffer('Rp ');
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) result.write('.');
    result.write(digits[index]);
  }
  return result.toString();
}

String _formatNumber(num value) {
  if (value == value.toInt()) return value.toInt().toString();
  return value.toString();
}

String _resolveImageUrl(String url) {
  final parsed = Uri.tryParse(url);
  if (parsed?.hasAuthority == true) return url;
  final apiBase = Uri.parse(ApiConfig.baseUrl);
  final basePath = apiBase.path.endsWith('/api')
      ? apiBase.path.substring(0, apiBase.path.length - 4)
      : apiBase.path;
  return apiBase.replace(path: basePath).resolve(url).toString();
}

Future<bool> _confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus'),
            ),
          ],
        ),
      ) ??
      false;
}

void _showResult(BuildContext context, bool success, String successMessage) {
  var message = successMessage;
  if (!success) {
    final state = context.read<ProductManagementCubit>().state;
    message = switch (state) {
      ProductManagementLoaded(errorMessage: final errorMessage) =>
        errorMessage ?? 'Operasi tidak berhasil.',
      ProductManagementFailure(message: final errorMessage) => errorMessage,
      _ => 'Operasi tidak berhasil.',
    };
  }
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
