import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/products/presentation/home_screen.dart';
import '../../features/products/presentation/product_list_screen.dart';
import '../../features/products/presentation/product_detail_screen.dart';
import '../../features/scraper/presentation/scraper_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/checkout/presentation/checkout_screen.dart';
import '../../features/checkout/presentation/order_placed_screen.dart';
import '../../features/orders/presentation/order_list_screen.dart';
import '../../features/orders/presentation/order_detail_screen.dart';
import '../../features/orders/presentation/track_screen.dart';
import '../../features/wallet/presentation/wallet_screen.dart';
import '../../features/wallet/presentation/wallet_fund_screen.dart';
import '../../features/wallet/presentation/wallet_transactions_screen.dart';
import '../../features/notifications/presentation/notification_list_screen.dart';
import '../../features/vendor/presentation/vendor_stores_screen.dart';
import '../../features/vendor/presentation/vendor_store_detail_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/profile_screen.dart';
import '../../features/referrals/presentation/referral_screen.dart';
import '../../features/shipping/presentation/shipping_calculator_screen.dart';
import '../../shared/widgets/main_scaffold.dart';
import '../constants/app_constants.dart';
import '../../features/auth/data/auth_repository.dart';

import '../../features/auth/presentation/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isSplash = state.matchedLocation == '/splash';
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isPublic = ['/shipping-calculator', '/'].any(
        (p) => state.matchedLocation == p || state.matchedLocation.startsWith('/products') || state.matchedLocation.startsWith('/stores'),
      );

      // Always allow splash
      if (isSplash) return null;

      if (!isAuthenticated && !isAuthRoute && !isPublic) {
        return '/auth/login';
      }
      if (isAuthenticated && isAuthRoute) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (_, __) => const SplashScreen(),
      ),
      // ── Auth ───────────────────────────────────────────────────────────
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        name: 'register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        name: 'forgotPassword',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),

      // ── Main shell (bottom nav) ────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/products',
            name: 'productList',
            builder: (_, state) => ProductListScreen(
              type: state.uri.queryParameters['type'] ?? 'china',
              category: state.uri.queryParameters['category'],
              query: state.uri.queryParameters['q'],
            ),
            routes: [
              GoRoute(
                path: ':slug',
                name: 'productDetail',
                builder: (_, state) => ProductDetailScreen(slug: state.pathParameters['slug']!),
              ),
            ],
          ),
          GoRoute(
            path: '/scraper',
            name: 'scraper',
            builder: (_, __) => const ScraperScreen(),
          ),
          GoRoute(
            path: '/cart',
            name: 'cart',
            builder: (_, __) => const CartScreen(),
          ),
          GoRoute(
            path: '/orders',
            name: 'orders',
            builder: (_, __) => const OrderListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'orderDetail',
                builder: (_, state) => OrderDetailScreen(
                  orderId: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/wallet',
            name: 'wallet',
            builder: (_, __) => const WalletScreen(),
            routes: [
              GoRoute(
                path: 'fund',
                name: 'walletFund',
                builder: (_, __) => const WalletFundScreen(),
              ),
              GoRoute(
                path: 'transactions',
                name: 'walletTransactions',
                builder: (_, __) => const WalletTransactionsScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (_, __) => const NotificationListScreen(),
          ),
          GoRoute(
            path: '/stores',
            name: 'vendorStores',
            builder: (_, __) => const VendorStoresScreen(),
            routes: [
              GoRoute(
                path: ':slug',
                name: 'vendorStore',
                builder: (_, state) => VendorStoreDetailScreen(
                  slug: state.pathParameters['slug']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/referrals',
            name: 'referrals',
            builder: (_, __) => const ReferralScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (_, __) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'profile',
                name: 'profile',
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/shipping-calculator',
            name: 'shippingCalculator',
            builder: (_, __) => const ShippingCalculatorScreen(),
          ),
          GoRoute(
            path: '/track',
            name: 'track',
            builder: (_, __) => const TrackScreen(),
          ),
        ],
      ),

      // ── Checkout (full-screen, outside shell) ─────────────────────────
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        builder: (_, __) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/order-placed/:orderId',
        name: 'orderPlaced',
        builder: (_, state) => OrderPlacedScreen(
          orderId: int.parse(state.pathParameters['orderId']!),
        ),
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});
