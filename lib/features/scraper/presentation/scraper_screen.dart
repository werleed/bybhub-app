import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class ScraperScreen extends ConsumerStatefulWidget {
  const ScraperScreen({super.key});
  @override
  ConsumerState<ScraperScreen> createState() => _ScraperScreenState();
}

class _ScraperScreenState extends ConsumerState<ScraperScreen> {
  final _urlCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;
  bool _canManual = false;

  @override
  void dispose() { _urlCtrl.dispose(); super.dispose(); }

  Future<void> _fetch() async {
    if (_urlCtrl.text.trim().isEmpty) return;
    setState(() { _loading = true; _error = null; _result = null; });

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('/scraper/fetch', data: {'url': _urlCtrl.text.trim()});
      final body = response.data as Map<String, dynamic>;
      setState(() { _result = body['data'] as Map<String, dynamic>?; });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _canManual = (e.errors?['can_manual'] as bool?) ?? false;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addToCart() async {
    if (_result == null) return;
    final productId = _result!['product_id'] as int?;
    final data = _result!['data'] as Map<String, dynamic>?;
    if (data == null) return;

    try {
      final dio = ref.read(dioProvider);
      if (productId != null) {
        await dio.post('/cart/add', data: {'product_id': productId, 'quantity': 1});
      } else {
        await dio.post('/cart/add-scraped', data: {
          'scraped_data': data,
          'quantity': 1,
          'unit_price_cny': data['price_cny'],
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to cart!'), backgroundColor: AppColors.success),
        );
        context.push('/cart');
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Paste a product link from:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: ['1688.com', 'taobao.com', 'alibaba.com'].map((s) =>
                  Chip(label: Text(s, style: const TextStyle(fontSize: 12)))).toList()),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _urlCtrl,
            decoration: InputDecoration(
              labelText: 'Paste product URL',
              hintText: 'https://detail.1688.com/offer/...',
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () { _urlCtrl.clear(); setState(() { _result = null; _error = null; }); },
              ),
            ),
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.go,
            onFieldSubmitted: (_) => _fetch(),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loading ? null : _fetch,
            icon: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.search),
            label: Text(_loading ? 'Fetching...' : 'Fetch Product'),
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_error!, style: const TextStyle(color: AppColors.error)),
                if (_canManual) ...[
                  const SizedBox(height: 8),
                  TextButton(onPressed: () {}, child: const Text('Enter manually instead')),
                ],
              ]),
            ),
          ],

          if (_result != null) ...[
            const SizedBox(height: 20),
            _ScrapedResultCard(result: _result!, onAddToCart: _addToCart),
          ],
        ]),
      ),
    );
  }
}

class _ScrapedResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  final VoidCallback onAddToCart;

  const _ScrapedResultCard({required this.result, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    final data = result['data'] as Map<String, dynamic>? ?? {};
    final title = data['title'] as String? ?? 'Product';
    final priceCny = (data['price_cny'] as num?)?.toDouble() ?? 0;
    final images = (data['images'] as List?) ?? [];
    final mainImg = images.isNotEmpty ? images.first.toString() : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (mainImg != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(mainImg, height: 200, width: double.infinity, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          Text('¥${priceCny.toStringAsFixed(2)} CNY', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.secondary)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAddToCart,
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Add to Cart'),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
        ]),
      ),
    );
  }
}
