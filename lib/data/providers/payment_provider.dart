import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment_method.dart';
import '../repositories/payment_repository.dart';
import '../services/payment_service.dart';

final paymentServiceProvider = Provider<PaymentService>((ref) {
  final client = Supabase.instance.client;
  return PaymentService(client);
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final service = ref.watch(paymentServiceProvider);
  return PaymentRepository(service);
});

final activePaymentMethodsProvider =
    FutureProvider<List<PaymentMethodModel>>((ref) async {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.getActivePaymentMethods();
});

final orderPaymentProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, orderId) async {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.getOrderPayment(orderId);
});
