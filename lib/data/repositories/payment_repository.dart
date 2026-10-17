import 'dart:typed_data';
import '../models/payment_method.dart';
import '../services/payment_service.dart';

class PaymentRepository {
  final PaymentService paymentService;

  PaymentRepository(this.paymentService);

  Future<List<PaymentMethodModel>> getActivePaymentMethods() {
    return paymentService.getActivePaymentMethods();
  }

  Future<Map<String, dynamic>?> getOrderPayment(String orderId) {
    return paymentService.getOrderPayment(orderId);
  }

  Future<void> submitOrderReceipt({
    required String orderId,
    required String paymentMethod,
    required Uint8List imageBytes,
    String? referenceNumber,
  }) {
    return paymentService.submitOrderReceipt(
      orderId: orderId,
      paymentMethod: paymentMethod,
      imageBytes: imageBytes,
      referenceNumber: referenceNumber,
    );
  }
}
