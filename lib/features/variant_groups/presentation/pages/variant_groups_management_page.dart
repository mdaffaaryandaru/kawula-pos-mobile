import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../products/domain/entities/product_management.dart';
import '../../../products/domain/repositories/product_management_repository.dart';
import '../../domain/entities/variant_group_definition.dart';
import '../../domain/repositories/variant_groups_repository.dart';
import '../../../products/presentation/pages/product_formatters.dart';

class VariantGroupsManagementPage extends StatefulWidget {
  const VariantGroupsManagementPage({
    super.key,
    required this.repository,
    required this.productsRepository,
  });

  final VariantGroupsRepository repository;
  final ProductManagementRepository productsRepository;

  @override
  State<VariantGroupsManagementPage> createState() =>
      _VariantGroupsManagementPageState();
}

class _VariantGroupsManagementPageState
    extends State<VariantGroupsManagementPage> {
  late Future<_VariantGroupsData> _data;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<_VariantGroupsData> _load() async {
    final groups = await widget.repository.getVariantGroupDefinitions();
    return _VariantGroupsData(groups: groups);
  }

  void _reload() {
    setState(() {
      _data = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grup Varian'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<_VariantGroupsData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _loadFailure(snapshot.error.toString());
          }
          final data = snapshot.data!;
          final filteredGroups = data.groups
              .where(
                (group) =>
                    group.name.toLowerCase().contains(_query.toLowerCase()) ||
                    group.options.any(
                      (option) => option.name.toLowerCase().contains(
                        _query.toLowerCase(),
                      ),
                    ),
              )
              .toList(growable: false);
          return RefreshIndicator(
            onRefresh: () async {
              final future = _load();
              setState(() {
                _data = future;
              });
              await future;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                _pageHeading(data.groups.length),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Cari grup varian...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Hapus pencarian',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close),
                          ),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _editGroup(data),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Tambah Grup Varian'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
                const SizedBox(height: 16),
                if (data.groups.isEmpty)
                  _emptyState(
                    'Belum ada grup varian',
                    'Buat grup untuk pilihan seperti rasa, suhu, atau ukuran.',
                  )
                else if (filteredGroups.isEmpty)
                  _emptyState(
                    'Grup Varian Tidak Ditemukan',
                    'Coba periksa kembali kata kunci pencarian Anda.',
                  )
                else
                  for (final group in filteredGroups) ...[
                    _VariantGroupCard(
                      group: group,
                      onEdit: () => _editGroup(data, group),
                      onDelete: () => _deleteGroup(group),
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _loadFailure(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 44),
            const SizedBox(height: 12),
            const Text(
              'Data grup varian belum dapat dimuat',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _reload, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }

  Widget _pageHeading(int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Master Data  ›  ',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'Grup Varian',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Grup Varian',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Chip(label: Text('$count Grup Aktif')),
          ],
        ),
        Text(
          'Kelola pilihan rasa, suhu, dan ukuran untuk katalog menu.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _emptyState(String title, String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 42, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Future<void> _editGroup(
    _VariantGroupsData data, [
    VariantGroupDefinition? group,
  ]) async {
    late final VariantRecipeReferences references;
    try {
      references = await widget.repository.getVariantRecipeReferences();
    } catch (error) {
      if (!mounted) return;
      _showMessage('Referensi resep tidak dapat dimuat: $error');
      return;
    }
    if (!mounted) return;
    final draft = await showDialog<_VariantGroupDraft>(
      context: context,
      builder: (_) => _VariantGroupDialog(group: group, references: references),
    );
    if (draft == null || !mounted) return;
    try {
      await widget.repository.saveVariantGroup(
        groupId: group?.id,
        name: draft.name,
        isRequired: draft.isRequired,
        minSelection: draft.minSelection,
        maxSelection: draft.maxSelection,
        options: draft.options,
      );
      if (!mounted) return;
      _reload();
      _showMessage(
        group == null
            ? 'Grup varian berhasil dibuat.'
            : 'Grup varian berhasil diperbarui.',
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage('Grup varian gagal disimpan: $error');
    }
  }

  Future<void> _deleteGroup(VariantGroupDefinition group) async {
    late final List<ManagedProduct> products;
    try {
      products = await widget.productsRepository.getProducts();
    } catch (error) {
      if (!mounted) return;
      _showMessage('Produk tidak dapat diperiksa sebelum penghapusan: $error');
      return;
    }
    if (!mounted) return;
    final linkedProducts = products
        .where((product) => product.variantGroupIds.contains(group.id))
        .toList(growable: false);
    if (linkedProducts.isNotEmpty) {
      _showMessage(
        'Grup ini masih digunakan oleh ${linkedProducts.length} produk. '
        'Lepaskan grup dari produk sebelum menghapusnya.',
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus grup varian?'),
        content: Text(
          'Grup "${group.name}" akan dihapus permanen dari server.',
        ),
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
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.repository.deleteVariantGroup(group.id);
      if (!mounted) return;
      _reload();
      _showMessage('Grup varian berhasil dihapus.');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Grup varian gagal dihapus: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _VariantGroupsData {
  const _VariantGroupsData({required this.groups});

  final List<VariantGroupDefinition> groups;
}

class _VariantGroupCard extends StatelessWidget {
  const _VariantGroupCard({
    required this.group,
    required this.onEdit,
    required this.onDelete,
  });

  final VariantGroupDefinition group;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Icon(
                    Icons.tune_outlined,
                    size: 19,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Min/Max: ${group.minSelection} - '
                        '${group.maxSelection} pilihan',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                _RequirementBadge(isRequired: group.isRequired),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'OPSI VARIAN (${group.options.length})',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final option in group.options)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    label: Text(
                      option.priceAdjustment == 0
                          ? option.name
                          : '${option.name} (${option.priceAdjustment > 0 ? '+' : '-'}'
                                '${formatRupiah(option.priceAdjustment.abs())})',
                    ),
                  ),
              ],
            ),
            if (group.options.any((option) => option.recipes.isNotEmpty)) ...[
              const SizedBox(height: 8),
              for (final option in group.options)
                for (final recipe in option.recipes)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      '${option.name}: ${recipe.inventoryName} · '
                      '${recipe.quantity} ${recipe.unitName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Spacer(),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Hapus'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RequirementBadge extends StatelessWidget {
  const _RequirementBadge({required this.isRequired});

  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isRequired
            ? colorScheme.tertiaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isRequired ? 'Wajib' : 'Tidak Wajib',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isRequired
              ? colorScheme.onTertiaryContainer
              : colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _VariantGroupDialog extends StatefulWidget {
  const _VariantGroupDialog({this.group, required this.references});

  final VariantGroupDefinition? group;
  final VariantRecipeReferences references;

  @override
  State<_VariantGroupDialog> createState() => _VariantGroupDialogState();
}

class _VariantGroupDialogState extends State<_VariantGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _minSelectionController;
  late final TextEditingController _maxSelectionController;
  late bool _isRequired;
  late final List<_VariantOptionForm> _options;
  String? _formError;

  @override
  void initState() {
    super.initState();
    final group = widget.group;
    _nameController = TextEditingController(text: group?.name ?? '');
    _minSelectionController = TextEditingController(
      text: '${group?.minSelection ?? 0}',
    );
    _maxSelectionController = TextEditingController(
      text: '${group?.maxSelection ?? 1}',
    );
    _isRequired = group?.isRequired ?? false;
    _options = group == null || group.options.isEmpty
        ? [_VariantOptionForm(references: widget.references)]
        : group.options
              .map(
                (option) => _VariantOptionForm(
                  references: widget.references,
                  option: option,
                ),
              )
              .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minSelectionController.dispose();
    _maxSelectionController.dispose();
    for (final option in _options) {
      option.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.group != null;
    return AlertDialog(
      title: Text(isEditing ? 'Ubah grup varian' : 'Tambah grup varian'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama grup',
                    hintText: 'Contoh: Ukuran',
                  ),
                  validator: (value) => (value?.trim().length ?? 0) < 2
                      ? 'Nama minimal 2 karakter.'
                      : null,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Pilihan wajib diisi'),
                  value: _isRequired,
                  onChanged: (value) => setState(() {
                    _isRequired = value;
                    _formError = null;
                    if (value &&
                        (num.tryParse(_minSelectionController.text) ?? 0) < 1) {
                      _minSelectionController.text = '1';
                    }
                  }),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minSelectionController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Minimal dipilih',
                        ),
                        validator: (value) {
                          final min = int.tryParse(value ?? '');
                          if (min == null) return 'Masukkan jumlah.';
                          return _isRequired && min < 1
                              ? 'Grup wajib memiliki minimal 1 pilihan.'
                              : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _maxSelectionController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Maksimal dipilih',
                        ),
                        validator: (value) {
                          final max = int.tryParse(value ?? '');
                          if (max == null || max < 1) {
                            return 'Minimal 1.';
                          }
                          final min = int.tryParse(
                            _minSelectionController.text,
                          );
                          return min != null && min > max
                              ? 'Maksimal harus ≥ minimal.'
                              : null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Opsi dan harga',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => setState(
                        () => _options.add(
                          _VariantOptionForm(references: widget.references),
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah opsi'),
                    ),
                  ],
                ),
                for (var index = 0; index < _options.length; index++)
                  _optionEditor(index),
                if (_formError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _formError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Resep bahan bersifat opsional. Jika ditambahkan, server '
                  'memakai resep tersebut untuk pemakaian inventori.',
                  style: Theme.of(context).textTheme.bodySmall,
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
        FilledButton(
          onPressed: _save,
          child: Text(isEditing ? 'Simpan perubahan' : 'Buat grup'),
        ),
      ],
    );
  }

  Widget _optionEditor(int index) {
    final option = _options[index];
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Opsi ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (_options.length > 1)
                  IconButton(
                    tooltip: 'Hapus opsi',
                    onPressed: () => setState(() {
                      _options.removeAt(index).dispose();
                    }),
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            TextFormField(
              controller: option.nameController,
              decoration: const InputDecoration(
                labelText: 'Nama opsi',
                hintText: 'Contoh: Large',
              ),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Nama opsi wajib diisi.'
                  : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: option.priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
              ],
              decoration: const InputDecoration(
                labelText: 'Penyesuaian harga',
                helperText: 'Gunakan nilai negatif untuk potongan harga.',
                prefixText: 'Rp ',
              ),
              validator: (value) => num.tryParse(value ?? '') == null
                  ? 'Masukkan penyesuaian harga yang valid.'
                  : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Resep bahan (opsional)',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                TextButton.icon(
                  onPressed:
                      widget.references.inventories.isEmpty ||
                          widget.references.units.isEmpty
                      ? null
                      : () => setState(
                          () => option.recipes.add(
                            _VariantRecipeForm(references: widget.references),
                          ),
                        ),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah'),
                ),
              ],
            ),
            if (widget.references.inventories.isEmpty ||
                widget.references.units.isEmpty)
              Text(
                'Bahan dan satuan harus tersedia sebelum resep dapat ditambahkan.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            for (
              var recipeIndex = 0;
              recipeIndex < option.recipes.length;
              recipeIndex++
            )
              _recipeEditor(option, recipeIndex),
          ],
        ),
      ),
    );
  }

  Widget _recipeEditor(_VariantOptionForm option, int index) {
    final recipe = option.recipes[index];
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: recipe.inventoryId,
            decoration: const InputDecoration(labelText: 'Bahan baku'),
            items: [
              for (final item in widget.references.inventories)
                DropdownMenuItem(value: item.id, child: Text(item.name)),
            ],
            validator: (value) => value == null ? 'Pilih bahan baku.' : null,
            onChanged: (value) => setState(() => recipe.inventoryId = value),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: recipe.quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: const InputDecoration(labelText: 'Jumlah'),
                  validator: (value) {
                    final amount = num.tryParse(value ?? '');
                    return amount == null || amount < 0.001
                        ? 'Minimal 0.001.'
                        : null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  initialValue: recipe.unitId,
                  decoration: const InputDecoration(labelText: 'Satuan'),
                  items: [
                    for (final unit in widget.references.units)
                      DropdownMenuItem(value: unit.id, child: Text(unit.name)),
                  ],
                  validator: (value) => value == null ? 'Pilih satuan.' : null,
                  onChanged: (value) => setState(() => recipe.unitId = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: recipe.conversionFactorController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Faktor konversi',
                    helperText: 'Konversi ke satuan dasar bahan',
                  ),
                  validator: (value) {
                    final factor = num.tryParse(value ?? '');
                    return factor == null || factor < 0.0001
                        ? 'Minimal 0.0001.'
                        : null;
                  },
                ),
              ),
              IconButton(
                tooltip: 'Hapus resep',
                onPressed: () => setState(() {
                  option.recipes.removeAt(index).dispose();
                }),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final minSelection = int.parse(_minSelectionController.text);
    final maxSelection = int.parse(_maxSelectionController.text);
    if (_options.isEmpty) {
      setState(() => _formError = 'Grup harus memiliki minimal satu opsi.');
      return;
    }
    Navigator.pop(
      context,
      _VariantGroupDraft(
        name: _nameController.text.trim(),
        isRequired: _isRequired,
        minSelection: minSelection,
        maxSelection: maxSelection,
        options: _options
            .map(
              (option) => VariantOptionDefinition(
                name: option.nameController.text.trim(),
                priceAdjustment: num.parse(option.priceController.text.trim()),
                recipes: option.recipes
                    .map(
                      (recipe) => VariantRecipeDefinition(
                        inventoryId: recipe.inventoryId!,
                        inventoryName: widget.references.inventories
                            .firstWhere((item) => item.id == recipe.inventoryId)
                            .name,
                        quantity: num.parse(
                          recipe.quantityController.text.trim(),
                        ),
                        unitId: recipe.unitId!,
                        unitName: widget.references.units
                            .firstWhere((item) => item.id == recipe.unitId)
                            .name,
                        conversionFactor: num.parse(
                          recipe.conversionFactorController.text.trim(),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _VariantOptionForm {
  _VariantOptionForm({
    required VariantRecipeReferences references,
    VariantOptionDefinition? option,
  }) : nameController = TextEditingController(text: option?.name ?? ''),
       priceController = TextEditingController(
         text: '${option?.priceAdjustment ?? 0}',
       ),
       recipes =
           option?.recipes
               .map(
                 (recipe) =>
                     _VariantRecipeForm(references: references, recipe: recipe),
               )
               .toList() ??
           [];

  final TextEditingController nameController;
  final TextEditingController priceController;
  final List<_VariantRecipeForm> recipes;

  void dispose() {
    nameController.dispose();
    priceController.dispose();
    for (final recipe in recipes) {
      recipe.dispose();
    }
  }
}

class _VariantRecipeForm {
  _VariantRecipeForm({
    required VariantRecipeReferences references,
    VariantRecipeDefinition? recipe,
  }) : inventoryId =
           recipe?.inventoryId ?? references.inventories.firstOrNull?.id,
       unitId = recipe?.unitId ?? references.units.firstOrNull?.id,
       quantityController = TextEditingController(
         text: '${recipe?.quantity ?? 1}',
       ),
       conversionFactorController = TextEditingController(
         text: '${recipe?.conversionFactor ?? 1}',
       );

  String? inventoryId;
  String? unitId;
  final TextEditingController quantityController;
  final TextEditingController conversionFactorController;

  void dispose() {
    quantityController.dispose();
    conversionFactorController.dispose();
  }
}

class _VariantGroupDraft {
  const _VariantGroupDraft({
    required this.name,
    required this.isRequired,
    required this.minSelection,
    required this.maxSelection,
    required this.options,
  });

  final String name;
  final bool isRequired;
  final int minSelection;
  final int maxSelection;
  final List<VariantOptionDefinition> options;
}
