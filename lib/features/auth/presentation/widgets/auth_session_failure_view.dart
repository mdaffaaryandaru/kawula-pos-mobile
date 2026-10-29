import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_cubit.dart';

class AuthSessionFailureView extends StatelessWidget {
  const AuthSessionFailureView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Sesi belum dapat diperiksa',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: context.read<AuthCubit>().restoreSession,
                child: const Text('Coba lagi'),
              ),
              TextButton(
                onPressed: context.read<AuthCubit>().logout,
                child: const Text('Keluar dari sesi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
