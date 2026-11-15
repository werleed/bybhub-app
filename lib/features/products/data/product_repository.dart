import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';

class ProductModel {
  final int id;
  final String title;
  final String? slug;
  final String? mainImage;
  final List<String> images;
  final double priceCny;
  final double priceLocal;
  final String currency;
  final String currencySymbol;
  final String source;
  final String productType;
  final String stockStatus;
  final int moq;
  final bool isFlashSale;
  final double? flashSalePriceLocal;
  final Map<String, dynamic>? category;
  final int orderCount;
  final String? description;
  final double? priceCnyMax;
  final List<dynamic> priceTiers;
  final List<dynamic> skus;
  final List<dynamic> variants;
  final double weightKg;
  final double billableWeight;
  final double domesticFreightCny;
  final String? sellerName;
  final String? supplierId;
  final String? supplierChatUrl;
  final bool supplierVerified;
  final int supplierScore;
  final Map<String, bool> restrictions;
  final int? stockQuantity;
  final int qty_step;

  const ProductModel({
    required this.id,
    required this.title,
    this.slug,
    this.mainImage,
    required this.images,
    required this.priceCny,
    required this.priceLocal,
    required this.currency,
    required this.currencySymbol,
    required this.source,
    required this.productType,
    required this.stockStatus,
    required this.moq,
    required this.isFlashSale,
    this.flashSalePriceLocal,
    this.category,
    required this.orderCount,
    this.description,
    this.priceCnyMax,
    required this.priceTiers,
    required this.skus,
    required this.variants,
    required this.weightKg,
    required this.billableWeight,
    required this.domesticFreightCny,
    this.sellerName,
    this.supplierId,
    this.supplierChatUrl,
    required this.supplierVerified,
    required this.supplierScore,
    required this.restrictions,
    this.stockQuantity,
    required this.qty_step,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id: json['id'] as int,
        title: json['title'] as String,
        slug: json['slug'] as String?,
        mainImage: json['main_image'] as String?,
        images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
        priceCny: (json['price_cny'] as num).toDouble(),
        priceLocal: (json['price_local'] as num?)?.toDouble() ?? 0,
        currency: json['currency'] as String? ?? 'NGN',
        currencySymbol: json['currency_symbol'] as String? ?? '₦',
        source: json['source'] as String? ?? 'manual',
        productType: json['product_type'] as String? ?? 'china',
        stockStatus: json['stock_status'] as String? ?? 'in_stock',
        moq: (json['moq'] as int?) ?? 1,
        isFlashSale: json['is_flash_sale'] as bool? ?? false,
        flashSalePriceLocal: (json['flash_sale_price_local'] as num?)?.toDouble(),
        category: json['category'] as Map<String, dynamic>?,
        orderCount: (json['order_count'] as int?) ?? 0,
        description: json['description'] as String?,
        priceCnyMax: (json['price_cny_max'] as num?)?.toDouble(),
        priceTiers: (json['price_tiers'] as List?) ?? [],
        skus: (json['skus'] as List?) ?? [],
        variants: (json['variants'] as List?) ?? [],
        weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0,
        billableWeight: (json['billable_weight'] as num?)?.toDouble() ?? 0.5,
        domesticFreightCny: (json['domestic_freight_cny'] as num?)?.toDouble() ?? 0,
        sellerName: json['seller_name'] as String?,
        supplierId: json['supplier_id']?.toString(),
        supplierChatUrl: json['supplier_chat_url'] as String?,
        supplierVerified: json['supplier_verified'] as bool? ?? false,
        supplierScore: (json['supplier_score'] as int?) ?? 0,
        restrictions: {
          'has_battery': (json['restrictions']?['has_battery'] as bool?) ?? false,
          'has_liquid': (json['restrictions']?['has_liquid'] as bool?) ?? false,
          'is_powder': (json['restrictions']?['is_powder'] as bool?) ?? false,
          'is_food': (json['restrictions']?['is_food'] as bool?) ?? false,
          'is_fragile': (json['restrictions']?['is_fragile'] as bool?) ?? false,
          'allows_air': (json['restrictions']?['allows_air'] as bool?) ?? true,
        },
        stockQuantity: json['stock_quantity'] as int?,
        qty_step: (json['qty_step'] as int?) ?? 1,
      );

  bool get isInStock => stockStatus != 'out_of_stock';
  bool get allowsAirFreight => restrictions['allows_air'] ?? true;
}

// ── Providers ─────────────────────────────────────────────────────────────

final productListProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>(
  (ref, params) async {
    final dio = ref.watch(dioProvider);
    try {
      final response = await dio.get('/products', queryParameters: params);
      return response.data as Map<String, dynamic>;
    } on Exception catch (e) {
      throw e;
    }
  },
);

final productDetailProvider = FutureProvider.family<ProductModel, String>((ref, slug) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/products/$slug');
  final body = response.data as Map<String, dynamic>;
  return ProductModel.fromJson(body['data'] as Map<String, dynamic>);
});

final categoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/categories');
  final body = response.data as Map<String, dynamic>;
  return (body['data'] as List).cast<Map<String, dynamic>>();
});
