import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/common_widgets.dart';

final transactionsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/wallet/transactions');
  final body = response.data as Map<String, dynamic>;
  return (body['data'] as List?) ?? [];
});

class WalletTransactionsScreen extends ConsumerWidget {
  const WalletTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History')),
      body: txnAsync.when(
        loading: () => const LoadingOverlay(),
        error: (e, _) => ErrorRetry(message: e.toString(), onRetry: () => ref.invalidate(transactionsProvider)),
        data: (txns) => txns.isEmpty
            ? const EmptyState(icon: Icons.receipt_outlined, title: 'No transactions yet')
            : ListView.separated(
                itemCount: txns.length,
                separatorBuilder: (_, __) => const Divider(height: 0, indent: 72),
                itemBuilder: (_, i) {
                  final t = txns[i] as Map<String, dynamic>;
                  final isCredit = t['type'] == 'credit';
                  final amount = (t['amount'] as num).toDouble();
                  final currency = t['currency'] as String? ?? 'NGN';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (isCredit ? AppColors.success : AppColors.error).withOpacity(0.1),
                      child: Icon(isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isCredit ? AppColors.success : AppColors.error),
                    ),
                    title: Text(t['description'] as String? ?? t['category'] as String? ?? '',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Balance: ${CurrencyFormatter.format((t['balance_after'] as num).toDouble(), currency)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      Text(t['created_at']?.toString().substring(0, 10) ?? '',
                          style: const TextStyle(fontSize: 11)),
                    ]),
                    trailing: Text(
                      '${isCredit ? '+' : '-'}${CurrencyFormatter.format(amount, currency)}',
                      style: TextStyle(fontWeight: FontWeight.w700, color: isCredit ? AppColors.success : AppColors.error),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
