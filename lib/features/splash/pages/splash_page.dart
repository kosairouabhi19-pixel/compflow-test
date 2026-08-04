import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final logoSize = size.shortestSide * 0.22;
    final clampedLogoSize = logoSize.clamp(72.0, 140.0);
  Future.microtask(() {
    context.go('/home');
  });
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: clampedLogoSize,
                height: clampedLogoSize,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(clampedLogoSize * 0.28),
                ),
                alignment: Alignment.center,
                child: Text(
                  'C',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: clampedLogoSize * 0.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'CompFlow',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}