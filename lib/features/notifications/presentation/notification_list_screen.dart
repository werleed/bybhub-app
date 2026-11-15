import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../data/notification_repository.dart';

final notificationsListProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/notifications');
  final body = response.data as Map<String, dynamic>;
  return (body['data'] as List?) ?? [];
});

class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              final dio = ref.read(dioProvider);
              try {
                await dio.post('/notifications/read-all');
                ref.invalidate(notificationsListProvider);
                ref.invalidate(unreadNotificationCountProvider);
              } catch (_) {}
            },
            child: const Text('Mark all read', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: notifAsync.when(
        loading: () => const LoadingOverlay(),
        error: (e, _) => ErrorRetry(message: e.toString(), onRetry: () => ref.invalidate(notificationsListProvider)),
        data: (notifs) => notifs.isEmpty
            ? const EmptyState(icon: Icons.notifications_outlined, title: 'No notifications')
            : ListView.separated(
                itemCount: notifs.length,
                separatorBuilder: (_, __) => const Divider(height: 0),
                itemBuilder: (_, i) {
                  final n = notifs[i] as Map<String, dynamic>;
                  final isRead = n['is_read'] as bool? ?? false;
                  return ListTile(
                    tileColor: isRead ? null : AppColors.primary.withOpacity(0.04),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(n['icon'] as String? ?? '🔔'),
                    ),
                    title: Text(n['title'] as String? ?? '',
                        style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.w700, fontSize: 13)),
                    subtitle: Text(n['message'] as String? ?? '',
                        maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                    trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(n['created_at']?.toString().substring(0, 10) ?? '',
                          style: const TextStyle(fontSize: 11, color: AppColors.textDisabled)),
                      if (!isRead) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle)),
                    ]),
                    onTap: () async {
                      if (!isRead) {
                        final dio = ref.read(dioProvider);
                        try {
                          await dio.post('/notifications/${n['id']}/read');
                          ref.invalidate(notificationsListProvider);
                          ref.invalidate(unreadNotificationCountProvider);
                        } catch (_) {}
                      }
                    },
                  );
                },
              ),
      ),
    );
  }
}
