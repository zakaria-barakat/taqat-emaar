import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/status_helpers.dart';
import '../../data/models/order.dart';
import '../../data/providers/order_provider.dart';
import '../checkout/order_payment_screen.dart';

const _navy = Color(0xFF18334F);
const _gold = Color(0xFFF0AD35);
const _pageBackground = Color(0xFFF6F8FB);

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _isConfirmingReceipt = false;

  Future<void> _handleConfirmReceipt(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green),
              SizedBox(width: 8),
              Text('تأكيد استلام الطلب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
          content: const Text(
            'هل تأكدت من وصول واستلام كافة عناصر ومواد هذا الطلب بحالة سليمة؟\nبمجرد التأكيد، سيتم توثيق الاستلام وإشعار إدارة طاقة إعمار.',
            style: TextStyle(height: 1.5, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('نعم، استلمت الطلب'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isConfirmingReceipt = true);

    try {
      await ref.read(orderRepositoryProvider).confirmOrderReceived(orderId);
      ref.invalidate(orderDetailProvider(orderId));
      ref.invalidate(myOrdersProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: _navy,
            content: Text('تم تأكيد استلام الطلب بنجاح. شكرًا لتعاملك مع طاقة إعمار!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            content: Text('تعذر تأكيد الاستلام: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConfirmingReceipt = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _pageBackground,
        appBar: AppBar(
          title: Text(
            'تفاصيل طلب #${widget.orderId.length >= 8 ? widget.orderId.substring(0, 8) : widget.orderId}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(orderDetailProvider(widget.orderId)),
            ),
          ],
        ),
        body: SafeArea(
          child: orderAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 12),
                    Text('تعذر تحميل تفاصيل الطلب: $e'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => ref.invalidate(orderDetailProvider(widget.orderId)),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            ),
            data: (order) {
              if (order == null) {
                return const Center(child: Text('الطلب غير موجود.'));
              }
              return _buildContent(context, order);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, OrderModel order) {
    final orderStatusText = StatusHelpers.getOrderStatusArabic(order.status);
    final orderStatusColor = StatusHelpers.getOrderStatusColor(order.status);
    final paymentStatusText = StatusHelpers.getPaymentStatusArabic(order.paymentStatus);
    final paymentStatusColor = StatusHelpers.getPaymentStatusColor(order.paymentStatus);

    final isPendingPayment = order.paymentStatus.toLowerCase() == 'pending';
    final canConfirmReceipt = order.status.toLowerCase() == 'delivered' &&
        order.paymentStatus.toLowerCase() == 'verified' &&
        order.receivedConfirmedAt == null;
    final isAlreadyConfirmed = order.receivedConfirmedAt != null;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // بطاقة الحالة العامة
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5EAF0)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('حالة الطلب والتجهيز:', style: TextStyle(color: Colors.black54, fontSize: 13)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: orderStatusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      orderStatusText,
                      style: TextStyle(fontWeight: FontWeight.bold, color: orderStatusColor),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('حالة الدفع والتحقق:', style: TextStyle(color: Colors.black54, fontSize: 13)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: paymentStatusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      paymentStatusText,
                      style: TextStyle(fontWeight: FontWeight.bold, color: paymentStatusColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // بطاقة معلومات التوصيل
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5EAF0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.location_on_outlined, color: _navy, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'بيانات وموقع التوصيل',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _navy),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                order.deliveryAddress,
                style: const TextStyle(fontSize: 13.5, height: 1.4),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 16, color: Colors.black45),
                  const SizedBox(width: 6),
                  Text(
                    order.customerPhone,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // بطاقة الأصناف
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5EAF0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'المنتجات المطلوبة',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _navy),
              ),
              const SizedBox(height: 12),
              ...order.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.productName} × ${item.quantity}',
                          style: const TextStyle(fontSize: 13.5),
                        ),
                      ),
                      Text(
                        '${item.subtotal.toStringAsFixed(0)} ${item.currency}',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: _navy,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('رسوم التوصيل:'),
                  Text(
                    'مجاني (${order.deliveryFee.toStringAsFixed(0)} ${order.currency})',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'المبلغ الإجمالي:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _navy),
                  ),
                  Text(
                    '${order.totalAmount.toStringAsFixed(0)} ${order.currency}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _navy,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        if (isAlreadyConfirmed) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_rounded, color: Colors.green.shade700, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تم تأكيد الاستلام بنجاح',
                        style: TextStyle(
                          color: Colors.green.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'وثقت استلام مواد وطلب البناء بتاريخ: ${order.receivedConfirmedAt!.toLocal().toString().split('.')[0]}',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else if (canConfirmReceipt) ...[
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _isConfirmingReceipt ? null : () => _handleConfirmReceipt(order.id),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: _isConfirmingReceipt
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_rounded),
            label: Text(
              _isConfirmingReceipt ? 'جاري توثيق الاستلام...' : 'تأكيد استلام الطلب',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ] else if (order.status.toLowerCase() == 'out_for_delivery') ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _navy.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _navy.withValues(alpha: 0.12)),
            ),
            child: const Row(
              children: [
                Icon(Icons.local_shipping_outlined, color: _navy, size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'شحنتك في طريقها إليك. سيتاح لك تأكيد الاستلام فور إتمام التسليم من المندوب.',
                    style: TextStyle(color: _navy, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (isPendingPayment) ...[
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderPaymentScreen(
                    orderId: order.id,
                    totalAmount: order.totalAmount,
                    currency: order.currency,
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: _navy,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text(
              'رفع إيصال التحويل الآن',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ],
    );
  }
}
