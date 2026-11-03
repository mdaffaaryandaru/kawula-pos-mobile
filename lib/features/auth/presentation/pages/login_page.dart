// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:kawula_pos/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:kawula_pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:kawula_pos/features/auth/presentation/widgets/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key, this.errorMessage});

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) => LoginForm(
        isLoading: state is AuthSubmitting,
        errorMessage: errorMessage,
        onSubmit: ({required email, required password}) =>
            context.read<AuthCubit>().login(email: email, password: password),
      ),
    );
  }
}
