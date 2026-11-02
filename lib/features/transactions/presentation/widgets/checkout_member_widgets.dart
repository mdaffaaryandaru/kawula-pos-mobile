part of '../pages/checkout_page.dart';

// Extensions keep checkout rendering close to its page-owned state.
// ignore_for_file: invalid_use_of_protected_member

extension _CheckoutMemberWidgets on _CheckoutPageState {
  Widget _memberSelector(BuildContext context, bool isSubmitting) {
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
            if (_selectedMember case final member?)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InputChip(
                    avatar: const Icon(Icons.person_outline),
                    label: Text('${member.name} · ${member.phoneNumber}'),
                    deleteButtonTooltipMessage: 'Hapus member',
                    onDeleted: isSubmitting || _isClaimingReward
                        ? null
                        : () => setState(() {
                            _selectedMember = null;
                            _memberSearchController.clear();
                          }),
                  ),
                  Text('${member.currentStamps} stamp'),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: isSubmitting || _isClaimingReward
                        ? null
                        : () => _claimSelectedMemberReward(context),
                    icon: _isClaimingReward
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.card_giftcard_outlined),
                    label: Text(
                      _isClaimingReward ? 'Memproses klaim...' : 'Klaim reward',
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
                controller: _memberSearchController,
                focusNode: _memberSearchFocusNode,
                enabled: !isSubmitting,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: 'Cari nama atau nomor telepon',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _isSearchingMembers
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _memberSearchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus pencarian',
                          onPressed: () {
                            _memberSearchTimer?.cancel();
                            _memberSearchGeneration++;
                            _memberSearchController.clear();
                            setState(() {
                              _memberResults = const [];
                              _isSearchingMembers = false;
                              _memberSearchError = null;
                            });
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
                onChanged: _onMemberSearchChanged,
              ),
            if (_memberSearchError case final error?)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  error,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            if (_memberSearchController.text.trim().length < 2 &&
                _selectedMember == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Masukkan minimal 2 karakter untuk mencari.'),
              ),
            if (_memberResults.isNotEmpty && _selectedMember == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _memberResults.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final member = _memberResults[index];
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
                          _memberSearchTimer?.cancel();
                          _memberSearchGeneration++;
                          _memberSearchFocusNode.unfocus();
                          setState(() {
                            _selectedMember = member;
                            _memberResults = const [];
                            _memberSearchController.clear();
                            _memberSearchError = null;
                          });
                        },
                      );
                    },
                  ),
                ),
              )
            else if (_memberSearchController.text.trim().length >= 2 &&
                !_isSearchingMembers &&
                _memberSearchError == null &&
                _memberResults.isEmpty &&
                _selectedMember == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Member aktif tidak ditemukan.'),
              ),
            if (_openBill && _selectedMember != null)
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
    final member = _selectedMember;
    if (member == null || _isClaimingReward) return;

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

    setState(() => _isClaimingReward = true);
    try {
      final claim = await context.read<CheckoutCubit>().claimMemberReward(
        member.id,
      );
      if (!mounted || !context.mounted) return;
      setState(() {
        _selectedMember = claim.member;
        _isClaimingReward = false;
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
      setState(() => _isClaimingReward = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Klaim reward gagal: $error')));
    }
  }

  void _onMemberSearchChanged(String value) {
    _memberSearchTimer?.cancel();
    final query = value.trim();
    final generation = ++_memberSearchGeneration;
    setState(() {
      _selectedMember = null;
      _memberResults = const [];
      _memberSearchError = null;
      _isSearchingMembers = query.length >= 2;
    });
    if (query.length < 2) {
      setState(() => _isSearchingMembers = false);
      return;
    }
    _memberSearchTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final members = await context.read<CheckoutCubit>().searchMembers(
          query,
        );
        if (!mounted || generation != _memberSearchGeneration) return;
        setState(() {
          _memberResults = members
              .where((member) => member.isActive)
              .toList(growable: false);
          _isSearchingMembers = false;
        });
      } catch (error) {
        if (!mounted || generation != _memberSearchGeneration) return;
        setState(() {
          _isSearchingMembers = false;
          _memberSearchError = 'Member gagal dimuat: $error';
        });
      }
    });
  }
}
