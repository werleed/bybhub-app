import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../data/product_repository.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  final String type;
  final String? category;
  final String? query;

  const ProductListScreen({super.key, required this.type, this.category, this.query});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  late String _sort = 'newest';
  late String _type;
  String? _category;

  @override
  void initState() {
    super.initState();
    _type = widget.type;
    _category = widget.category;
  }

  @override
  Widget build(BuildContext context) {
    final params = <String, dynamic>{
      'type': _type,
      'sort': _sort,
      if (_category != null) 'category': _category,
      if (widget.query != null) 'q': widget.query,
    };

    final productsAsync = ref.watch(productListProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: Text(_category != null ? _category! : 'Products'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'newest', child: Text('Newest')),
              PopupMenuItem(value: 'popular', child: Text('Most Popular')),
              PopupMenuItem(value: 'price_asc', child: Text('Price: Low to High')),
              PopupMenuItem(value: 'price_desc', child: Text('Price: High to Low')),
            ],
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Row(children: [Icon(Icons.sort), Text(' Sort')]),
            ),
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 12, mainAxisSpacing: 12,
          ),
          itemCount: 8,
          itemBuilder: (_, __) => const SkeletonCard(),
        ),
        error: (e, _) => ErrorRetry(
          message: e.toString(),
          onRetry: () => ref.invalidate(productListProvider),
        ),
        data: (body) {
          final items = (body['data'] as List?) ?? [];
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No products found',
              subtitle: 'Try adjusting your search or filters',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 12, mainAxisSpacing: 12,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final p = ProductModel.fromJson(items[i] as Map<String, dynamic>);
              return GestureDetector(
                onTap: () => context.push('/products/${p.slug ?? p.id}'),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: p.mainImage != null
                          ? CachedNetworkImage(imageUrl: p.mainImage!, fit: BoxFit.cover, width: double.infinity)
                          : Container(color: AppColors.surfaceVariant, child: const Icon(Icons.image_outlined, size: 40)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        PriceDisplay(amount: p.priceLocal, currency: p.currency),
                      ]),
                    ),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
