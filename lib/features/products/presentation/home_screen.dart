import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../auth/data/auth_repository.dart';
import '../data/product_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final featuredAsync = ref.watch(productListProvider({
      'sort': 'popular',
      'per_page': '8',
    }));
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.primary,
                padding: const EdgeInsets.fromLTRB(16, 48, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user != null ? 'Hello, ${user.name.split(' ').first}! 👋' : 'Welcome to BYBHUB',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    const Text('Shop from China, delivered to West Africa',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                onPressed: () => context.push('/cart'),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () => context.push('/notifications'),
              ),
            ],
          ),

          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => context.push('/products'),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDEE2E6)),
                  ),
                  child: Row(children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.search, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text('Search products...', style: TextStyle(color: AppColors.textDisabled)),
                  ]),
                ),
              ),
            ),
          ),

          // Quick actions
          SliverToBoxAdapter(
            child: SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _QuickAction(icon: Icons.link, label: 'Import Link', onTap: () => context.push('/scraper')),
                  _QuickAction(icon: Icons.calculate_outlined, label: 'Shipping Calc', onTap: () => context.push('/shipping-calculator')),
                  _QuickAction(icon: Icons.receipt_long_outlined, label: 'My Orders', onTap: () => context.push('/orders')),
                  _QuickAction(icon: Icons.account_balance_wallet_outlined, label: 'Wallet', onTap: () => context.push('/wallet')),
                  _QuickAction(icon: Icons.store_outlined, label: 'Stores', onTap: () => context.push('/stores')),
                ],
              ),
            ),
          ),

          // Categories
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Categories',
              actionLabel: 'See all',
              onAction: () => context.push('/products'),
            ),
          ),

          categoriesAsync.when(
            loading: () => const SliverToBoxAdapter(child: SizedBox(height: 100, child: LoadingOverlay())),
            error: (e, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            data: (categories) => SliverToBoxAdapter(
              child: SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length.clamp(0, 10),
                  itemBuilder: (_, i) {
                    final c = categories[i];
                    return _CategoryChip(
                      name: c['name'] as String,
                      slug: c['slug'] as String,
                      imageUrl: c['image_url'] as String?,
                      onTap: () => context.push('/products?category=${c['slug']}'),
                    );
                  },
                ),
              ),
            ),
          ),

          // Featured products
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Popular Products',
              actionLabel: 'See all',
              onAction: () => context.push('/products'),
            ),
          ),

          featuredAsync.when(
            loading: () => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const SkeletonCard(),
                  childCount: 4,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 12, mainAxisSpacing: 12,
                ),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(child: ErrorRetry(message: e.toString(), onRetry: () => ref.invalidate(productListProvider))),
            data: (body) {
              final items = (body['data'] as List?) ?? [];
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final p = ProductModel.fromJson(items[i] as Map<String, dynamic>);
                      return _ProductCard(product: p);
                    },
                    childCount: items.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 12, mainAxisSpacing: 12,
                  ),
                ),
              );
            },
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDEE2E6)),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center, maxLines: 2),
          ]),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String name;
  final String slug;
  final String? imageUrl;
  final VoidCallback onTap;

  const _CategoryChip({required this.name, required this.slug, this.imageUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.surfaceVariant,
            backgroundImage: imageUrl != null ? CachedNetworkImageProvider(imageUrl!) : null,
            child: imageUrl == null ? const Icon(Icons.category_outlined, size: 20) : null,
          ),
          const SizedBox(height: 6),
          SizedBox(width: 60, child: Text(name, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/products/${product.slug ?? product.id}'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: product.mainImage != null
                ? CachedNetworkImage(imageUrl: product.mainImage!, fit: BoxFit.cover, width: double.infinity)
                : Container(color: AppColors.surfaceVariant, child: const Icon(Icons.image_outlined, size: 40, color: AppColors.textDisabled)),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              PriceDisplay(
                amount: product.isFlashSale && product.flashSalePriceLocal != null
                    ? product.flashSalePriceLocal!
                    : product.priceLocal,
                currency: product.currency,
                originalAmount: product.isFlashSale ? product.priceLocal : null,
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
