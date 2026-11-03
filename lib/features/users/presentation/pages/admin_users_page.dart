// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/users/domain/repositories/user_management_repository.dart';
import 'package:kawula_pos/features/users/presentation/bloc/user_management_cubit.dart';
import 'package:kawula_pos/features/users/presentation/widgets/admin_users_list.dart';
import 'package:kawula_pos/features/users/presentation/widgets/user_form_dialog.dart';
import 'package:kawula_pos/framework/widgets/master_data_feedback.dart';
import 'package:kawula_pos/framework/widgets/master_data_row_actions.dart';

class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({
    super.key,
    required this.admin,
    required this.repository,
  });

  final AuthUser admin;
  final UserManagementRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UserManagementCubit(repository)..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Users')),
        body: BlocBuilder<UserManagementCubit, UserManagementState>(
          builder: (context, state) => switch (state) {
            UserManagementLoading() => const MasterDataLoadingState(),
            UserManagementFailure() => MasterDataErrorState(
              title: 'Daftar pengguna belum dapat dimuat.',
              message: state.message,
              onRetry: context.read<UserManagementCubit>().load,
            ),
            UserManagementLoaded() => _users(context, state),
          },
        ),
      ),
    );
  }

  Widget _users(BuildContext context, UserManagementLoaded state) {
    return AdminUsersList(
      users: state.users,
      errorMessage: state.errorMessage,
      onRefresh: context.read<UserManagementCubit>().load,
      onAdd: () => _editUser(context),
      onEdit: (user) => _editUser(context, user: user),
      onDelete: (user) => _deleteUser(context, user),
    );
  }

  Future<void> _editUser(BuildContext context, {AuthUser? user}) async {
    final draft = await showDialog<UserDraft>(
      context: context,
      builder: (_) => UserFormDialog(user: user),
    );
    if (draft == null || !context.mounted) return;
    final saved = await context.read<UserManagementCubit>().saveUser(
      userId: user?.id,
      name: draft.name,
      email: draft.email,
      password: draft.password,
      pin: draft.pin,
      role: draft.role,
    );
    if (saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            user == null
                ? 'User berhasil ditambahkan.'
                : 'User ${user.name} berhasil diperbarui.',
          ),
        ),
      );
    }
  }

  Future<void> _deleteUser(BuildContext context, AuthUser user) async {
    final confirmed = await MasterDataDeleteConfirmation.show(
      context,
      title: 'Hapus user?',
      message: 'Akun ${user.name} (${user.email}) akan dihapus.',
    );
    if (confirmed != true || !context.mounted) return;
    final deleted = await context.read<UserManagementCubit>().deleteUser(
      user.id,
    );
    if (deleted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ${user.name} berhasil dihapus.')),
      );
    }
  }
}
