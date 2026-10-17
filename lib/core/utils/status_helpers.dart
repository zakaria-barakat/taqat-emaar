import 'package:flutter/material.dart';

class StatusHelpers {
  static String getOrderStatusArabic(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'قيد الانتظار';
      case 'confirmed':
        return 'مؤكد';
      case 'preparing':
        return 'جاري التجهيز';
      case 'out_for_delivery':
        return 'في طريق التوصيل';
      case 'delivered':
        return 'تم التوصيل بنجاح';
      case 'cancelled':
        return 'ملغي';
      case 'rejected':
        return 'مرفوض';
      case 'failed_delivery':
        return 'تعذر التسليم';
      default:
        return status;
    }
  }

  static Color getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF0AD35);
      case 'confirmed':
      case 'preparing':
        return const Color(0xFF1E88E5);
      case 'out_for_delivery':
        return const Color(0xFF8E24AA);
      case 'delivered':
        return const Color(0xFF2E7D32);
      case 'cancelled':
      case 'rejected':
      case 'failed_delivery':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF546E7A);
    }
  }

  static String getPaymentStatusArabic(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'بانتظار التحويل';
      case 'submitted':
        return 'تم إرسال الإيصال (قيد المراجعة)';
      case 'verified':
        return 'تم تأكيد الدفع';
      case 'rejected':
        return 'إيصال مرفوض';
      case 'refunded':
        return 'مسترد';
      default:
        return status;
    }
  }

  static Color getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFE65100);
      case 'submitted':
        return const Color(0xFF0288D1);
      case 'verified':
        return const Color(0xFF2E7D32);
      case 'rejected':
        return const Color(0xFFC62828);
      case 'refunded':
        return const Color(0xFF6A1B9A);
      default:
        return const Color(0xFF546E7A);
    }
  }
}
