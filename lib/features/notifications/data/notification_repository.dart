import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  try {
    final dio = ref.watch(dioProvider);
    final response = await dio.get('/notifications/unread-count');
    final data = response.data as Map<String, dynamic>;
    return (data['data']?['count'] as int?) ?? 0;
  } catch (_) {
    return 0;
  }
});
