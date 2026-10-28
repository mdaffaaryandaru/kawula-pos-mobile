import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../theme/app_colors.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../shifts/domain/entities/active_shift.dart';
import '../../../shifts/presentation/bloc/shifts_cubit.dart';
import '../../../shifts/presentation/bloc/shifts_state.dart';
import '../../../transactions/domain/entities/checkout.dart';
import '../../../transactions/domain/repositories/checkout_repository.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({
    super.key,
    required this.admin,
    required this.checkoutRepository,
    required this.onOpenCashier,
    required this.onOpenReport,
    required this.onOpenManagement,
  });

  final AuthUser admin;
  final CheckoutRepository checkoutRepository;
  final VoidCallback onOpenCashier;
  final VoidCallback onOpenReport;
  final VoidCallback onOpenManagement;

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
            tooltip: 'Menu admin',
            onSelected: (value) {
              if (value == 'management') {
                widget.onOpenManagement();
              } else if (value == 'account') {
                _showAccountDetails(context);
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
                    _DashboardHeading(admin: widget.admin),
                    const SizedBox(height: 22),
                    FutureBuilder<List<TransactionRecord>>(
                      future: _transactions,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return _DashboardLoadError(
                            message:
                                'Data transaksi gagal dimuat: '
                                '${snapshot.error}',
                            onRetry: _refresh,
                          );
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const _MetricsLoading();
                        }
                        final records = snapshot.data ?? const [];
                        final today = _todayTransactions(records);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _MetricsGrid(
                              metrics: _metricsFor(today, records),
                              availableWidth: constraints.maxWidth,
                              onTap: widget.onOpenReport,
                            ),
                            const SizedBox(height: 20),
                            _ShiftStatusBanner(
                              onOpenCashier: widget.onOpenCashier,
                            ),
                            const SizedBox(height: 20),
                            _DashboardActions(
                              onManageShift: widget.onOpenCashier,
                              onNewTransaction: widget.onOpenCashier,
                              onOpenReport: widget.onOpenReport,
                            ),
                            const SizedBox(height: 28),
                            _RecentTransactions(
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

  List<_DashboardMetric> _metricsFor(
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
      _DashboardMetric(
        label: 'Pendapatan Hari Ini',
        value: _formatRupiah(totalSales),
        icon: Icons.attach_money_rounded,
        color: AppColors.primary,
        tint: const Color(0xFFEAF1FF),
        detail: '${completed.length} transaksi selesai',
      ),
      _DashboardMetric(
        label: 'Transaksi Selesai',
        value: '${completed.length}',
        icon: Icons.shopping_cart_outlined,
        color: AppColors.success,
        tint: const Color(0xFFE8FBF3),
        detail: 'Hari ini',
      ),
      _DashboardMetric(
        label: 'Open Bill Aktif',
        value: '$pending',
        icon: Icons.receipt_long_outlined,
        color: AppColors.warning,
        tint: const Color(0xFFFFF6E5),
        detail: 'Menunggu pembayaran',
      ),
      _DashboardMetric(
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

class _DashboardHeading extends StatelessWidget {
  const _DashboardHeading({required this.admin});

  final AuthUser admin;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = switch (now.hour) {
      < 11 => 'Selamat pagi',
      < 15 => 'Selamat siang',
      < 18 => 'Selamat sore',
      _ => 'Selamat malam',
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, ${admin.name}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Berikut ringkasan aktivitas tokomu hari ini.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        if (MediaQuery.sizeOf(context).width > 520)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(now),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({
    required this.metrics,
    required this.availableWidth,
    required this.onTap,
  });

  final List<_DashboardMetric> metrics;
  final double availableWidth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final contentWidth = availableWidth >= 700
        ? availableWidth - 56
        : availableWidth - 32;
    final columns = contentWidth >= 1100
        ? 4
        : contentWidth >= 560
        ? 2
        : 1;
    const spacing = 14.0;
    final cardWidth = (contentWidth - spacing * (columns - 1)) / columns;
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: metrics
          .map(
            (metric) => SizedBox(
              width: cardWidth,
              child: _MetricCard(metric: metric, onTap: onTap),
            ),
          )
          .toList(),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric, required this.onTap});

  final _DashboardMetric metric;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 152),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x080F172A),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: metric.tint,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(metric.icon, color: metric.color, size: 22),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 17,
                    color: metric.color,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (context, progress, child) => Opacity(
                  opacity: progress,
                  child: Transform.translate(
                    offset: Offset(0, 8 * (1 - progress)),
                    child: child,
                  ),
                ),
                child: Text(
                  metric.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                metric.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                metric.detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: metric.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShiftStatusBanner extends StatelessWidget {
  const _ShiftStatusBanner({required this.onOpenCashier});

  final VoidCallback onOpenCashier;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShiftsCubit, ShiftsState>(
      builder: (context, state) => switch (state) {
        ShiftsLoading() => const _BannerShell(
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Memeriksa status shift...'),
            ],
          ),
        ),
        ShiftsActive() => _ActiveShiftBanner(
          shift: state.shift,
          onOpenCashier: onOpenCashier,
        ),
        ShiftsNeedsOpening() => _BannerShell(
          child: Row(
            children: [
              const _StatusDot(color: AppColors.warning),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Belum ada shift aktif',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Buka shift untuk mulai bertransaksi.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onOpenCashier,
                child: const Text('Buka shift'),
              ),
            ],
          ),
        ),
        ShiftsOpening() => const _BannerShell(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            title: Text('Shift sedang dibuka'),
          ),
        ),
        ShiftsClosing() => const _BannerShell(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            title: Text('Shift sedang ditutup'),
          ),
        ),
        ShiftsClosed() => _BannerShell(
          child: Row(
            children: [
              const _StatusDot(color: AppColors.textSecondary),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Shift sudah ditutup',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: context.read<ShiftsCubit>().loadActive,
                child: const Text('Perbarui'),
              ),
            ],
          ),
        ),
        ShiftsFailure() => _BannerShell(
          child: Row(
            children: [
              const Icon(Icons.cloud_off_outlined, color: AppColors.danger),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Status shift belum tersedia: ${state.message}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Coba periksa shift lagi',
                onPressed: context.read<ShiftsCubit>().loadActive,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ),
      },
    );
  }
}

