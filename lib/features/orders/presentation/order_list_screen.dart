import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/common_widgets.dart';

final ordersProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, params) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/orders', queryParameters: params);
  return response.data as Map<String, dynamic>;
});

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});
  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _typeFilters = ['All', 'China', 'Local'];
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _typeFilters.length, vsync: this);
    _tabs.addListener(() { if (!_tabs.indexIsChanging) setState(() => _tabIndex = _tabs.index); });
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Map<String, dynamic> get _params => {
    if (_tabIndex == 1) 'type': 'china',
    if (_tabIndex == 2) 'type': 'local',
  };

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider(_params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        bottom: TabBar(
          controller: _tabs,
          tabs: _typeFilters.map((t) => Tab(text: t)).toList(),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppColors.secondary,
        ),
      ),
      body: ordersAsync.when(
        loading: () => const LoadingOverlay(),
        error: (e, _) => ErrorRetry(message: e.toString(), onRetry: () => ref.invalidate(ordersProvider)),
        data: (body) {
          final items = (body['data'] as List?) ?? [];
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              subtitle: 'Your orders will appear here',
              actionLabel: 'Browse Products',
              onAction: () => context.push('/products'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) => _OrderCard(order: items[i] as Map<String, dynamic>),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final orderId = order['id'] as int;
    final orderNumber = order['order_number'] as String? ?? '';
    final status = order['status'] as String? ?? 'paid';
    final statusLabel = order['status_label'] as String? ?? status;
    final total = (order['grand_total'] as num?)?.toDouble() ?? 0;
    final currency = order['currency'] as String? ?? 'NGN';
    final itemCount = order['item_count'] as int? ?? 0;
    final hasUnpaidShipping = order['has_unpaid_shipping'] as bool? ?? false;
    final canCancel = order['can_cancel'] as bool? ?? false;
    final createdAt = order['created_at'] as String?;

    final statusColor = AppColors.orderStatus[status] ?? AppColors.textSecondary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/orders/$orderId'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(orderNumber, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              StatusBadge(status: status, label: statusLabel, color: statusColor),
            ]),
            const SizedBox(height: 8),
            Text('$itemCount item${itemCount != 1 ? 's' : ''}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 4),
            PriceDisplay(amount: total, currency: currency),
            if (hasUnpaidShipping) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.payment_outlined, size: 14, color: AppColors.warning),
                  SizedBox(width: 4),
                  Text('Shipping fee pending', style: TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w600)),
                ]),
              ),
            ],
            if (createdAt != null) ...[
              const SizedBox(height: 4),
              Text(createdAt.substring(0, 10), style: const TextStyle(color: AppColors.textDisabled, fontSize: 12)),
            ],
          ]),
        ),
      ),
    );
  }
}
