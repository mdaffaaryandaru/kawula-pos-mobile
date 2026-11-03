// Dart imports:
import 'dart:math' as math;

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:kawula_pos/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:kawula_pos/features/auth/presentation/bloc/auth_state.dart';

class KawulaSplashScreen extends StatefulWidget {
  const KawulaSplashScreen({super.key, required this.child});

  final Widget child;

  @override
  State<KawulaSplashScreen> createState() => _KawulaSplashScreenState();
}

class _KawulaSplashScreenState extends State<KawulaSplashScreen>
    with SingleTickerProviderStateMixin {
  static const _backgroundColor = Color(0xFFFFFCF8);
  static const _progressColor = Color(0xFF8B5E3C);
  static const _progressTrackColor = Color(0xFFE9DED2);
  static const _splashDuration = Duration(milliseconds: 3000);

  late final AnimationController _splashController;
  bool _isVisible = true;
  late bool _hasResolvedInitialAuth;

  @override
  void initState() {
    super.initState();
    _hasResolvedInitialAuth = context.read<AuthCubit>().state is! AuthChecking;
    _splashController = AnimationController(
      vsync: this,
      duration: _splashDuration,
    )..addStatusListener(_handleSplashAnimationStatus);
    _splashController.forward();
  }

  void _handleSplashAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _isVisible = false);
    }
  }

  @override
  void dispose() {
    _splashController
      ..removeStatusListener(_handleSplashAnimationStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (!_hasResolvedInitialAuth && state is! AuthChecking) {
          setState(() => _hasResolvedInitialAuth = true);
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final isCheckingInitialAuth =
              !_hasResolvedInitialAuth && state is AuthChecking;
          if (!_isVisible && !isCheckingInitialAuth) {
            return widget.child;
          }

          return Scaffold(
            backgroundColor: _backgroundColor,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final illustrationSize = constraints.maxWidth;
                  final logoSize = math.min(
                    constraints.maxWidth * 0.68,
                    constraints.maxHeight * 0.36,
                  );

                  return Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 0,
                        child: Image.asset(
                          'assets/splash/splash_top.png',
                          width: illustrationSize,
                          height: illustrationSize,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        child: Image.asset(
                          'assets/splash/splash_bottom.png',
                          width: illustrationSize,
                          height: illustrationSize,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/splash/splash_center.png',
                            width: logoSize,
                            height: logoSize,
                            fit: BoxFit.contain,
                          ),
                          if (_isVisible || isCheckingInitialAuth) ...[
                            const SizedBox(height: 24),
                            SizedBox(
                              width: 160,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: const LinearProgressIndicator(
                                  minHeight: 5,
                                  color: _progressColor,
                                  backgroundColor: _progressTrackColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