class _ActiveShiftBanner extends StatelessWidget {
  const _ActiveShiftBanner({required this.shift, required this.onOpenCashier});

  final ActiveShift shift;
  final VoidCallback onOpenCashier;

  @override
  Widget build(BuildContext context) {
    return _BannerShell(
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const _StatusDot(color: AppColors.success),
          const Text(
            'Shift Aktif',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${shift.outletName ?? 'Outlet'} · '
            'Modal awal ${_formatRupiah(shift.startingCash)} · '
            '${shift.totalTransactions} transaksi',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          OutlinedButton(
            onPressed: onOpenCashier,
            child: const Text('Kelola Shift'),
          ),
        ],
      ),
    );
  }
}

class _DashboardActions extends StatelessWidget {
  const _DashboardActions({
    required this.onManageShift,
    required this.onNewTransaction,
    required this.onOpenReport,
  });

  final VoidCallback onManageShift;
  final VoidCallback onNewTransaction;
  final VoidCallback onOpenReport;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _DashboardAction(
        label: 'Kelola Shift',
        icon: Icons.sync_alt_rounded,
        color: AppColors.primary,
        onTap: onManageShift,
      ),
      _DashboardAction(
        label: 'Transaksi Baru · Buka Kasir',
        icon: Icons.point_of_sale_rounded,
        color: AppColors.success,
        onTap: onNewTransaction,
      ),
      _DashboardAction(
        label: 'Riwayat Hari Ini',
        icon: Icons.trending_up_rounded,
        color: AppColors.navy,
        onTap: onOpenReport,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final width = constraints.maxWidth;
        final columns = width >= 720
            ? 3
            : width >= 480
            ? 2
            : 1;
        final cardWidth = (width - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: actions
              .map(
                (action) => SizedBox(
                  width: cardWidth,
                  child: _ActionCard(action: action),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action});

  final _DashboardAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: action.color,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: action.color.withValues(alpha: .22),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          child: Row(
            children: [
              Icon(action.icon, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  action.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white70,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions({
    required this.transactions,
    required this.availableWidth,
    required this.onOpenReport,
  });

  final List<TransactionRecord> transactions;
  final double availableWidth;
  final VoidCallback onOpenReport;

  @override
  Widget build(BuildContext context) {
    final isWide = availableWidth >= 850;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Transaksi Terbaru',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: onOpenReport,
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (transactions.isEmpty)
          const _EmptyTransactions()
        else
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(18),
            ),
            child: isWide
                ? _TransactionTable(transactions: transactions)
                : Column(
                    children: [
                      for (
                        var index = 0;
                        index < transactions.length;
                        index++
                      ) ...[
                        _TransactionCard(transaction: transactions[index]),
                        if (index != transactions.length - 1)
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      ],
                    ],
                  ),
          ),
      ],
    );
  }
}

class _TransactionTable extends StatelessWidget {
  const _TransactionTable({required this.transactions});

