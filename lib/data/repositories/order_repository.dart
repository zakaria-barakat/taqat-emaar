import '../models/order.dart';
import '../services/order_service.dart';

class OrderRepository {
  final OrderService orderService;

  OrderRepository(this.orderService);

  Future<String> createOrderFromCart({
    required String customerPhone,
    required String deliveryAddress,
    double? deliveryLatitude,
    double? deliveryLongitude,
  }) {
    return orderService.createOrderFromCart(
      customerPhone: customerPhone,
      deliveryAddress: deliveryAddress,
      deliveryLatitude: deliveryLatitude,
      deliveryLongitude: deliveryLongitude,
    );
  }

  Future<List<OrderModel>> getMyOrders(String userId) {
    return orderService.getMyOrders(userId);
  }

  Future<OrderModel?> getOrderById(String orderId) {
    return orderService.getOrderById(orderId);
  }

  Future<void> cancelOrder(String orderId) {
    return orderService.cancelOrder(orderId);
  }

  Future<void> confirmOrderReceived(String orderId) {
    return orderService.confirmOrderReceived(orderId);
  }
}
