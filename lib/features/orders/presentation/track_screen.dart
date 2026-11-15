import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class TrackScreen extends ConsumerStatefulWidget {
  const TrackScreen({super.key});

  @override
  ConsumerState<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends ConsumerState<TrackScreen> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _track() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/track', queryParameters: {'tracking_number': _ctrl.text.trim()});
      final body = res.data as Map<String, dynamic>;
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
      appBar: AppBar(title: const Text('Track Shipment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _ctrl,
                decoration: const InputDecoration(
                  labelText: 'BYB Tracking Number',
                  hintText: 'BYB-XXXX-XXXX',
                  prefixIcon: Icon(Icons.local_shipping_outlined),
                ),
                textInputAction: TextInputAction.go,
                onFieldSubmitted: (_) => _track(),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _loading ? null : _track,
              style: ElevatedButton.styleFrom(minimumSize: const Size(80, 52)),
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Track'),
            ),
          ]),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(_error!, style: const TextStyle(color: AppColors.error)),
            ),
          ],

          if (_result != null) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.local_shipping, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('Tracking: ${_result!['byb_tracking'] ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 12),
                  StatusBadge(
                    status: _result!['status'] as String? ?? 'pending',
                    label: _result!['status_label'] as String? ?? (_result!['status'] as String? ?? 'Unknown'),
                  ),
                  const SizedBox(height: 12),
                  if (_result!['carrier'] != null)
                    Text('Carrier: ${_result!['carrier']}', style: const TextStyle(color: AppColors.textSecondary)),
                  if (_result!['estimated_arrival'] != null)
                    Text('Est. Arrival: ${_result!['estimated_arrival']}',
                        style: const TextStyle(color: AppColors.textSecondary)),
                  if (_result!['arrived_at'] != null)
                    Text('Arrived: ${(_result!['arrived_at'] as String).substring(0, 10)}',
                        style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                  if (_result!['delivered_at'] != null)
                    Text('Delivered: ${(_result!['delivered_at'] as String).substring(0, 10)}',
                        style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
