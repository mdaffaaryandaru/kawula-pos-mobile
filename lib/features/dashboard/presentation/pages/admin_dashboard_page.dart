// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:kawula_pos/features/dashboard/presentation/widgets/admin_dashboard_action_widgets.dart';
import 'package:kawula_pos/features/dashboard/presentation/widgets/admin_dashboard_models.dart';
import 'package:kawula_pos/features/dashboard/presentation/widgets/admin_dashboard_shift_widgets.dart';
import 'package:kawula_pos/features/dashboard/presentation/widgets/admin_dashboard_state_widgets.dart';
import 'package:kawula_pos/features/dashboard/presentation/widgets/admin_dashboard_summary_widgets.dart';
import 'package:kawula_pos/features/dashboard/presentation/widgets/admin_dashboard_transaction_widgets.dart';
import 'package:kawula_pos/features/shifts/presentation/bloc/shifts_cubit.dart';
import 'package:kawula_pos/features/transactions/domain/entities/checkout.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/checkout_repository.dart';
import 'package:kawula_pos/theme/app_colors.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({
    super.key,
    required this.admin,
    required this.checkoutRepository,
    required this.onOpenCashier,
    required this.onOpenReport,
    required this.onOpenManagement,
    this.isCashier = false,
  });

  final AuthUser admin;
  final CheckoutRepository checkoutRepository;
  final VoidCallback onOpenCashier;
  final VoidCallback onOpenReport;
  final VoidCallback onOpenManagement;
  final bool isCashier;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late Future<List<TransactionRecord>> _transactions;

  @override
  void initState() {
    super.initState();
    _transactions = widget.checkoutRepository.getTransactions();
  }

  Future<void> _refresh() async {
    setState(() {
      _transactions = widget.checkoutRepository.getTransactions();
    });
    context.read<ShiftsCubit>().loadActive();
    await _transactions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang dashboard',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          PopupMenuButton<String>(
            tooltip: widget.isCashier ? 'Menu akun' : 'Menu admin',
            onSelected: (value) {
              if (value == 'management') {
                widget.onOpenManagement();
              } else if (value == 'account') {
                _showAccountDetails(context);
              } else if (value == 'logout') {
                context.read<AuthCubit>().logout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'account',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: .1),
                    foregroundColor: AppColors.primary,
                    child: Text(_initials(widget.admin.name)),
                  ),
                  title: Text(widget.admin.name),
                  subtitle: Text(widget.admin.email),
                ),
              ),
              const PopupMenuDivider(),
              if (widget.isCashier)
                const PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.logout),
                    title: Text('Keluar'),
                  ),
                )
              else
                const PopupMenuItem(
                  value: 'management',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.manage_accounts_outlined),
                    title: Text('Buka Manajemen'),
                  ),
                ),
            ],
            child: Container(
              margin: const EdgeInsets.only(right: 16, left: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.dashboardBackground,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    child: Text(
                      _initials(widget.admin.name),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.admin.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          widget.admin.role,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth >= 1200
                ? 1440.0
                : constraints.maxWidth;
            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: maxWidth,
                child: ListView(
                  key: const PageStorageKey<String>('admin-dashboard-list'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth >= 700 ? 28 : 16,
                    vertical: 24,
                  ),
                  children: [
                    DashboardHeading(admin: widget.admin),
                    const SizedBox(height: 22),
                    FutureBuilder<List<TransactionRecord>>(
                      future: _transactions,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return DashboardLoadError(
                            message:
                                'Data transaksi gagal dimuat: '
                                '${snapshot.error}',
                            onRetry: _refresh,
                          );
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const MetricsLoading();
                        }
                        final records = snapshot.data ?? const [];
                        final today = _todayTransactions(records);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            MetricsGrid(
                              metrics: _metricsFor(today, records),
                              availableWidth: constraints.maxWidth,
                            ),
                            const SizedBox(height: 20),
                            ShiftStatusBanner(user: widget.admin),
                            const SizedBox(height: 20),
                            DashboardActions(
                              user: widget.admin,
                              onNewTransaction: widget.onOpenCashier,
                              onOpenReport: widget.onOpenReport,
                            ),
                            const SizedBox(height: 28),
                            RecentTransactions(
                              transactions: today.take(5).toList(),
                              availableWidth: constraints.maxWidth,
                              onOpenReport: widget.onOpenReport,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<TransactionRecord> _todayTransactions(List<TransactionRecord> records) {
    final now = DateTime.now();
    final today = records.where((record) {
      final createdAt = record.createdAt?.toLocal();
      return createdAt != null &&
          createdAt.year == now.year &&
          createdAt.month == now.month &&
          createdAt.day == now.day;
    }).toList();
    today.sort((a, b) {
      final aDate = a.createdAt;
      final bDate = b.createdAt;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    return today;
  }

  List<DashboardMetric> _metricsFor(
    List<TransactionRecord> todayTransactions,
    List<TransactionRecord> allTransactions,
  ) {
    final completed = todayTransactions
        .where((transaction) => transaction.status.toLowerCase() == 'completed')
        .toList();
    final pending = allTransactions
        .where((transaction) => transaction.isPending)
        .length;
    final totalSales = completed.fold<num>(
      0,
      (total, transaction) => total + transaction.totalAmount,
    );
    final itemsSold = completed.fold<int>(
      0,
      (total, transaction) =>
          total +
          transaction.items.fold<int>(0, (sum, item) => sum + item.quantity),
    );
    final refunds = todayTransactions
        .where((transaction) => transaction.status.toLowerCase() == 'refunded')
        .length;

    return [
      DashboardMetric(
        label: 'Pendapatan Hari Ini',
        value: formatDashboardRupiah(totalSales),
        icon: Icons.attach_money_rounded,
        color: AppColors.primary,
        tint: const Color(0xFFEAF1FF),
        detail: '${completed.length} transaksi selesai',
      ),
      DashboardMetric(
        label: 'Transaksi Selesai',
        value: '${completed.length}',
        icon: Icons.shopping_cart_outlined,
        color: AppColors.success,
        tint: const Color(0xFFE8FBF3),
        detail: 'Hari ini',
      ),
      DashboardMetric(
        label: 'Open Bill Aktif',
        value: '$pending',
        icon: Icons.receipt_long_outlined,
        color: AppColors.warning,
        tint: const Color(0xFFFFF6E5),
        detail: 'Menunggu pembayaran',
      ),
      DashboardMetric(
        label: 'Item Terjual',
        value: '$itemsSold',
        icon: Icons.inventory_2_outlined,
        color: AppColors.danger,
        tint: const Color(0xFFFFEEF0),
        detail: '$refunds transaksi refund',
      ),
    ];
  }

  void _showAccountDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary.withValues(alpha: .1),
                foregroundColor: AppColors.primary,
                child: Text(
                  _initials(widget.admin.name),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.admin.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(widget.admin.email),
              const SizedBox(height: 6),
              Chip(
                avatar: const Icon(Icons.verified_user_outlined, size: 16),
                label: Text(widget.admin.role),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty);
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}
