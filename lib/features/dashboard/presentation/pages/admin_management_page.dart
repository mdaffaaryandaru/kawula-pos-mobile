import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../balances/domain/repositories/balances_repository.dart';
import '../../../balances/presentation/pages/balances_admin_page.dart';
import '../../../categories/domain/repositories/categories_repository.dart';
import '../../../discounts/domain/repositories/discounts_repository.dart';
import '../../../discounts/presentation/pages/discounts_management_page.dart';
import '../../../categories/presentation/pages/categories_management_page.dart';
import '../../../products/domain/repositories/product_management_repository.dart';
import '../../../products/domain/repositories/catalog_repository.dart';
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
import '../../../inventories/domain/repositories/inventory_repository.dart';
import '../../../inventories/presentation/pages/inventories_management_page.dart';
import '../../../product_units/domain/repositories/product_units_repository.dart';
import '../../../product_units/presentation/pages/product_units_management_page.dart';
import '../../../payment_method/domain/repositories/payment_methods_repository.dart';
import '../../../payment_method/presentation/pages/payment_methods_management_page.dart';
import '../../../outlets/domain/repositories/outlets_repository.dart';
import '../../../outlets/presentation/pages/outlets_management_page.dart';
import '../../../table_areas/domain/repositories/table_areas_repository.dart';
import '../../../table_areas/presentation/pages/table_areas_management_page.dart';
import '../../../tables/domain/repositories/tables_repository.dart';
import '../../../tables/presentation/pages/tables_management_page.dart';
import '../../../members/domain/repositories/members_repository.dart';
import '../../../members/presentation/pages/members_management_page.dart';
import '../../../members/presentation/pages/membership_program_page.dart';

class AdminManagementPage extends StatelessWidget {
  const AdminManagementPage({
    super.key,
    required this.admin,
    required this.apiBaseUrl,
    required this.userManagementRepository,
    required this.productManagementRepository,
    required this.catalogRepository,
    required this.categoriesRepository,
    required this.balancesRepository,
    required this.storeSettingsRepository,
    required this.checkoutRepository,
    required this.shiftsRepository,
    required this.variantGroupsRepository,
    this.discountsRepository,
    this.paymentMethodsRepository,
    this.inventoryRepository,
    this.productUnitsRepository,
    this.outletsRepository,
    this.tableAreasRepository,
    this.tablesRepository,
    this.membersRepository,
  });

