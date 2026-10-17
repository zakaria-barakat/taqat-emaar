import 'package:flutter_test/flutter_test.dart';
import 'package:taqat_emaar/data/models/order.dart';

void main() {
  group('OrderModel tests', () {
    test('OrderModel parses received_confirmed_at correctly when present', () {
      final json = {
        'id': 'order-123',
        'user_id': 'user-456',
        'status': 'delivered',
        'payment_status': 'verified',
        'subtotal': 15000.0,
        'delivery_fee': 0.0,
        'total_amount': 15000.0,
        'currency': 'YER',
        'customer_phone': '777123456',
        'delivery_address': 'Sanaa, Hadda Street',
        'created_at': '2026-10-15T10:00:00Z',
        'updated_at': '2026-10-16T12:00:00Z',
        'received_confirmed_at': '2026-10-16T14:30:00Z',
        'order_items': [
          {
            'id': 'item-1',
            'order_id': 'order-123',
            'product_id': 'prod-1',
            'product_name': 'أسمنت الوطنية بورتلاندي',
            'quantity': 10,
            'unit_price': 1500.0,
            'currency': 'YER',
            'subtotal': 15000.0,
          }
        ],
      };

      final order = OrderModel.fromJson(json);

      expect(order.id, 'order-123');
      expect(order.status, 'delivered');
      expect(order.paymentStatus, 'verified');
      expect(order.receivedConfirmedAt, isNotNull);
      expect(order.receivedConfirmedAt!.year, 2026);
      expect(order.items.length, 1);
      expect(order.items.first.productName, 'أسمنت الوطنية بورتلاندي');

      final serialized = order.toJson();
      expect(serialized['received_confirmed_at'], isNotNull);
    });

    test('OrderModel handles null received_confirmed_at gracefully', () {
      final json = {
        'id': 'order-789',
        'user_id': 'user-456',
        'status': 'pending',
        'payment_status': 'pending',
        'subtotal': 5000.0,
        'delivery_fee': 0.0,
        'total_amount': 5000.0,
        'currency': 'YER',
        'customer_phone': '777000000',
        'delivery_address': 'Sanaa',
        'received_confirmed_at': null,
      };

      final order = OrderModel.fromJson(json);
      expect(order.receivedConfirmedAt, isNull);
    });
  });
}
