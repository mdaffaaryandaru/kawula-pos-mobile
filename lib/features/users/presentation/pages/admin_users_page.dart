import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../domain/repositories/user_management_repository.dart';
import '../bloc/user_management_cubit.dart';

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
        appBar: AppBar(
          title: const Text('Pengaturan kasir'),
          actions: [
            IconButton(
              onPressed: context.read<AuthCubit>().logout,
              tooltip: 'Keluar',
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: BlocBuilder<UserManagementCubit, UserManagementState>(
          builder: (context, state) => switch (state) {
            UserManagementLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            UserManagementFailure() => _loadFailure(context, state.message),
            UserManagementLoaded() => _users(context, state),
          },
        ),
      ),
    );
  }

  Widget _users(BuildContext context, UserManagementLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, ${admin.name}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              const Text(
                'Atur PIN 4 digit pengguna. PIN hanya dikirim untuk disimpan backend dan tidak ditampilkan kembali.',
              ),
            ],
          ),
        ),
        if (state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _ErrorBanner(message: state.errorMessage!),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: context.read<UserManagementCubit>().load,
            child: state.users.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 80),
                      Center(child: Text('Belum ada pengguna.')),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: state.users.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final user = state.users[index];
                      return _UserCard(
                        user: user,
                        onSetPin: () => _setPin(context, user),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _loadFailure(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Daftar pengguna belum dapat dimuat',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: context.read<UserManagementCubit>().load,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setPin(BuildContext context, AuthUser user) async {
    final pin = await showDialog<String>(
      context: context,
      builder: (_) => _SetPinDialog(userName: user.name),
    );
    if (pin == null || !context.mounted) return;
    await context.read<UserManagementCubit>().updatePin(
      userId: user.id,
      pin: pin,
    );
    if (!context.mounted) return;
    final state = context.read<UserManagementCubit>().state;
    if (state is UserManagementLoaded && state.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PIN untuk ${user.name} berhasil diperbarui.')),
      );
    }
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.onSetPin});

  final AuthUser user;
  final VoidCallback onSetPin;

  @override
  Widget build(BuildContext context) {
    final hasPin = user.hasPin;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            user.role == 'Admin'
                ? Icons.admin_panel_settings
                : Icons.point_of_sale,
          ),
        ),
        title: Text(user.name),
        subtitle: Text(
          '${user.email}\n${user.role} · PIN ${hasPin ? 'sudah diatur' : 'belum diatur'}',
        ),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: hasPin ? 'Ubah PIN ${user.name}' : 'Atur PIN ${user.name}',
          onPressed: onSetPin,
          icon: const Icon(Icons.pin_outlined),
        ),
      ),
    );
  }
}

class _SetPinDialog extends StatefulWidget {
  const _SetPinDialog({required this.userName});

  final String userName;

  @override
  State<_SetPinDialog> createState() => _SetPinDialogState();
}

class _SetPinDialogState extends State<_SetPinDialog> {
  final _pinController = TextEditingController();
  final _confirmationController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Atur PIN · ${widget.userName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _pinController,
              autofocus: true,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: const InputDecoration(labelText: 'PIN baru'),
            ),
            TextField(
              controller: _confirmationController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: const InputDecoration(labelText: 'Ulangi PIN'),
            ),
            if (_errorMessage != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            final pin = _pinController.text;
            if (pin.length != 4) {
              setState(() => _errorMessage = 'PIN harus tepat 4 digit.');
              return;
            }
            if (pin != _confirmationController.text) {
              setState(() => _errorMessage = 'Konfirmasi PIN tidak sama.');
              return;
            }
            Navigator.pop(context, pin);
          },
          child: const Text('Simpan PIN'),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

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
