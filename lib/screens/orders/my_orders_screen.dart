import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/status_helpers.dart';
import '../../data/models/order.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/order_provider.dart';
import '../checkout/order_payment_screen.dart';
import 'order_detail_screen.dart';

const _navy = Color(0xFF18334F);
const _gold = Color(0xFFF0AD35);
const _pageBackground = Color(0xFFF6F8FB);

class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final ordersAsync = ref.watch(myOrdersProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _pageBackground,
        appBar: AppBar(
          title: const Text(
            'طلباتي',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _navy,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(myOrdersProvider),
            ),
          ],
        ),
        body: SafeArea(
          child: !isAuthenticated
              ? _buildNotAuthenticated(context)
              : ordersAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 12),
                          Text('تعذر تحميل الطلبات: $e'),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => ref.invalidate(myOrdersProvider),
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (orders) {
                    if (orders.isEmpty) {
                      return _buildEmptyOrders(context);
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: orders.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return _buildOrderCard(context, ref, order);
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildNotAuthenticated(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'يرجى تسجيل الدخول لعرض قائمة طلباتك.',
          style: TextStyle(fontSize: 15, color: Colors.black54),
        ),
      ),
    );
  }

  Widget _buildEmptyOrders(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.assignment_outlined, size: 54, color: _navy),
            ),
            const SizedBox(height: 20),
            const Text(
              'لا توجد طلبات سابقة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy),
            ),
            const SizedBox(height: 8),
            const Text(
              'عندما تقوم بإنشاء وتأكيد طلبات جديدة، ستظهر تفاصيلها وحالاتها هنا.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, WidgetRef ref, OrderModel order) {
    final orderStatusText = StatusHelpers.getOrderStatusArabic(order.status);
    final orderStatusColor = StatusHelpers.getOrderStatusColor(order.status);
    final paymentStatusText = StatusHelpers.getPaymentStatusArabic(order.paymentStatus);
    final paymentStatusColor = StatusHelpers.getPaymentStatusColor(order.paymentStatus);

    final isPendingPayment = order.paymentStatus.toLowerCase() == 'pending';
    final canCancel = order.status.toLowerCase() == 'pending' && isPendingPayment;

    final dateStr = order.createdAt != null
        ? '${order.createdAt!.year}/${order.createdAt!.month}/${order.createdAt!.day}'
        : '';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5EAF0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _navy.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: _navy, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'طلب #${order.id.substring(0, 8)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _navy,
                      ),
                    ),
                  ],
                ),
                Text(
                  dateStr,
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: orderStatusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    orderStatusText,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: orderStatusColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: paymentStatusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    paymentStatusText,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: paymentStatusColor,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.items.length} عنصر',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                Text(
                  '${order.totalAmount.toStringAsFixed(0)} ${order.currency}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _navy,
                  ),
                ),
              ],
            ),

            if (isPendingPayment || canCancel) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (isPendingPayment)
                    Expanded(
                      child: FilledButton.icon(
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
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.upload_file_rounded, size: 18),
                        label: const Text(
                          'رفع إيصال الدفع',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  if (canCancel) ...[
                    if (isPendingPayment) const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _confirmCancelOrder(context, ref, order.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('إلغاء الطلب', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmCancelOrder(BuildContext context, WidgetRef ref, String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إلغاء الطلب'),
          content: const Text(
            'هل أنت متأكد من رغبتك في إلغاء هذا الطلب وتحرير المنتجات المحجوزة؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('تراجع'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final repo = ref.read(orderRepositoryProvider);
                  await repo.cancelOrder(orderId);
                  ref.invalidate(myOrdersProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إلغاء الطلب بنجاح وتحرير الحجوزات.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تعذر إلغاء الطلب: $e')),
                    );
                  }
                }
              },
              child: const Text('تأكيد الإلغاء'),
            ),
          ],
        ),
      ),
    );
  }
}
