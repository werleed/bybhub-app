/// Global constants for the BYBHUB mobile app.
/// These values mirror server-side enums and config — update if the backend changes.
library app_constants;

class AppConstants {
  /// Change to https://bybimport.com for production.
  static const String baseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://127.0.0.1:8090');
  static const String apiVersion = 'v1';
  static const String apiBaseUrl = '$baseUrl/api/$apiVersion';

  /// Image proxy — all 1688/Taobao images MUST go through this.
  static const String imgProxy = '$baseUrl/img-proxy';

  // ── Secure storage keys ───────────────────────────────────────────────────
  static const String kAuthToken = 'auth_token';
  static const String kUserId = 'user_id';
  static const String kUserJson = 'user_json';

  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const String kLanguage = 'language';
  static const String kDisplayCurrency = 'display_currency';
  static const String kOnboardingDone = 'onboarding_done';

  // ── Hive boxes ────────────────────────────────────────────────────────────
  static const String kProductsBox = 'products_cache';
  static const String kOrdersBox = 'orders_cache';
  static const String kCategoriesBox = 'categories_cache';
  static const String kNotificationsBox = 'notifications_cache';

  // ── Pagination ────────────────────────────────────────────────────────────
  static const int pageSize = 24;
  static const int pageSmall = 15;

  // ── Countries ─────────────────────────────────────────────────────────────
  static const List<Map<String, String>> countries = [
    {'code': 'NG', 'name': 'Nigeria', 'currency': 'NGN', 'language': 'en'},
    {'code': 'GH', 'name': 'Ghana', 'currency': 'GHS', 'language': 'en'},
    {'code': 'NE', 'name': 'Niger', 'currency': 'XOF', 'language': 'fr'},
  ];

  // ── Currencies ────────────────────────────────────────────────────────────
  static const Map<String, String> currencySymbols = {
    'NGN': '₦',
    'GHS': '₵',
    'XOF': 'Fr',
    'USD': '\$',
    'CNY': '¥',
  };

  static const List<String> walletCurrencies = ['NGN', 'GHS', 'XOF'];
  static const List<String> displayCurrencies = ['NGN', 'GHS', 'XOF', 'USD', 'CNY'];

  // ── Order status pipelines ────────────────────────────────────────────────
  /// Import (China) order status machine — mirrors backend enum exactly.
  static const List<String> chinaOrderStatuses = [
    'paid',
    'procuring',
    'on_way_to_warehouse',
    'china_warehouse',
    'awaiting_shipping_payment',
    'in_transit',
    'arrived',
    'out_for_delivery',
    'delivered',
  ];

  /// Local (vendor) order status machine.
  static const List<String> localOrderStatuses = [
    'paid',
    'confirmed',
    'preparing',
    'ready_for_pickup',
    'out_for_delivery',
    'delivered',
    'completed',
  ];

  static const List<String> terminalStatuses = ['delivered', 'cancelled', 'completed', 'refunded'];

  // ── Shipment statuses ─────────────────────────────────────────────────────
  static const List<String> shipmentStatuses = [
    'pending',
    'fee_assigned',
    'fee_paid',
    'shipped',
    'arrived',
    'completed',
  ];

  // ── Shipping methods ─────────────────────────────────────────────────────
  /// Sea methods are available at checkout; air assigned by admin post-weighing.
  static const List<String> seaShippingMethods = ['sea_los', 'sea_kan', 'sea'];
  static const List<String> airShippingMethods = ['cargo_gz_los', 'cargo_gz_kan', 'cargo_hk_los', 'cargo_hk_kan', 'express'];

  // ── FCM ───────────────────────────────────────────────────────────────────
  static const String fcmChannelId = 'bybhub_default';
  static const String fcmChannelName = 'BYBHUB Notifications';

  // ── WhatsApp support ──────────────────────────────────────────────────────
  static const String whatsappSupportNumber = '+2348000000000'; // Update with real number
  static const String whatsappSupportUrl = 'https://wa.me/$whatsappSupportNumber';

  // ── App info ──────────────────────────────────────────────────────────────
  static const String appName = 'BYBHUB';
  static const String supportEmail = 'support@bybimport.com';
  static const String websiteUrl = 'https://bybimport.com';

  // ── Cache TTL (seconds) ───────────────────────────────────────────────────
  static const int productCacheTtl = 3600;    // 1 hour
  static const int categoryCacheTtl = 86400;  // 24 hours
  static const int orderCacheTtl = 300;       // 5 minutes
  static const int walletCacheTtl = 60;       // 1 minute — financial data, keep short
}
