import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/common_widgets.dart';

class ShippingCalculatorScreen extends ConsumerStatefulWidget {
  const ShippingCalculatorScreen({super.key});
  @override
  ConsumerState<ShippingCalculatorScreen> createState() => _ShippingCalculatorScreenState();
}

class _ShippingCalculatorScreenState extends ConsumerState<ShippingCalculatorScreen> {
  String _country = 'NG';
  String _method = 'sea_los';
  final _weightCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void dispose() { _weightCtrl.dispose(); super.dispose(); }

  Future<void> _calculate() async {
    final weight = double.tryParse(_weightCtrl.text.replaceAll(',', ''));
    if (weight == null || weight <= 0) {
      setState(() => _error = 'Enter a valid weight');
      return;
    }
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('/shipping/calculate', data: {
        'country': _country,
        'method': _method,
        'weight': weight,
      });
      final body = response.data as Map<String, dynamic>;
      setState(() => _result = body['data'] as Map<String, dynamic>?);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shipping Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                DropdownButtonFormField<String>(
                  value: _country,
                  decoration: const InputDecoration(labelText: 'Destination country'),
                  items: AppConstants.countries.map((c) => DropdownMenuItem(value: c['code']!, child: Text(c['name']!))).toList(),
                  onChanged: (v) => setState(() => _country = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _method,
                  decoration: const InputDecoration(labelText: 'Shipping method'),
                  items: [
                    ...AppConstants.seaShippingMethods.map((m) => DropdownMenuItem(value: m, child: Text('🚢 ${m.replaceAll('_', ' ').toUpperCase()}'))),
                    ...AppConstants.airShippingMethods.map((m) => DropdownMenuItem(value: m, child: Text('✈️ ${m.replaceAll('_', ' ').toUpperCase()}'))),
                  ],
                  onChanged: (v) => setState(() => _method = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Weight (kg)', suffixText: 'kg'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loading ? null : _calculate,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Calculate'),
                ),
              ]),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            Card(
              color: AppColors.success.withOpacity(0.08),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  const Text('Estimated Shipping Cost', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.format((_result!['cost'] as num).toDouble(), _result!['currency'] as String? ?? 'NGN'),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.success),
                  ),
                  Text('for ${_result!['weight']}kg via ${(_result!['method'] as String).toUpperCase()}',
                      style: const TextStyle(color: AppColors.textSecondary)),
                ]),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