  final List<TransactionRecord> transactions;

  @override
  Widget build(BuildContext context) {
    final headerStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w700,
      letterSpacing: .6,
    );
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.3),
        1: FlexColumnWidth(1.0),
        2: FlexColumnWidth(1.2),
        3: FlexColumnWidth(1.0),
        4: FlexColumnWidth(1.0),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFF9FAFC)),
          children: [
            _TableCell('ID TRANSAKSI', style: headerStyle),
            _TableCell('ITEM', style: headerStyle),
            _TableCell('TOTAL', style: headerStyle),
            _TableCell('STATUS', style: headerStyle),
            _TableCell('WAKTU', style: headerStyle),
          ],
        ),
        for (final transaction in transactions)
          TableRow(
            children: [
              _TableCell(_shortId(transaction.id)),
              _TableCell('${_itemCount(transaction)} item'),
              _TableCell(
                _formatRupiah(transaction.totalAmount),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              _TableCell.child(
                child: _TransactionStatus(status: transaction.status),
              ),
              _TableCell.child(
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(_formatTime(transaction.createdAt)),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell(this.text, {this.style}) : child = null;

  const _TableCell.child({required this.child}) : text = null, style = null;

  final String? text;
  final TextStyle? style;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    child:
        child ??
        Text(
          text ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style ?? const TextStyle(color: AppColors.textSecondary),
        ),
  );
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction});

  final TransactionRecord transaction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.dashboardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _shortId(transaction.id),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _TransactionStatus(status: transaction.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_itemCount(transaction)} item · '
                  '${_formatTime(transaction.createdAt)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatRupiah(transaction.totalAmount),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionStatus extends StatelessWidget {
  const _TransactionStatus({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = status.toLowerCase();
    final color = switch (normalizedStatus) {
      'completed' => AppColors.success,
      'pending' => AppColors.warning,
      'refunded' || 'cancelled' => AppColors.danger,
      _ => AppColors.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        _statusLabel(normalizedStatus),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetricsLoading extends StatelessWidget {
  const _MetricsLoading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 36),
    child: Center(child: CircularProgressIndicator()),
  );
}

class _DashboardLoadError extends StatelessWidget {
  const _DashboardLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppColors.danger),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    ),
  );
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Column(
      children: [
        Icon(
          Icons.receipt_long_outlined,
          size: 32,
          color: AppColors.textSecondary,
        ),
        SizedBox(height: 8),
        Text(
          'Belum ada transaksi hari ini.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _BannerShell extends StatelessWidget {
  const _BannerShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: color.withValues(alpha: .2), blurRadius: 7)],
    ),
  );
}

class _DashboardMetric {
  const _DashboardMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.tint,
    required this.detail,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color tint;
  final String detail;
}

class _DashboardAction {
  const _DashboardAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty);
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}

String _formatRupiah(num amount) {
  final digits = amount.round().abs().toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return '${amount < 0 ? '- ' : ''}Rp $grouped';
}

String _formatTime(DateTime? time) {
  if (time == null) return '--:--';
  final localTime = time.toLocal();
  return '${localTime.hour.toString().padLeft(2, '0')}:'
      '${localTime.minute.toString().padLeft(2, '0')}';
}

String _formatDate(DateTime date) {
  const months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _shortId(String id) => id.length > 6
    ? id.substring(id.length - 6).toUpperCase()
    : id.toUpperCase();

int _itemCount(TransactionRecord transaction) =>
    transaction.items.fold<int>(0, (total, item) => total + item.quantity);

String _statusLabel(String status) => switch (status) {
  'completed' => 'Selesai',
  'pending' => 'Open bill',
  'refunded' => 'Refund',
  'cancelled' => 'Dibatalkan',
  _ => status,
};
