import 'package:kawula_pos/features/products/domain/entities/cart_item.dart';

class OfflineCheckoutPayloadBuilder {
  const OfflineCheckoutPayloadBuilder();

  Map<String, Object?> build({
    required String outletId,
    required List<CartItem> items,
    required num total,
    required num serviceCharge,
    required String paymentMethod,
    required String? memberId,
    required String? tableNumber,
    required bool openBill,
    required num paidAmount,
  }) => {
    'outlet_id': outletId,
    'items': items
        .map(
          (item) => {
            'product_id': item.product.id,
            'quantity': item.quantity,
            'selected_variants': item.selectedVariants
                .map(
                  (variant) => {
                    'group_name': variant.groupName,
                    'option_name': variant.optionName,
                    if (variant.optionId != null) 'option_id': variant.optionId,
                  },
                )
                .toList(growable: false),
            if (item.notes.trim().isNotEmpty) 'notes': item.notes.trim(),
          },
        )
        .toList(growable: false),
    'total_amount': total,
    'service_charge': serviceCharge,
    'payment_method': paymentMethod,
    if (memberId != null && memberId.isNotEmpty) 'member_id': memberId,
    if (tableNumber != null && tableNumber.trim().isNotEmpty)
      'table_number': tableNumber.trim(),
    if (openBill) 'status': 'pending',
    if (!openBill) 'paid_amount': paidAmount,
  };
}
