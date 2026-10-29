import 'package:flutter/material.dart';

import '../../../../framework/widgets/master_data_feedback.dart';
import '../../../../framework/widgets/responsive_data_table.dart';
import '../../../../framework/widgets/master_data_header.dart';
import '../../../../framework/widgets/master_data_row_actions.dart';
import '../../../../framework/widgets/master_data_search_panel.dart';
import '../../../auth/domain/entities/auth_user.dart';

class AdminUsersList extends StatefulWidget {
  const AdminUsersList({
    super.key,
    required this.users,
    required this.errorMessage,
    required this.onRefresh,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<AuthUser> users;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final VoidCallback onAdd;
  final ValueChanged<AuthUser> onEdit;
  final ValueChanged<AuthUser> onDelete;

  @override
  State<AdminUsersList> createState() => _AdminUsersListState();
}

class _AdminUsersListState extends State<AdminUsersList> {
  final _searchController = TextEditingController();
  String _query = '';
  String _roleFilter = 'Semua Role';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = widget.users
        .where((user) {
          final matchesQuery = '${user.name} ${user.email}'
              .toLowerCase()
              .contains(_query);
          return matchesQuery &&
              (_roleFilter == 'Semua Role' || user.role == _roleFilter);
        })
        .toList(growable: false);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              _header(context),
              if (widget.errorMessage != null) ...[
                const SizedBox(height: 12),
                UserManagementErrorBanner(message: widget.errorMessage!),
              ],
              const SizedBox(height: 20),
              _searchPanel(),
              const SizedBox(height: 20),
              if (widget.users.isEmpty)
                MasterDataEmptyState(
                  icon: Icons.people_outline,
                  title: 'Belum ada pengguna.',
                  message:
                      'Tambahkan akun admin atau kasir untuk mulai mengelola akses.',
                  actionLabel: 'Tambah User',
                  onAction: widget.onAdd,
                )
              else if (filteredUsers.isEmpty)
                const MasterDataEmptyState(
                  icon: Icons.search_off,
                  title: 'Pengguna tidak ditemukan.',
                  message: 'Ubah kata pencarian atau filter role.',
                )
              else
                _usersTable(filteredUsers, constraints.maxWidth),
            ],
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context) {
    return MasterDataHeader(
      title: 'Users',
      description:
          'Kelola akun admin dan kasir toko secara real-time dari API.',
      addLabel: 'Tambah User',
      onRefresh: widget.onRefresh,
      onAdd: widget.onAdd,
    );
  }

  Widget _searchPanel() {
    final role = DropdownButtonFormField<String>(
      initialValue: _roleFilter,
      isExpanded: true,
      decoration: const InputDecoration(filled: true),
      items: const [
        DropdownMenuItem(value: 'Semua Role', child: Text('Semua Role')),
        DropdownMenuItem(value: 'Admin', child: Text('Admin')),
        DropdownMenuItem(value: 'Kasir', child: Text('Kasir')),
      ],
      onChanged: (value) => setState(() => _roleFilter = value ?? 'Semua Role'),
    );
    return MasterDataSearchPanel(
      controller: _searchController,
      onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
      query: _query,
      hintText: 'Cari nama atau email...',
      trailing: role,
    );
  }

  Widget _usersTable(List<AuthUser> users, double availableWidth) {
    return ResponsiveDataTable(
      minWidth: availableWidth - 40,
      columns: const [
        DataColumn(label: Text('NAMA')),
        DataColumn(label: Text('EMAIL')),
        DataColumn(label: Text('PIN')),
        DataColumn(label: Text('ROLE')),
        DataColumn(label: Text('AKSI')),
      ],
      rows: users.map(_userRow).toList(growable: false),
    );
  }

  DataRow _userRow(AuthUser user) => DataRow(
    cells: [
      DataCell(SizedBox(width: 210, child: Text(user.name))),
      DataCell(SizedBox(width: 240, child: Text(user.email))),
      DataCell(
        Text(
          user.hasPin ? 'Telah Diatur' : 'Belum Diatur',
          style: TextStyle(
            color: user.hasPin ? Colors.teal.shade700 : Colors.orange.shade800,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      DataCell(_RoleChip(role: user.role)),
      DataCell(
        MasterDataRowActions(
          onEdit: () => widget.onEdit(user),
          onDelete: () => widget.onDelete(user),
        ),
      ),
    ],
  );

}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'Admin';
    final color = isAdmin
        ? Theme.of(context).colorScheme.primary
        : Colors.blueGrey;
    return Chip(
      avatar: Icon(
        isAdmin ? Icons.shield_outlined : Icons.person_outline,
        size: 16,
        color: color,
      ),
      label: Text(role),
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withValues(alpha: .08),
      side: BorderSide.none,
    );
  }
}

class UserManagementErrorBanner extends StatelessWidget {
  const UserManagementErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
      ),
    );
  }
}
