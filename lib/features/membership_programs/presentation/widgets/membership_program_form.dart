import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../framework/widgets/master_data_header.dart';
import '../../../discounts/domain/entities/discount_definition.dart';
import '../../../products/domain/entities/catalog_product.dart';
import '../../domain/entities/membership_program.dart';
import '../bloc/membership_program_cubit.dart';

class MembershipProgramForm extends StatefulWidget {
  const MembershipProgramForm({
    super.key,
    required this.program,
    required this.products,
    required this.discounts,
  });

  final MembershipProgram program;
  final List<CatalogProduct> products;
  final List<DiscountDefinition> discounts;

  @override
  State<MembershipProgramForm> createState() => _MembershipProgramFormState();
}

class _MembershipProgramFormState extends State<MembershipProgramForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _targetVisitsController;
  late String _rewardType;
  String? _rewardId;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _targetVisitsController = TextEditingController(
      text: widget.program.targetVisits.toString(),
    );
    _rewardType = widget.program.rewardType;
    _rewardId = widget.program.rewardId;
    _isActive = widget.program.isActive;
  }

  @override
  void dispose() {
    _targetVisitsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isProductReward = _rewardType == 'product';
    final List<_RewardOption> rewardOptions = isProductReward
        ? widget.products
              .map((item) => _RewardOption(id: item.id, name: item.name))
              .toList(growable: false)
        : widget.discounts
              .map((item) => _RewardOption(id: item.id, name: item.name))
              .toList(growable: false);
    if (_rewardId != null &&
        !rewardOptions.any((item) => item.id == _rewardId)) {
      _rewardId = null;
    }

    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _header(context),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: _panelDecoration(context),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _targetVisitsController,
                    decoration: const InputDecoration(
                      labelText: 'Target Kunjungan',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final target = int.tryParse(value?.trim() ?? '');
                      if (target == null || target < 1) {
                        return 'Target minimal 1 kunjungan.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Jumlah kunjungan atau transaksi yang harus dicapai pelanggan untuk mendapatkan reward.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: _rewardType,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Tipe Reward'),
                    items: const [
                      DropdownMenuItem(
                        value: 'product',
                        child: Text('Produk Gratis'),
                      ),
                      DropdownMenuItem(
                        value: 'discount',
                        child: Text('Diskon'),
                      ),
                    ],
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() {
                              _rewardType = value;
                              _rewardId = null;
                            });
                          },
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_rewardType),
                    initialValue: _rewardId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: isProductReward
                          ? 'Produk Reward'
                          : 'Diskon Reward',
                      hintText: isProductReward
                          ? 'Pilih produk yang akan diberikan gratis'
                          : 'Pilih diskon yang akan diberikan',
                    ),
                    items: [
                      for (final item in rewardOptions)
                        DropdownMenuItem<String>(
                          value: item.id,
                          child: Text(
                            item.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: _isSaving || rewardOptions.isEmpty
                        ? null
                        : (value) => setState(() => _rewardId = value),
                    validator: (value) {
                      if (_isActive && (value == null || value.isEmpty)) {
                        return isProductReward
                            ? 'Pilih produk reward.'
                            : 'Pilih diskon reward.';
                      }
                      return null;
                    },
                  ),
                  if (rewardOptions.isEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      isProductReward
                          ? 'Belum ada produk aktif untuk dijadikan reward.'
                          : 'Belum ada diskon aktif untuk dijadikan reward.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status Program',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Aktifkan agar fitur klaim otomatis muncul di aplikasi kasir ketika pelanggan mencapai target.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Material(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          child: CheckboxListTile(
                            value: _isActive,
                            onChanged: _isSaving
                                ? null
                                : (value) => setState(
                                    () => _isActive = value ?? false,
                                  ),
                            title: const Text(
                              'Aktifkan program membership',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Simpan Program'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) => MasterDataHeader(
    eyebrow: 'ADMINISTRASI',
    title: 'Program Membership',
    description: 'Atur target stamp dan reward member yang otomatis berulang.',
    onRefresh: () {
      if (!_isSaving) context.read<MembershipProgramCubit>().load();
    },
  );

  BoxDecoration _panelDecoration(BuildContext context) => BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final targetVisits = int.parse(_targetVisitsController.text.trim());
    setState(() => _isSaving = true);
    final success = await context.read<MembershipProgramCubit>().save(
      targetVisits: targetVisits,
      rewardType: _rewardType,
      rewardId: _rewardId,
      isActive: _isActive,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Program membership berhasil disimpan.')),
      );
    }
  }
}

class _RewardOption {
  const _RewardOption({required this.id, required this.name});

  final String id;
  final String name;
}
