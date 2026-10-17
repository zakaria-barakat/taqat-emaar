import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';

class OrderService {
  final SupabaseClient client;

  OrderService(this.client);

  static const String _orderSelect = '''
    *,
    order_items (
      id,
      order_id,
      product_id,
      product_name,
      quantity,
      unit_price,
      currency,
      subtotal,
      created_at
    )
  ''';

  Future<String> createOrderFromCart({
    required String customerPhone,
    required String deliveryAddress,
    double? deliveryLatitude,
    double? deliveryLongitude,
  }) async {
    final params = <String, dynamic>{
      'p_customer_phone': customerPhone.trim(),
      'p_delivery_address': deliveryAddress.trim(),
    };
    if (deliveryLatitude != null) {
      params['p_delivery_latitude'] = deliveryLatitude;
    }
    if (deliveryLongitude != null) {
      params['p_delivery_longitude'] = deliveryLongitude;
    }

    final response = await client.rpc(
      'create_order_from_cart',
      params: params,
    );

    if (response is Map && response['id'] != null) {
      return response['id'].toString();
    }
    return response.toString();
  }

  Future<List<OrderModel>> getMyOrders(String userId) async {
    final response = await client
        .from('orders')
        .select(_orderSelect)
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    final response = await client
        .from('orders')
        .select(_orderSelect)
        .eq('id', orderId)
        .maybeSingle();

    if (response == null) return null;
    return OrderModel.fromJson(response);
  }

  Future<void> cancelOrder(String orderId) async {
    await client.rpc('cancel_order', params: {
      'p_order_id': orderId,
    });
  }

  Future<void> confirmOrderReceived(String orderId) async {
    await client.rpc('confirm_order_received', params: {
      'p_order_id': orderId,
    });
  }
}
