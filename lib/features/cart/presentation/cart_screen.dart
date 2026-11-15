import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/common_widgets.dart';

final cartProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/cart');
  return response.data as Map<String, dynamic>;
});

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          cartAsync.value != null
              ? TextButton(
                  onPressed: () async {
                    final dio = ref.read(dioProvider);
                    try {
                      await dio.delete('/cart');
                      ref.invalidate(cartProvider);
                    } catch (_) {}
                  },
                  child: const Text('Clear', style: TextStyle(color: Colors.white)),
                )
              : const SizedBox.shrink(),
        ],
      ),
      body: cartAsync.when(
        loading: () => const LoadingOverlay(),
        error: (e, _) => ErrorRetry(message: e.toString(), onRetry: () => ref.invalidate(cartProvider)),
        data: (body) {
          final items = (body['data']?['items'] as List?) ?? [];
          final total = (body['data']?['total_local'] as num?)?.toDouble() ?? 0;
          final currency = body['data']?['currency'] as String? ?? 'NGN';

          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              subtitle: 'Browse products or import a link to get started',
              actionLabel: 'Browse Products',
              onAction: () => context.push('/products'),
            );
          }

          return Column(children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i] as Map<String, dynamic>;
                  return _CartItemTile(item: item, onChanged: () => ref.invalidate(cartProvider));
                },
              ),
            ),
            // Checkout bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
              ),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Total', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    PriceDisplay(amount: total, currency: currency,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ]),
                ),
                ElevatedButton(
                  onPressed: () => context.push('/checkout'),
                  child: const Text('Checkout'),
                ),
              ]),
            ),
          ]);
        },
      ),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  final Map<String, dynamic> item;
  final VoidCallback onChanged;

  const _CartItemTile({required this.item, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemId = item['id'] as int;
    final title = item['title'] as String? ?? 'Product';
    final image = item['image'] as String?;
    final quantity = item['quantity'] as int? ?? 1;
    final lineTotal = (item['line_total_local'] as num?)?.toDouble() ?? 0;
    final currency = item['currency'] as String? ?? 'NGN';
    final variant = item['selected_variant'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: image != null
                ? Image.network(image, width: 72, height: 72, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 72, height: 72, color: AppColors.surfaceVariant))
                : Container(width: 72, height: 72, color: AppColors.surfaceVariant,
                    child: const Icon(Icons.image_outlined)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              if (variant != null) ...[
                const SizedBox(height: 4),
                Text(variant, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                PriceDisplay(amount: lineTotal, currency: currency),
                Row(children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 18),
                    onPressed: quantity > 1 ? () => _updateQty(ref, itemId, quantity - 1) : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w600)),
                  IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: () => _updateQty(ref, itemId, quantity + 1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                    onPressed: () => _remove(ref, itemId),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ]),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Future<void> _updateQty(WidgetRef ref, int itemId, int qty) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/cart/$itemId', data: {'quantity': qty});
      onChanged();
    } catch (_) {}
  }

  Future<void> _remove(WidgetRef ref, int itemId) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.delete('/cart/$itemId');
      onChanged();
    } catch (_) {}
  }
}
