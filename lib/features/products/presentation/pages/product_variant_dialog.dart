import 'package:flutter/material.dart';

import '../../domain/entities/catalog_product.dart';
import 'product_formatters.dart';

Future<List<SelectedProductVariant>?> showProductVariantDialog(
  BuildContext context,
  CatalogProduct product,
) {
  final selectedByGroup = <String, Set<String>>{};
  final formKey = GlobalKey<FormState>();

  return showDialog<List<SelectedProductVariant>>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(product.name),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final group in product.variantGroups) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${group.name}${group.isRequired ? ' *' : ''}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (group.maxSelection > 1)
                      Text(
                        'Pilih ${group.minSelection}–${group.maxSelection} opsi',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    FormField<Set<String>>(
                      initialValue: selectedByGroup[group.name] ?? <String>{},
                      validator: (_) {
                        final count = selectedByGroup[group.name]?.length ?? 0;
                        if (count < group.minSelection ||
                            count > group.maxSelection) {
                          return 'Pilih ${group.minSelection}–${group.maxSelection} opsi.';
                        }
                        if (group.isRequired && count == 0) {
                          return 'Varian ini wajib dipilih.';
                        }
                        return null;
                      },
                      builder: (field) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (group.maxSelection == 1)
                            RadioGroup<String>(
                              groupValue:
                                  selectedByGroup[group.name]?.firstOrNull,
                              onChanged: (value) {
                                setState(() {
                                  selectedByGroup[group.name] = {?value};
                                });
                                field.didChange(selectedByGroup[group.name]);
                              },
                              child: Column(
                                children: [
                                  for (final option in group.options)
                                    RadioListTile<String>(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(option.name),
                                      subtitle: Text(
                                        option.priceAdjustment == 0
                                            ? 'Tanpa tambahan harga'
                                            : '+${formatRupiah(option.priceAdjustment)}',
                                      ),
                                      value: option.id ?? option.name,
                                    ),
                                ],
                              ),
                            )
                          else
                            for (final option in group.options)
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(option.name),
                                subtitle: Text(
                                  option.priceAdjustment == 0
                                      ? 'Tanpa tambahan harga'
                                      : '+${formatRupiah(option.priceAdjustment)}',
                                ),
                                value:
                                    selectedByGroup[group.name]?.contains(
                                      option.id ?? option.name,
                                    ) ??
                                    false,
                                onChanged: (checked) {
                                  setState(() {
                                    final selections = selectedByGroup
                                        .putIfAbsent(
                                          group.name,
                                          () => <String>{},
                                        );
                                    final key = option.id ?? option.name;
                                    if (checked == true &&
                                        selections.length <
                                            group.maxSelection) {
                                      selections.add(key);
                                    } else {
                                      selections.remove(key);
                                    }
                                  });
                                  field.didChange(selectedByGroup[group.name]);
                                },
                              ),
                          if (field.errorText != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Text(
                                field.errorText!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final selections = <SelectedProductVariant>[];
              for (final group in product.variantGroups) {
                final selected =
                    selectedByGroup[group.name] ?? const <String>{};
                for (final option in group.options) {
                  if (!selected.contains(option.id ?? option.name)) continue;
                  selections.add(
                    SelectedProductVariant(
                      groupName: group.name,
                      optionName: option.name,
                      optionId: option.id,
                      priceAdjustment: option.priceAdjustment,
                    ),
                  );
                }
              }
              Navigator.pop(dialogContext, selections);
            },
            child: const Text('Tambahkan'),
          ),
        ],
      ),
    ),
  );
}
