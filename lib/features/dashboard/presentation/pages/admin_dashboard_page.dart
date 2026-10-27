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
import '../../../transactions/domain/repositories/checkout_repository.dart';
import '../../../users/domain/repositories/user_management_repository.dart';
import '../../../users/presentation/pages/admin_users_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({
    super.key,
    required this.admin,
    required this.userManagementRepository,
    required this.productManagementRepository,
    required this.categoriesRepository,
    required this.balancesRepository,
    required this.checkoutRepository,
    required this.shiftsRepository,
  });

  final AuthUser admin;
  final UserManagementRepository userManagementRepository;
  final ProductManagementRepository productManagementRepository;
  final CategoriesRepository categoriesRepository;
  final BalancesRepository balancesRepository;
  final CheckoutRepository checkoutRepository;
  final AdminShiftsRepository shiftsRepository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: context.read<AuthCubit>().logout,
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Halo, ${admin.name}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Pilih data yang ingin dikelola.'),
          const SizedBox(height: 20),
          _DashboardFeatureCard(
            title: 'Produk',
            description: 'Kelola produk, harga, stok, varian, dan foto.',
            icon: Icons.inventory_2_outlined,
            onTap: () => _open(
              context,
              ProductsManagementPage(repository: productManagementRepository),
            ),
          ),
          _DashboardFeatureCard(
            title: 'Kategori',
            description: 'Tambah, ubah, aktifkan, atau hapus kategori.',
            icon: Icons.category_outlined,
            onTap: () => _open(
              context,
              CategoriesManagementPage(repository: categoriesRepository),
            ),
          ),
          _DashboardFeatureCard(
            title: 'Pengaturan kasir',
            description: 'Lihat pengguna dan atur PIN kasir.',
            icon: Icons.manage_accounts_outlined,
            onTap: () => _open(
              context,
              AdminUsersPage(
                admin: admin,
                repository: userManagementRepository,
              ),
            ),
          ),
          _DashboardFeatureCard(
            title: 'Keuangan',
            description: 'Lihat saldo, mutasi, catat pengeluaran, dan koreksi.',
            icon: Icons.account_balance_wallet_outlined,
            onTap: () => _open(
              context,
              BalancesAdminPage(
                repository: balancesRepository,
                checkoutRepository: checkoutRepository,
              ),
            ),
          ),
          _DashboardFeatureCard(
            title: 'Shift kasir',
            description: 'Pantau shift dan force-close jika diperlukan.',
            icon: Icons.schedule_outlined,
            onTap: () =>
                _open(context, AdminShiftsPage(repository: shiftsRepository)),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _DashboardFeatureCard extends StatelessWidget {
  const _DashboardFeatureCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: Icon(icon, size: 30),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
