import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../features/notifications/data/notification_repository.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  static const _tabs = [
    _NavTab(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home', path: '/'),
    _NavTab(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: 'Products', path: '/products'),
    _NavTab(icon: Icons.link, activeIcon: Icons.link, label: 'Import', path: '/scraper'),
    _NavTab(icon: Icons.shopping_cart_outlined, activeIcon: Icons.shopping_cart, label: 'Cart', path: '/cart'),
    _NavTab(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'Orders', path: '/orders'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final unreadAsync = ref.watch(unreadNotificationCountProvider);
    final unreadCount = unreadAsync.when(data: (v) => v, loading: () => 0, error: (_, __) => 0);

    int selectedIndex = _tabs.indexWhere((t) => location.startsWith(t.path));
    if (selectedIndex < 0) selectedIndex = 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (i) => context.go(_tabs[i].path),
        items: _tabs.map((t) {
          final isSelected = _tabs.indexOf(t) == selectedIndex;
          return BottomNavigationBarItem(
            icon: Icon(isSelected ? t.activeIcon : t.icon),
            label: t.label,
          );
        }).toList(),
      ),
      floatingActionButton: unreadCount > 0
          ? FloatingActionButton.small(
              backgroundColor: AppColors.secondary,
              onPressed: () => context.push('/notifications'),
              child: Stack(
                children: [
                  const Icon(Icons.notifications_outlined, color: Colors.white),
                  Positioned(
                    top: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                      child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 9)),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

class _NavTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  const _NavTab({required this.icon, required this.activeIcon, required this.label, required this.path});
}
