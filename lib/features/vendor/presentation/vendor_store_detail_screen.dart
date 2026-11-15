import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/common_widgets.dart';

final vendorStoreDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, slug) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/stores/$slug');
  final body = response.data as Map<String, dynamic>;
  return body['data'] as Map<String, dynamic>;
});

class VendorStoreDetailScreen extends ConsumerWidget {
  final String slug;
  const VendorStoreDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeAsync = ref.watch(vendorStoreDetailProvider(slug));

    return Scaffold(
      body: storeAsync.when(
        loading: () => const LoadingOverlay(),
        error: (e, _) => ErrorRetry(message: e.toString(), onRetry: () => ref.invalidate(vendorStoreDetailProvider(slug))),
        data: (data) {
          final store = data['store'] as Map<String, dynamic>;
          final products = (data['products']?['data'] as List?) ?? [];
          return CustomScrollView(slivers: [
            SliverAppBar(
              expandedHeight: 150,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(store['store_name'] as String? ?? ''),
                background: Container(color: AppColors.primary,
                  child: Center(child: Icon(Icons.store, size: 60, color: Colors.white.withOpacity(0.3)))),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(store['store_description'] as String? ?? '',
                    style: const TextStyle(color: AppColors.textSecondary)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final p = products[i] as Map<String, dynamic>;
                    return GestureDetector(
                      onTap: () => context.push('/products/${p['slug'] ?? p['id']}'),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(children: [
                          Expanded(child: p['main_image'] != null
                              ? Image.network(p['main_image'] as String, fit: BoxFit.cover, width: double.infinity)
                              : Container(color: AppColors.surfaceVariant, child: const Icon(Icons.image_outlined))),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(p['title'] as String? ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(CurrencyFormatter.format((p['price_ngn'] as num).toDouble(), 'NGN'),
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.secondary)),
                            ]),
                          ),
                        ]),
                      ),
                    );
                  },
                  childCount: products.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 12, mainAxisSpacing: 12,
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
          ]);
        },
      ),
    );
  }
}
