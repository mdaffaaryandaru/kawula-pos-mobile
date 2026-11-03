// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:kawula_pos/features/transactions/presentation/bloc/checkout_cubit.dart';
import 'package:kawula_pos/features/transactions/presentation/pages/checkout_page.dart';

extension CheckoutMemberWidgets on CheckoutPageState {
  Widget memberSelector(BuildContext context, bool isSubmitting) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Member (opsional)', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Pilih member terdaftar untuk mendapatkan stamp. Kosongkan jika bukan member.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (selectedMember case final member?)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InputChip(
                    avatar: const Icon(Icons.person_outline),
                    label: Text('${member.name} · ${member.phoneNumber}'),
                    deleteButtonTooltipMessage: 'Hapus member',
                    onDeleted: isSubmitting || isClaimingReward
                        ? null
                        : () => updateState(() {
                            selectedMember = null;
                            memberSearchController.clear();
                          }),
                  ),
                  Text('${member.currentStamps} stamp'),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: isSubmitting || isClaimingReward
                        ? null
                        : () => _claimSelectedMemberReward(context),
                    icon: isClaimingReward
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.card_giftcard_outlined),
                    label: Text(
                      isClaimingReward ? 'Memproses klaim...' : 'Klaim reward',
                    ),
                  ),
                  Text(
                    'Klaim langsung memotong stamp dan terpisah dari transaksi. '
                    'Reward perlu diberikan atau diterapkan manual.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              )
            else
              TextField(
                controller: memberSearchController,
                focusNode: memberSearchFocusNode,
                enabled: !isSubmitting,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: 'Cari nama atau nomor telepon',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: isSearchingMembers
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : memberSearchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus pencarian',
                          onPressed: () {
                            memberSearchTimer?.cancel();
                            memberSearchGeneration++;
                            memberSearchController.clear();
                            updateState(() {
                              memberResults = const [];
                              isSearchingMembers = false;
                              memberSearchError = null;
                            });
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
                onChanged: _onMemberSearchChanged,
              ),
            if (memberSearchError case final error?)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  error,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            if (memberSearchController.text.trim().length < 2 &&
                selectedMember == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Masukkan minimal 2 karakter untuk mencari.'),
              ),
            if (memberResults.isNotEmpty && selectedMember == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: memberResults.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final member = memberResults[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          child: Icon(Icons.person_outline),
                        ),
                        title: Text(member.name),
                        subtitle: Text(
                          '${member.phoneNumber} · ${member.currentStamps} stamp',
                        ),
                        onTap: () {
                          memberSearchTimer?.cancel();
                          memberSearchGeneration++;
                          memberSearchFocusNode.unfocus();
                          updateState(() {
                            selectedMember = member;
                            memberResults = const [];
                            memberSearchController.clear();
                            memberSearchError = null;
                          });
                        },
                      );
                    },
                  ),
                ),
              )
            else if (memberSearchController.text.trim().length >= 2 &&
                !isSearchingMembers &&
                memberSearchError == null &&
                memberResults.isEmpty &&
                selectedMember == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Member aktif tidak ditemukan.'),
              ),
            if (openBill && selectedMember != null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Stamp akan ditambahkan saat open bill dilunasi.'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _claimSelectedMemberReward(BuildContext context) async {
    final member = selectedMember;
    if (member == null || isClaimingReward) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Klaim reward member?'),
        content: Text(
          'Klaim untuk ${member.name} akan langsung mengurangi stamp sesuai '
          'program aktif. Klaim ini tidak terhubung ke pembayaran dan reward '
          'harus diberikan atau diterapkan manual.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Klaim sekarang'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || !context.mounted) return;

    updateState(() => isClaimingReward = true);
    try {
      final claim = await context.read<CheckoutCubit>().claimMemberReward(
        member.id,
      );
      if (!mounted || !context.mounted) return;
      updateState(() {
        selectedMember = claim.member;
        isClaimingReward = false;
      });
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reward berhasil diklaim'),
          content: Text(
            '${claim.rewardName} (${claim.rewardType}) untuk ${claim.member.name}. '
            'Sisa stamp: ${claim.member.currentStamps}. '
            'Reward belum diterapkan otomatis ke transaksi.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted || !context.mounted) return;
      updateState(() => isClaimingReward = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Klaim reward gagal: $error')));
    }
  }

  void _onMemberSearchChanged(String value) {
    memberSearchTimer?.cancel();
    final query = value.trim();
    final generation = ++memberSearchGeneration;
    updateState(() {
      selectedMember = null;
      memberResults = const [];
      memberSearchError = null;
      isSearchingMembers = query.length >= 2;
    });
    if (query.length < 2) {
      updateState(() => isSearchingMembers = false);
      return;
    }
    memberSearchTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final members = await context.read<CheckoutCubit>().searchMembers(
          query,
        );
        if (!mounted || generation != memberSearchGeneration) return;
        updateState(() {
          memberResults = members
              .where((member) => member.isActive)
              .toList(growable: false);
          isSearchingMembers = false;
        });
      } catch (error) {
        if (!mounted || generation != memberSearchGeneration) return;
        updateState(() {
          isSearchingMembers = false;
          memberSearchError = 'Member gagal dimuat: $error';
        });
      }
    });
  }
}
