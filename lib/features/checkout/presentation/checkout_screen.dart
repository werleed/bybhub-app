import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/common_widgets.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _shippingMethod = 'sea_los';
  String? _couponCode;
  final _couponCtrl = TextEditingController();
  bool _loading = false;
  bool _placing = false;
  String? _error;
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  @override
  void dispose() { _couponCtrl.dispose(); super.dispose(); }

  Future<void> _fetchSummary() async {
    setState(() { _loading = true; _error = null; });
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/cart/checkout-summary', queryParameters: {
        'shipping_method': _shippingMethod,
        if (_couponCode != null) 'coupon_code': _couponCode,
      });
      final body = response.data as Map<String, dynamic>;
      setState(() { _summary = body['data'] as Map<String, dynamic>?; });
    } on ApiException catch (e) {
      setState(() { _error = e.message; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _placeOrder() async {
    if (_summary == null) return;
    setState(() { _placing = true; _error = null; });
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('/orders/checkout', data: {
        'shipping_method': _shippingMethod,
        if (_couponCode != null) 'coupon_code': _couponCode,
        'terms_accepted': true,
      });
      final body = response.data as Map<String, dynamic>;
      final orderId = body['data']?['order_id'] as int?;
      if (mounted && orderId != null) {
        context.go('/order-placed/$orderId');
      }
    } on ApiException catch (e) {
      setState(() { _error = e.message; });
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: _loading
          ? const LoadingOverlay()
          : _error != null && _summary == null
              ? ErrorRetry(message: _error!, onRetry: _fetchSummary)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    // Shipping method (sea only at checkout)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Shipping Method', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 4),
                          const Text('Sea freight only at checkout. Air/express assigned by admin after weighing.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(height: 12),
                          ...AppConstants.seaShippingMethods.map((method) => RadioListTile<String>(
                            value: method,
                            groupValue: _shippingMethod,
                            title: Text(method.replaceAll('_', ' ').toUpperCase()),
                            onChanged: (v) {
                              setState(() => _shippingMethod = v!);
                              _fetchSummary();
                            },
                          )),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Coupon
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(children: [
                          Expanded(
                            child: TextField(
                              controller: _couponCtrl,
                              decoration: const InputDecoration(labelText: 'Coupon code (optional)'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              setState(() => _couponCode = _couponCtrl.text.isNotEmpty ? _couponCtrl.text : null);
                              _fetchSummary();
                            },
                            child: const Text('Apply'),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Order summary
                    if (_summary != null) _OrderSummaryCard(summary: _summary!),

                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(_error!, style: const TextStyle(color: AppColors.error)),
                      ),
                    ],

                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _placing || _summary == null || !(_summary!['can_pay_with_wallet'] as bool? ?? false)
                          ? null
                          : _placeOrder,
                      child: _placing
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Place Order & Pay from Wallet'),
                    ),

                    if (_summary != null && !(_summary!['can_pay_with_wallet'] as bool? ?? true)) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => context.push('/wallet/fund'),
                        icon: const Icon(Icons.account_balance_wallet_outlined),
                        label: const Text('Top Up Wallet'),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ]),
                ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _OrderSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final currency = summary['currency'] as String? ?? 'NGN';
    final itemsTotal = (summary['items_total_local'] as num?)?.toDouble() ?? 0;
    final purchaseFee = (summary['purchase_fee'] as num?)?.toDouble() ?? 0;
    final discount = (summary['discount_amount'] as num?)?.toDouble() ?? 0;
    final couponDiscount = (summary['coupon_discount'] as num?)?.toDouble() ?? 0;
    final grandTotal = (summary['grand_total'] as num?)?.toDouble() ?? 0;
    final walletBalance = (summary['wallet_balance'] as num?)?.toDouble() ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const Divider(),
          _SummaryRow('Items total', CurrencyFormatter.format(itemsTotal, currency)),
          _SummaryRow('Purchase fee', CurrencyFormatter.format(purchaseFee, currency)),
          if (discount > 0) _SummaryRow('Discount', '−${CurrencyFormatter.format(discount, currency)}',
              color: AppColors.success),
          if (couponDiscount > 0) _SummaryRow('Coupon', '−${CurrencyFormatter.format(couponDiscount, currency)}',
              color: AppColors.success),
          const Divider(),
          _SummaryRow('Total due now', CurrencyFormatter.format(grandTotal, currency),
              bold: true),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline, size: 16, color: AppColors.info),
              const SizedBox(width: 8),
              Expanded(child: Text(summary['shipping_fee_note'] as String? ?? '',
                  style: const TextStyle(fontSize: 12, color: AppColors.info))),
            ]),
          ),
          const SizedBox(height: 8),
          _SummaryRow('Wallet balance', CurrencyFormatter.format(walletBalance, currency),
              color: walletBalance >= grandTotal ? AppColors.success : AppColors.error),
        ]),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool bold;

  const _SummaryRow(this.label, this.value, {this.color, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
      color: color,
      fontSize: bold ? 16 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: style.copyWith(color: color ?? AppColors.textSecondary)),
        Text(value, style: style),
      ]),
    );
  }
}
