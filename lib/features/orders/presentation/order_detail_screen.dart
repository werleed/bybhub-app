import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/common_widgets.dart';

final orderDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, orderId) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/orders/$orderId');
  final body = response.data as Map<String, dynamic>;
  return body['data'] as Map<String, dynamic>;
});

class OrderDetailScreen extends ConsumerStatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _actionLoading = false;
  String? _actionError;

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Order Detail')),
      body: orderAsync.when(
        loading: () => const LoadingOverlay(),
        error: (e, _) => ErrorRetry(message: e.toString(), onRetry: () => ref.invalidate(orderDetailProvider(widget.orderId))),
        data: (order) => _buildDetail(context, order),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, Map<String, dynamic> order) {
    final status = order['status'] as String? ?? 'paid';
    final orderType = order['order_type'] as String? ?? 'china';
    final currency = order['currency'] as String? ?? 'NGN';
    final shipping = order['shipping'] as Map<String, dynamic>? ?? {};
    final delivery = order['delivery'] as Map<String, dynamic>? ?? {};
    final pricing = order['pricing'] as Map<String, dynamic>? ?? {};
    final items = (order['items'] as List?) ?? [];
    final timeline = (order['timeline'] as List?) ?? [];
    final canPayShipping = order['can_pay_shipping'] as bool? ?? false;
    final canRequestDoorstep = order['can_request_doorstep'] as bool? ?? false;
    final canConfirmPickup = order['can_confirm_pickup'] as bool? ?? false;
    final canRate = order['can_rate'] as bool? ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Status header
        Card(
          color: AppColors.primary,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(order['order_number'] as String? ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              StatusBadge(
                status: status,
                label: order['status_label'] as String? ?? status,
                color: (AppColors.orderStatus[status] ?? AppColors.textSecondary).withOpacity(2),
              ),
              if (order['byb_tracking'] != null) ...[
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.local_shipping_outlined, color: Colors.white60, size: 16),
                  const SizedBox(width: 4),
                  Text(order['byb_tracking'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                ]),
              ],
            ]),
          ),
        ),
        const SizedBox(height: 12),

        // Tracking timeline (import orders)
        if (orderType == 'china' && timeline.isNotEmpty) _TrackingTimeline(timeline: timeline, currentStatus: status),

        // Pending actions banner
        if (canPayShipping) ...[
          _ActionBanner(
            icon: Icons.payment,
            message: 'Shipping fee assigned: ${CurrencyFormatter.format((shipping['fee_assigned'] as num?)?.toDouble() ?? 0, currency)}',
            description: shipping['fee_description'] as String? ?? '',
            actionLabel: 'Pay Now',
            color: AppColors.warning,
            onAction: () => _payShippingFee(order),
            loading: _actionLoading,
          ),
        ],
        if (canRequestDoorstep && !canPayShipping) ...[
          _ActionBanner(
            icon: Icons.home_outlined,
            message: 'Your goods have arrived!',
            description: 'Request doorstep delivery or confirm pickup.',
            actionLabel: 'Request Delivery',
            color: AppColors.success,
            onAction: () => _showDoorstepDialog(order),
            loading: _actionLoading,
          ),
        ],
        if (canConfirmPickup) ...[
          _ActionBanner(
            icon: Icons.check_circle_outlined,
            message: 'Pick up from our office',
            description: delivery['pickup_office'] as String? ?? 'Visit our warehouse to collect your goods.',
            actionLabel: 'Confirm Pickup',
            color: AppColors.info,
            onAction: () => _confirmPickup(),
            loading: _actionLoading,
          ),
        ],

        if (_actionError != null) ...[
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(_actionError!, style: const TextStyle(color: AppColors.error))),
        ],

        const SizedBox(height: 12),

        // Items
        Card(
          child: Column(children: [
            const ListTile(title: Text('Items', style: TextStyle(fontWeight: FontWeight.w700))),
            const Divider(height: 0),
            ...items.map((item) {
              final i = item as Map<String, dynamic>;
              return ListTile(
                leading: i['image'] != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(i['image'] as String, width: 48, height: 48, fit: BoxFit.cover))
                    : const Icon(Icons.inventory_2_outlined),
                title: Text(i['title'] as String? ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (i['selected_variant'] != null) Text(i['selected_variant'] as String, style: const TextStyle(fontSize: 11)),
                  Text('Qty: ${i['quantity']} × ${CurrencyFormatter.format((i['unit_price_local'] as num).toDouble(), currency)}'),
                  if ((i['procurement_status'] as String?) != null)
                    StatusBadge(status: i['procurement_status'] as String, label: (i['procurement_status'] as String).replaceAll('_', ' ')),
                ]),
                trailing: Text(CurrencyFormatter.format((i['total_price_local'] as num).toDouble(), currency),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              );
            }),
          ]),
        ),
        const SizedBox(height: 12),

        // Pricing breakdown
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              const Text('Payment Summary', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Divider(),
              _PricingRow('Items total', (pricing['items_total_local'] as num).toDouble(), currency),
              _PricingRow('Purchase fee', (pricing['purchase_fee'] as num).toDouble(), currency),
              if ((pricing['discount_amount'] as num).toDouble() > 0)
                _PricingRow('Discount', -(pricing['discount_amount'] as num).toDouble(), currency, color: AppColors.success),
              if ((pricing['international_shipping_fee'] as num).toDouble() > 0)
                _PricingRow('Shipping fee', (pricing['international_shipping_fee'] as num).toDouble(), currency),
              if ((pricing['doorstep_delivery_fee'] as num).toDouble() > 0)
                _PricingRow('Doorstep fee', (pricing['doorstep_delivery_fee'] as num).toDouble(), currency),
              const Divider(),
              _PricingRow('Total paid', (pricing['grand_total'] as num).toDouble(), currency, bold: true),
            ]),
          ),
        ),
        const SizedBox(height: 12),

        // Action buttons
        if (canRate) ...[
          ElevatedButton.icon(
            onPressed: () => _showRateDialog(),
            icon: const Icon(Icons.star_outline),
            label: const Text('Rate this order'),
          ),
          const SizedBox(height: 8),
        ],
        if (order['can_cancel'] as bool? ?? false) ...[
          OutlinedButton(
            onPressed: () => _cancelOrder(order),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
            child: const Text('Cancel Order'),
          ),
        ],
        const SizedBox(height: 40),
      ]),
    );
  }

  Future<void> _payShippingFee(Map<String, dynamic> order) async {
    setState(() { _actionLoading = true; _actionError = null; });
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/orders/${widget.orderId}/pay-shipping');
      ref.invalidate(orderDetailProvider(widget.orderId));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shipping fee paid!'), backgroundColor: AppColors.success));
    } on ApiException catch (e) {
      setState(() => _actionError = e.message);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _confirmPickup() async {
    setState(() { _actionLoading = true; _actionError = null; });
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/orders/${widget.orderId}/confirm-pickup');
      ref.invalidate(orderDetailProvider(widget.orderId));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pickup confirmed!'), backgroundColor: AppColors.success));
    } on ApiException catch (e) {
      setState(() => _actionError = e.message);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _cancelOrder(Map<String, dynamic> order) async {
    setState(() { _actionLoading = true; _actionError = null; });
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/orders/${widget.orderId}/cancel');
      ref.invalidate(orderDetailProvider(widget.orderId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order cancelled. Refund issued.'), backgroundColor: AppColors.success));
        context.pop();
      }
    } on ApiException catch (e) {
      setState(() => _actionError = e.message);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  void _showDoorstepDialog(Map<String, dynamic> order) {
    // TODO: show address input dialog
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Doorstep delivery dialog — coming in next iteration')));
  }

  void _showRateDialog() {
    // TODO: show rating dialog
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rating dialog — coming in next iteration')));
  }
}

class _TrackingTimeline extends StatelessWidget {
  final List<dynamic> timeline;
  final String currentStatus;

  const _TrackingTimeline({required this.timeline, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final allStatuses = AppConstants.chinaOrderStatuses;
    final currentIndex = allStatuses.indexOf(currentStatus);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Tracking', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          ...allStatuses.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final isDone = i <= currentIndex;
            final isCurrent = i == currentIndex;
            final color = isCurrent ? AppColors.primary : (isDone ? AppColors.success : AppColors.textDisabled);

            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Column(children: [
                Icon(isCurrent ? Icons.radio_button_checked : (isDone ? Icons.check_circle : Icons.radio_button_unchecked),
                    color: color, size: 20),
                if (i < allStatuses.length - 1) Container(width: 2, height: 24, color: isDone ? AppColors.success.withOpacity(0.4) : AppColors.surfaceVariant),
              ]),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(s.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(color: color, fontWeight: isCurrent ? FontWeight.w700 : FontWeight.normal, fontSize: 13)),
                ),
              ),
            ]);
          }),
        ]),
      ),
    );
  }
}

class _ActionBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final String description;
  final String actionLabel;
  final Color color;
  final VoidCallback onAction;
  final bool loading;

  const _ActionBanner({
    required this.icon,
    required this.message,
    required this.description,
    required this.actionLabel,
    required this.color,
    required this.onAction,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(message, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 14)),
            if (description.isNotEmpty)
              Text(description, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
          ])),
          loading
              ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: color))
              : ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, minimumSize: const Size(80, 36)),
                  child: Text(actionLabel, style: const TextStyle(fontSize: 12)),
                ),
        ]),
      ),
    );
  }
}

class _PricingRow extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final Color? color;
  final bool bold;

  const _PricingRow(this.label, this.amount, this.currency, {this.color, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
        Text(CurrencyFormatter.format(amount.abs(), currency),
            style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: color ?? AppColors.textPrimary, fontSize: bold ? 15 : 13)),
      ]),
    );
  }
}
