import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class OrderPlacedScreen extends StatelessWidget {
  final int orderId;
  const OrderPlacedScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, size: 60, color: AppColors.success),
              ),
              const SizedBox(height: 24),
              Text('Order Placed!', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              const Text(
                'Your order has been placed and payment deducted from your wallet.\n\nWe will start procuring your goods shortly. You will be notified when your goods arrive at our China warehouse.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.6),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go('/orders/$orderId'),
                child: const Text('Track Order'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/'),
                child: const Text('Continue Shopping'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
