import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

final vendorStoresProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/stores');
  final body = response.data as Map<String, dynamic>;
  return (body['data'] as List?) ?? [];
});

class VendorStoresScreen extends ConsumerWidget {
  const VendorStoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(vendorStoresProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Local Stores')),
      body: storesAsync.when(
        loading: () => const LoadingOverlay(),
        error: (e, _) => ErrorRetry(message: e.toString(), onRetry: () => ref.invalidate(vendorStoresProvider)),
        data: (stores) => stores.isEmpty
            ? const EmptyState(icon: Icons.store_outlined, title: 'No stores available')
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: stores.length,
                itemBuilder: (_, i) {
                  final s = stores[i] as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.surfaceVariant,
                        backgroundImage: s['store_logo'] != null ? NetworkImage(s['store_logo'] as String) : null,
                        child: s['store_logo'] == null ? const Icon(Icons.store) : null,
                      ),
                      title: Text(s['store_name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${s['product_count']} products'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/stores/${s['store_slug']}'),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
