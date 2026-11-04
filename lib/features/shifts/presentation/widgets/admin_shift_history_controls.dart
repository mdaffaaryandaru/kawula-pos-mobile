// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:kawula_pos/theme/app_colors.dart';

class AdminShiftsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AdminShiftsAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) =>
      AppBar(title: const ShiftLogoTitle(title: 'Shift kasir'));
}

class ShiftLogoTitle extends StatelessWidget {
  const ShiftLogoTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/images/logo.jpg',
            width: 32,
            height: 32,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        Text(title),
      ],
    );
  }
}

class ShiftHistoryHeader extends StatelessWidget {
  const ShiftHistoryHeader({super.key, required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 520;
    return Container(
      padding: EdgeInsets.all(isWide ? 28 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LAPORAN',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Riwayat Shift',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Memantau riwayat shift kasir, status, dan ringkasan kas.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(isWide ? 'Refresh' : 'Muat ulang'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ShiftHistorySearch extends StatelessWidget {
  const ShiftHistorySearch({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? selectedStatus;
  final ValueChanged<String?> onStatusChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Color(0x080F172A),
          blurRadius: 12,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final search = TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Cari kasir, outlet, atau status...',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        );
        final filter = DropdownButtonFormField<String>(
          initialValue: selectedStatus ?? 'all',
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Status',
            prefixIcon: const Icon(Icons.filter_list_rounded),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('Semua shift')),
            DropdownMenuItem(value: 'open', child: Text('Sedang berjalan')),
            DropdownMenuItem(value: 'closed', child: Text('Ditutup manual')),
            DropdownMenuItem(
              value: 'auto_closed',
              child: Text('Ditutup otomatis'),
            ),
          ],
          onChanged: onStatusChanged,
        );

        if (constraints.maxWidth >= 760) {
          return Row(
            children: [
              Expanded(child: search),
              const SizedBox(width: 12),
              SizedBox(width: 220, child: filter),
            ],
          );
        }
        return Column(children: [search, const SizedBox(height: 12), filter]);
      },
    ),
  );
}