  final AuthUser admin;
  final String apiBaseUrl;
  final UserManagementRepository userManagementRepository;
  final ProductManagementRepository productManagementRepository;
  final CatalogRepository catalogRepository;
  final CategoriesRepository categoriesRepository;
  final BalancesRepository balancesRepository;
  final StoreSettingsRepository storeSettingsRepository;
  final CheckoutRepository checkoutRepository;
  final AdminShiftsRepository shiftsRepository;
  final VariantGroupsRepository variantGroupsRepository;
  final DiscountsRepository? discountsRepository;
  final PaymentMethodsRepository? paymentMethodsRepository;
  final InventoryRepository? inventoryRepository;
  final ProductUnitsRepository? productUnitsRepository;
  final OutletsRepository? outletsRepository;
  final TableAreasRepository? tableAreasRepository;
  final TablesRepository? tablesRepository;
  final MembersRepository? membersRepository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'KATALOG & PENJUALAN',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (inventoryRepository != null && productUnitsRepository != null)
              _ManagementTile(
                title: 'Inventaris',
                subtitle: 'Kelola bahan, satuan, stok, dan riwayat mutasi.',
                icon: Icons.inventory_outlined,
                onTap: () => _open(
                  context,
                  InventoriesManagementPage(
                    repository: inventoryRepository!,
                    productUnitsRepository: productUnitsRepository!,
                  ),
                ),
              ),
            _ManagementTile(
              title: 'Produk',
              subtitle: 'Kelola menu, harga, stok, dan foto.',
              icon: Icons.inventory_2_outlined,
              onTap: () => _open(
                context,
                ProductsManagementPage(
                  repository: productManagementRepository,
                  variantGroupsRepository: variantGroupsRepository,
                  discountsRepository: discountsRepository,
                ),
              ),
            ),
            _ManagementTile(
              title: 'Grup Varian',
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
            const SizedBox(height: 20),
            Text('MASTER DATA', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _ManagementTile(
              title: 'Kategori',
              subtitle: 'Kelola kategori produk.',
              icon: Icons.category_outlined,
              onTap: () => _open(
                context,
                CategoriesManagementPage(repository: categoriesRepository),
              ),
            ),
            if (discountsRepository != null)
              _ManagementTile(
                title: 'Diskon',
                subtitle: 'Kelola diskon persentase dan nominal.',
                icon: Icons.percent_outlined,
                onTap: () => _open(
                  context,
                  DiscountsManagementPage(repository: discountsRepository!),
                ),
              ),
            if (paymentMethodsRepository != null)
              _ManagementTile(
                title: 'Metode Pembayaran',
                subtitle: 'Kelola nama, kode, dan status opsi pembayaran.',
                icon: Icons.payments_outlined,
                onTap: () => _open(
                  context,
                  PaymentMethodsManagementPage(
                    repository: paymentMethodsRepository!,
                  ),
                ),
              ),
            if (productUnitsRepository != null)
              _ManagementTile(
                title: 'Satuan Produk',
                subtitle: 'Kelola nama, singkatan, dan status satuan produk.',
                icon: Icons.straighten_outlined,
                onTap: () => _open(
                  context,
                  ProductUnitsManagementPage(
                    repository: productUnitsRepository!,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              'AREA & OUTLET',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (outletsRepository != null) ...[
              _ManagementTile(
                title: 'Outlet',
                subtitle: 'Kelola outlet/cabang operasional cafe.',
                icon: Icons.storefront_outlined,
                onTap: () => _open(
                  context,
                  OutletsManagementPage(repository: outletsRepository!),
                ),
              ),
              if (tableAreasRepository != null)
                _ManagementTile(
                  title: 'Area',
                  subtitle: 'Kelola area/zona meja pada setiap outlet.',
                  icon: Icons.table_bar_outlined,
                  onTap: () => _open(
                    context,
                    TableAreasManagementPage(
                      repository: tableAreasRepository!,
                      outletsRepository: outletsRepository!,
                    ),
                  ),
                ),
              if (tablesRepository != null &&
                  tableAreasRepository != null &&
                  outletsRepository != null)
                _ManagementTile(
                  title: 'Meja',
                  subtitle: 'Kelola nomor meja, kapasitas, dan ketersediaan.',
                  icon: Icons.table_restaurant_outlined,
                  onTap: () => _open(
                    context,
                    TablesManagementPage(
                      repository: tablesRepository!,
                      areasRepository: tableAreasRepository!,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 20),
            Text('LAPORAN', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _ManagementTile(
              title: 'Laporan Transaksi',
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
              title: 'Riwayat Shift',
              subtitle: 'Lihat shift kasir dan detailnya.',
              icon: Icons.schedule_outlined,
              onTap: () =>
                  _open(context, AdminShiftsPage(repository: shiftsRepository)),
            ),
            const SizedBox(height: 20),
            Text(
              'ADMINISTRASI',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _ManagementTile(
              title: 'Pengguna',
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
            if (membersRepository != null)
              _ManagementTile(
                title: 'Member',
                subtitle: 'Kelola data pelanggan.',
                icon: Icons.people_outline,
                onTap: () => _open(
                  context,
                  MembersManagementPage(repository: membersRepository!),
                ),
              ),
            _ManagementTile(
              title: 'Keuangan & Saldo',
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
            if (membersRepository != null && discountsRepository != null)
              _ManagementTile(
                title: 'Program Membership',
                subtitle: 'Atur target stamp dan reward member.',
                icon: Icons.card_giftcard_outlined,
                onTap: () => _open(
                  context,
                  MembershipProgramPage(
                    membersRepository: membersRepository!,
                    catalogRepository: catalogRepository,
                    discountsRepository: discountsRepository!,
                  ),
                ),
              ),
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
                subtitle: const Text('Keluar dari akun Kawula ini.'),
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
