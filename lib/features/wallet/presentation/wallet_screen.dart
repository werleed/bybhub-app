import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/common_widgets.dart';

final walletBalanceProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/wallet');
  final body = response.data as Map<String, dynamic>;
  return body['data'] as Map<String, dynamic>;
});

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletBalanceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: walletAsync.when(
        loading: () => const LoadingOverlay(),
        error: (e, _) => ErrorRetry(message: e.toString(), onRetry: () => ref.invalidate(walletBalanceProvider)),
        data: (wallet) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Balance card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF16213E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  wallet['formatted'] as String? ?? '₦0.00',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _WalletAction(icon: Icons.add, label: 'Fund', onTap: () => context.push('/wallet/fund')),
                  _WalletAction(icon: Icons.send_outlined, label: 'Transfer', onTap: () {}),
                  _WalletAction(icon: Icons.history, label: 'History', onTap: () => context.push('/wallet/transactions')),
                  _WalletAction(icon: Icons.account_balance_outlined, label: 'DVA', onTap: () {}),
                ]),
              ]),
            ),
            const SizedBox(height: 20),

            // Recent transactions
            SectionHeader(
              title: 'Recent Transactions',
              actionLabel: 'See all',
              onAction: () => context.push('/wallet/transactions'),
            ),
            const _RecentTransactions(),
          ]),
        ),
      ),
    );
  }
}

class _WalletAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _WalletAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ]),
    );
  }
}

class _RecentTransactions extends ConsumerWidget {
  const _RecentTransactions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnAsync = ref.watch(FutureProvider<List<dynamic>>((r) async {
      final dio = r.watch(dioProvider);
      final response = await dio.get('/wallet/transactions', queryParameters: {'per_page': '5'});
      final body = response.data as Map<String, dynamic>;
      return (body['data'] as List?) ?? [];
    }).future);

    return FutureBuilder<List<dynamic>>(
      future: txnAsync,
      builder: (context, snap) {
        if (!snap.hasData) return const LoadingOverlay();
        final txns = snap.data!;
        if (txns.isEmpty) {
          return const EmptyState(icon: Icons.receipt_outlined, title: 'No transactions yet');
        }
        return Column(
          children: txns.map((t) {
            final txn = t as Map<String, dynamic>;
            final isCredit = txn['type'] == 'credit';
            final amount = (txn['amount'] as num).toDouble();
            final currency = txn['currency'] as String? ?? 'NGN';
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: (isCredit ? AppColors.success : AppColors.error).withOpacity(0.1),
                child: Icon(isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isCredit ? AppColors.success : AppColors.error, size: 18),
              ),
              title: Text(txn['description'] as String? ?? txn['category'] as String? ?? '',
                  style: const TextStyle(fontSize: 13)),
              subtitle: Text(txn['created_at']?.toString().substring(0, 10) ?? ''),
              trailing: Text(
                '${isCredit ? '+' : '-'}${CurrencyFormatter.format(amount, currency)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isCredit ? AppColors.success : AppColors.error,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
