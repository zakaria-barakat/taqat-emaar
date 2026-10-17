import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment_method.dart';

class PaymentService {
  final SupabaseClient client;

  PaymentService(this.client);

  Future<List<PaymentMethodModel>> getActivePaymentMethods() async {
    final response = await client
        .from('payment_methods')
        .select('*')
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    return (response as List)
        .map((json) => PaymentMethodModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>?> getOrderPayment(String orderId) async {
    final response = await client
        .from('payments')
        .select('*')
        .eq('order_id', orderId)
        .maybeSingle();

    return response;
  }

  Future<void> submitOrderReceipt({
    required String orderId,
    required String paymentMethod,
    required Uint8List imageBytes,
    String? referenceNumber,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('يجب تسجيل الدخول لإرسال إيصال الدفع.');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final relativePath = '${user.id}/${orderId}_$timestamp.jpg';

    // 1. رفع الصورة إلى الـ Bucket الخاص payment-receipts
    await client.storage.from('payment-receipts').uploadBinary(
          relativePath,
          imageBytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    // 2. استدعاء الدالة الآمنة submit_order_payment_receipt بالمسار النسبي
    await client.rpc('submit_order_payment_receipt', params: {
      'p_order_id': orderId,
      'p_payment_method': paymentMethod,
      'p_receipt_path': relativePath,
      'p_reference_number': referenceNumber?.trim(),
    });
  }
}
