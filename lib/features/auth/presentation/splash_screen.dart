import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../data/auth_repository.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    final auth = ref.read(authStateProvider);
    context.go(auth.isAuthenticated ? '/' : '/auth/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          // Animated logo
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: const Center(
                child: Text('BYB',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.primary)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(AppConstants.appName,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 2)),
          const SizedBox(height: 8),
          const Text('Shop from China · Delivered to West Africa',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 48),
          const SizedBox(width: 32, height: 32,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white70)),
        ]),
      ),
    );
  }
}
