// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:image_picker/image_picker.dart';

// Project imports:
import 'package:kawula_pos/features/products/presentation/models/product_draft.dart';
import 'package:kawula_pos/features/products/presentation/widgets/product_management_helpers.dart';

class ProductImageGallery extends StatefulWidget {
  const ProductImageGallery({
    super.key,
    required this.images,
    required this.onChanged,
  });

  final List<ProductImageDraft> images;
  final ValueChanged<List<ProductImageDraft>> onChanged;

  @override
  State<ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<ProductImageGallery> {
  late final List<ProductImageDraft> _images;

  @override
  void initState() {
    super.initState();
    _images = [...widget.images];
  }

  @override
  Widget build(BuildContext context) {
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
                    _notifyChanged();
                  }),
                  onRemove: () => setState(() {
                    final wasMain = image.isMain;
                    _images.remove(image);
                    if (wasMain && _images.isNotEmpty) {
                      _images.first.isMain = true;
                    }
                    _notifyChanged();
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
      final additions = <ProductImageDraft>[];
      for (final file in selected.take(remaining)) {
        final bytes = Uint8List.fromList(await file.readAsBytes());
        if (bytes.length > 2 * 1024 * 1024) {
          _showDialogMessage('Setiap foto harus berukuran maksimal 2 MB.');
          return;
        }
        additions.add(
          ProductImageDraft(
            file: file,
            bytes: bytes,
            isMain: _images.isEmpty && additions.isEmpty,
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        _images.addAll(additions);
        _notifyChanged();
      });
    } on PlatformException catch (error) {
      _showDialogMessage(
        'Foto tidak dapat dipilih: ${error.message ?? error.code}',
      );
    }
  }

  void _notifyChanged() {
    widget.onChanged(List.unmodifiable(_images));
  }

  void _showDialogMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ProductImageTile extends StatelessWidget {
  const _ProductImageTile({
    required this.image,
    required this.onSetMain,
    required this.onRemove,
  });

  final ProductImageDraft image;
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
      resolveProductImageUrl(image.url!),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) =>
          const Center(child: Icon(Icons.broken_image_outlined)),
    );
  }
}
