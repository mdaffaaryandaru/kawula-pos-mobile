import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../balances/domain/repositories/balances_repository.dart';
import '../../../balances/presentation/pages/balances_admin_page.dart';
import '../../../categories/domain/repositories/categories_repository.dart';
import '../../../categories/presentation/pages/categories_management_page.dart';
import '../../../products/domain/repositories/product_management_repository.dart';
import '../../../products/presentation/pages/products_management_page.dart';
import '../../../shifts/domain/repositories/admin_shifts_repository.dart';
import '../../../shifts/presentation/pages/admin_shifts_page.dart';
import '../../../store_settings/domain/repositories/store_settings_repository.dart';
import '../../../store_settings/presentation/pages/store_settings_page.dart';
import '../../../transactions/domain/repositories/checkout_repository.dart';
import '../../../transactions/presentation/pages/admin_transaction_report_page.dart';
import '../../../users/domain/repositories/user_management_repository.dart';
import '../../../users/presentation/pages/admin_users_page.dart';
import '../../../variant_groups/domain/repositories/variant_groups_repository.dart';
import '../../../variant_groups/presentation/pages/variant_groups_management_page.dart';

class AdminManagementPage extends StatelessWidget {
  const AdminManagementPage({
    super.key,
    required this.admin,
    required this.apiBaseUrl,
    required this.userManagementRepository,
    required this.productManagementRepository,
    required this.categoriesRepository,
    required this.balancesRepository,
    required this.storeSettingsRepository,
    required this.checkoutRepository,
    required this.shiftsRepository,
    required this.variantGroupsRepository,
  });

  final AuthUser admin;
  final String apiBaseUrl;
  final UserManagementRepository userManagementRepository;
  final ProductManagementRepository productManagementRepository;
  final CategoriesRepository categoriesRepository;
  final BalancesRepository balancesRepository;
  final StoreSettingsRepository storeSettingsRepository;
  final CheckoutRepository checkoutRepository;
  final AdminShiftsRepository shiftsRepository;
  final VariantGroupsRepository variantGroupsRepository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Operasional', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _ManagementTile(
              title: 'Laporan transaksi',
              subtitle: 'Ringkasan penjualan, open bill, dan pengeluaran.',
              icon: Icons.analytics_outlined,
              onTap: () => _open(
                context,
                AdminTransactionReportPage(
                  checkoutRepository: checkoutRepository,
                  balancesRepository: balancesRepository,
                ),
              ),
            ),
            _ManagementTile(
              title: 'Keuangan',
              subtitle: 'Saldo, pengeluaran, dan riwayat mutasi.',
              icon: Icons.account_balance_wallet_outlined,
              onTap: () => _open(
                context,
                BalancesAdminPage(
                  repository: balancesRepository,
                  checkoutRepository: checkoutRepository,
                ),
              ),
            ),
            _ManagementTile(
              title: 'Pemantauan shift',
              subtitle: 'Lihat shift kasir dan detailnya.',
              icon: Icons.schedule_outlined,
              onTap: () =>
                  _open(context, AdminShiftsPage(repository: shiftsRepository)),
            ),
            const SizedBox(height: 20),
            Text('Katalog', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _ManagementTile(
              title: 'Produk',
              subtitle: 'Kelola menu, harga, stok, dan foto.',
              icon: Icons.inventory_2_outlined,
              onTap: () => _open(
                context,
                ProductsManagementPage(
                  repository: productManagementRepository,
                  variantGroupsRepository: variantGroupsRepository,
                ),
              ),
            ),
            _ManagementTile(
              title: 'Grup varian',
              subtitle: 'Kelola ukuran, rasa, dan opsi produk.',
              icon: Icons.tune_outlined,
              onTap: () => _open(
                context,
                VariantGroupsManagementPage(
                  repository: variantGroupsRepository,
                  productsRepository: productManagementRepository,
                ),
              ),
            ),
            _ManagementTile(
              title: 'Kategori',
              subtitle: 'Kelola kategori produk.',
              icon: Icons.category_outlined,
              onTap: () => _open(
                context,
                CategoriesManagementPage(repository: categoriesRepository),
              ),
            ),
            const SizedBox(height: 20),
            Text('Pengaturan', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _ManagementTile(
              title: 'Pengaturan toko',
              subtitle: 'Identitas, biaya, logo, dan penutupan shift.',
              icon: Icons.storefront_outlined,
              onTap: () => _open(
                context,
                StoreSettingsPage(
                  repository: storeSettingsRepository,
                  apiBaseUrl: apiBaseUrl,
                ),
              ),
            ),
            _ManagementTile(
              title: 'Pengaturan kasir',
              subtitle: 'Kelola pengguna kasir dan PIN.',
              icon: Icons.manage_accounts_outlined,
              onTap: () => _open(
                context,
                AdminUsersPage(
                  admin: admin,
                  repository: userManagementRepository,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Akun', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: Text(admin.name),
                subtitle: Text('${admin.email} · ${admin.role}'),
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.logout_outlined,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Keluar',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                subtitle: const Text('Keluar dari akun Kawula POS ini.'),
                onTap: context.read<AuthCubit>().logout,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _ManagementTile extends StatelessWidget {
  const _ManagementTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
