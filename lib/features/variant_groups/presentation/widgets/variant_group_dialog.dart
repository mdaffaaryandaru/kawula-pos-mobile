part of '../pages/variant_groups_management_page.dart';

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
