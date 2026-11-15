import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../data/product_repository.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String slug;
  const ProductDetailScreen({super.key, required this.slug});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  String? _selectedVariant;
  int _imageIndex = 0;
  bool _addingToCart = false;
  String? _cartError;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.slug));

    return Scaffold(
      body: productAsync.when(
        loading: () => const LoadingOverlay(),
        error: (e, _) => ErrorRetry(message: e.toString(), onRetry: () => ref.invalidate(productDetailProvider(widget.slug))),
        data: (product) => _buildDetailWithBar(context, product),
      ),
    );
  }

  Widget _buildDetailWithBar(BuildContext context, ProductModel product) {
    return Scaffold(
      body: _buildDetail(context, product),
      bottomNavigationBar: _buildBottomBar(context, product),
    );
  }

  Widget _buildDetail(BuildContext context, ProductModel product) {
    final images = product.images.isNotEmpty ? product.images : [product.mainImage].whereType<String>().toList();

    return CustomScrollView(
      slivers: [
        // Image gallery
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: AppColors.primary),
          flexibleSpace: FlexibleSpaceBar(
            background: images.isNotEmpty
                ? PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => _imageIndex = i),
                    itemBuilder: (_, i) => CachedNetworkImage(imageUrl: images[i], fit: BoxFit.contain),
                  )
                : Container(color: AppColors.surfaceVariant, child: const Icon(Icons.image_outlined, size: 64)),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Title + price
              Text(product.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              PriceDisplay(amount: product.priceLocal, currency: product.currency,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.secondary)),
              Text('¥${product.priceCny.toStringAsFixed(2)} CNY', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 16),

              // Source badge
              Row(children: [
                Chip(label: Text(product.source.toUpperCase(), style: const TextStyle(fontSize: 11))),
                const SizedBox(width: 8),
                StatusBadge(status: product.stockStatus, label: product.stockStatus == 'in_stock' ? 'In Stock' : product.stockStatus.replaceAll('_', ' ')),
              ]),
              const SizedBox(height: 16),

              // Shipping restrictions
              if (!product.allowsAirFreight) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.warning_amber_outlined, color: AppColors.warning, size: 18),
                    SizedBox(width: 8),
                    Expanded(child: Text('Sea freight only (contains restricted items)', style: TextStyle(fontSize: 12, color: AppColors.warning))),
                  ]),
                ),
                const SizedBox(height: 12),
              ],

              // Variants (if any)
              if (product.variants.isNotEmpty) ...[
                const Text('Variants', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: product.skus.map<Widget>((sku) {
                    final label = (sku as Map)['label'] as String;
                    final isSelected = _selectedVariant == label;
                    return ChoiceChip(
                      label: Text(label, style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withOpacity(0.15),
                      onSelected: (_) => setState(() => _selectedVariant = label),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Quantity
              Row(children: [
                const Text('Qty:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                _QuantitySelector(
                  value: _quantity,
                  min: product.moq,
                  step: product.qty_step,
                  onChanged: (v) => setState(() => _quantity = v),
                ),
                const SizedBox(width: 12),
                if (product.moq > 1) Text('Min. ${product.moq}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ]),
              const SizedBox(height: 20),

              // Description
              if (product.description != null) ...[
                const Text('Description', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 8),
                Text(product.description!, style: const TextStyle(height: 1.5, color: AppColors.textSecondary)),
                const SizedBox(height: 16),
              ],

              // Supplier info
              if (product.sellerName != null) ...[
                const Divider(),
                const Text('Supplier Info', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.store_outlined, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(product.sellerName!, style: const TextStyle(color: AppColors.textSecondary)),
                  if (product.supplierVerified) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.verified, size: 16, color: Colors.blue),
                  ],
                ]),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: product.supplierScore / 100,
                  backgroundColor: AppColors.surfaceVariant,
                  color: AppColors.success,
                ),
                Text('Supplier score: ${product.supplierScore}/100', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],

              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, ProductModel product) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/scraper'),
            icon: const Icon(Icons.link, size: 18),
            label: const Text('Import Link'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _addingToCart || !product.isInStock ? null : () => _addToCart(product),
            child: _addingToCart
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Add to Cart'),
          ),
        ),
      ]),
    );
  }

  Future<void> _addToCart(ProductModel product) async {
    setState(() { _addingToCart = true; _cartError = null; });
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/cart/add', data: {
        'product_id': product.id,
        'quantity': _quantity,
        if (_selectedVariant != null) 'selected_variant': _selectedVariant,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to cart! 🛒'), backgroundColor: AppColors.success),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _addingToCart = false);
    }
  }
}

class _QuantitySelector extends StatelessWidget {
  final int value;
  final int min;
  final int step;
  final ValueChanged<int> onChanged;

  const _QuantitySelector({
    required this.value,
    required this.min,
    required this.step,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      IconButton(
        onPressed: value > min ? () => onChanged(value - step) : null,
        icon: const Icon(Icons.remove_circle_outline),
        color: AppColors.primary,
      ),
      Container(
        width: 48,
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFDEE2E6)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: Text('$value', style: const TextStyle(fontWeight: FontWeight.w600))),
      ),
      IconButton(
        onPressed: () => onChanged(value + step),
        icon: const Icon(Icons.add_circle_outline),
        color: AppColors.primary,
      ),
    ]);
  }
}
