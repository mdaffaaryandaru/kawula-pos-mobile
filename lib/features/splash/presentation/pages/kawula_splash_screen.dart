import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class KawulaSplashScreen extends StatefulWidget {
  const KawulaSplashScreen({super.key, required this.child});

  final Widget child;

  @override
  State<KawulaSplashScreen> createState() => _KawulaSplashScreenState();
}

class _KawulaSplashScreenState extends State<KawulaSplashScreen> {
  static const _backgroundColor = Color(0xFFFFFCF8);

  Timer? _timer;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _isVisible = false);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
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
                    'assets/splash/Splash_up.png',
                    width: illustrationSize,
                    height: illustrationSize,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: Image.asset(
                    'assets/splash/Splash_bot.png',
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
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
