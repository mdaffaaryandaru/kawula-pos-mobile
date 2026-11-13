import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/shifts/domain/entities/active_shift.dart';
import 'package:kawula_pos/features/offline/data/database/daos/offline_transactions_dao.dart';
import 'package:kawula_pos/features/offline/data/checkout/offline_checkout_validator.dart';

class OfflineReceiptSnapshotBuilder {
  const OfflineReceiptSnapshotBuilder();

  Map<String, Object?> build({
    required OfflineCheckoutValidationResult checkout,
    required AuthUser user,
    required ActiveShift shift,
    required String localId,
    required String syncMarker,
    required OfflineTransactionStatus status,
    required DateTime createdAt,
    required String? memberId,
    required String? tableNumber,
    required bool openBill,
    required num paidAmount,
    required num serviceCharge,
  }) {
    final settings = checkout.settings;
    return {
      'transaction_id': localId,
      'status': status.databaseValue,
      'store_name': settings.storeName.isEmpty ? 'Kawula' : settings.storeName,
      'address': settings.address,
      'logo_url': settings.logoUrl,
      'outlet_id': checkout.outletId,
      'outlet_name': shift.outletName ?? '',
      'cashier_id': user.id,
      'cashier_name': user.name,
      'created_at_local': createdAt.toIso8601String(),
      'items': List.generate(checkout.items.length, (index) {
        final item = checkout.items[index];
        return {
          'product_id': item.product.id,
          'product_name': item.product.name,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'discount_amount': checkout.itemDiscountAmounts[index],
          'notes': item.notes,
          'selected_variants': item.selectedVariants
              .map(
                (variant) => {
                  'group_name': variant.groupName,
                  'option_name': variant.optionName,
                },
              )
              .toList(growable: false),
        };
      }, growable: false),
      'subtotal': checkout.subtotal,
      'tax_amount': checkout.taxAmount,
      'service_charge': serviceCharge,
      'discount_amount': checkout.discountAmount,
      'total_amount': checkout.total,
      'payment_method': checkout.paymentMethod,
      'paid_amount': openBill ? 0 : paidAmount,
      'change_amount': checkout.changeAmount,
      'member_id': memberId,
      'member_name': '',
      'table_number': tableNumber ?? '',
      'sync_marker': syncMarker,
      'sync_status': status.databaseValue,
    };
  }
}
