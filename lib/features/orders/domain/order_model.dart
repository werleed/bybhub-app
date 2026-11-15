/// Order status label helper — mirrors backend config/bybhub.php order_statuses.
class OrderStatusHelper {
  static String label(String status) {
    const labels = {
      'pending': 'Pending',
      'paid': 'Paid',
      'procuring': 'Procuring',
      'on_way_to_warehouse': 'On Way to Warehouse',
      'china_warehouse': 'China Warehouse',
      'awaiting_shipping_payment': 'Awaiting Shipping Payment',
      'in_transit': 'In Transit',
      'arrived': 'Arrived',
      'out_for_delivery': 'Out for Delivery',
      'delivered': 'Delivered',
      'cancelled': 'Cancelled',
      'confirmed': 'Confirmed',
      'preparing': 'Preparing',
      'ready_for_pickup': 'Ready for Pickup',
      'completed': 'Completed',
      'disputed': 'Disputed',
      'refunded': 'Refunded',
    };
    return labels[status] ?? status.replaceAll('_', ' ').split(' ').map((w) => '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }

  static String shortLabel(String status) {
    const short = {
      'pending': 'Pending',
      'paid': 'Paid',
      'procuring': 'Procuring',
      'on_way_to_warehouse': 'To Warehouse',
      'china_warehouse': 'Warehouse',
      'awaiting_shipping_payment': 'Pay Shipping',
      'in_transit': 'Transit',
      'arrived': 'Arrived',
      'out_for_delivery': 'Delivering',
      'delivered': 'Delivered',
      'cancelled': 'Cancelled',
      'confirmed': 'Confirmed',
      'preparing': 'Preparing',
      'ready_for_pickup': 'Ready',
      'completed': 'Done',
      'disputed': 'Disputed',
      'refunded': 'Refunded',
    };
    return short[status] ?? status;
  }

  /// Returns true if the status is terminal (no further transitions expected).
  static bool isTerminal(String status) =>
      ['delivered', 'cancelled', 'completed', 'refunded'].contains(status);

  /// Returns the step index in the china order pipeline (0-based).
  /// Returns -1 if the status is not in the standard pipeline.
  static int pipelineStep(String status) {
    const pipeline = [
      'paid', 'procuring', 'on_way_to_warehouse', 'china_warehouse',
      'in_transit', 'arrived', 'out_for_delivery', 'delivered',
    ];
    return pipeline.indexOf(status);
  }
}

/// Order item model.
class OrderItemModel {
  final int id;
  final String title;
  final String? image;
  final String? selectedVariant;
  final int quantity;
  final double unitPriceLocal;
  final double totalPriceLocal;
  final String? procurementStatus;

  const OrderItemModel({
    required this.id,
    required this.title,
    this.image,
    this.selectedVariant,
    required this.quantity,
    required this.unitPriceLocal,
    required this.totalPriceLocal,
    this.procurementStatus,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
        id: json['id'] as int,
        title: (json['title'] as String?) ?? (json['product_snapshot']?['title'] as String?) ?? 'Product',
        image: json['image'] as String?,
        selectedVariant: json['selected_variant'] as String?,
        quantity: (json['quantity'] as int?) ?? 1,
        unitPriceLocal: (json['unit_price_local'] as num?)?.toDouble() ?? 0,
        totalPriceLocal: (json['total_price_local'] as num?)?.toDouble() ?? 0,
        procurementStatus: json['procurement_status'] as String?,
      );
}
