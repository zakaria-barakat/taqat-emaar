import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import '../repositories/order_repository.dart';
import '../services/order_service.dart';
import 'auth_provider.dart';

final orderServiceProvider = Provider<OrderService>((ref) {
  final client = Supabase.instance.client;
  return OrderService(client);
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final service = ref.watch(orderServiceProvider);
  return OrderRepository(service);
});

final myOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final repo = ref.watch(orderRepositoryProvider);
  return repo.getMyOrders(user.id);
});

final orderDetailProvider =
    FutureProvider.family<OrderModel?, String>((ref, orderId) async {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.getOrderById(orderId);
});
