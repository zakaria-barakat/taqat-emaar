import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cart_item.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/cart_provider.dart';
import '../auth/welcome_screen.dart';
import '../checkout/checkout_screen.dart';

const _navy = Color(0xFF18334F);
const _pageBackground = Color(0xFFF6F8FB);

class CartScreen extends ConsumerWidget {
  const CartScreen({
    super.key,
    this.onBrowseTap,
  });

  final VoidCallback? onBrowseTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final cartState = ref.watch(cartProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _pageBackground,
        appBar: AppBar(
          title: const Text(
            'سلة المشتريات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _navy,
            ),
          ),
          actions: [
            if (isAuthenticated && !cartState.isEmpty)
              IconButton(
                tooltip: 'إفراغ السلة',
                icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                onPressed: () => _confirmClearCart(context, ref),
              ),
            IconButton(
              tooltip: 'تحديث السلة',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.read(cartProvider.notifier).loadCart(),
            ),
          ],
        ),
        body: SafeArea(
          child: !isAuthenticated
              ? _buildGuestView(context)
              : cartState.isLoading && cartState.items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : cartState.errorMessage != null && cartState.items.isEmpty
                      ? _buildErrorView(context, ref, cartState.errorMessage!)
                      : cartState.isEmpty
                          ? _buildEmptyView(context)
                          : _buildCartContent(context, ref, cartState),
        ),
      ),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _navy.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 56,
                color: _navy,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'تسجيل الدخول مطلوب',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _navy,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'لحفظ مشترياتك ومتابعة الطلبات، يرجى تسجيل الدخول أو إنشاء حسابك في طاقة إعمار.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                );
              },
              icon: const Icon(Icons.login_rounded),
              label: const Text('تسجيل الدخول / إنشاء حساب'),
              style: FilledButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.remove_shopping_cart_outlined,
                size: 54,
                color: _navy,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'سلة المشتريات فارغة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _navy,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'لم تقم بإضافة أي مواد بناء إلى سلتك بعد. تصفح أقسام المتجر واختر ما يناسب مشروعك.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onBrowseTap ?? () => Navigator.pop(context),
              icon: const Icon(Icons.storefront_outlined),
              label: const Text('تصفح المنتجات والتصنيفات'),
              style: FilledButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.read(cartProvider.notifier).loadCart(),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent(BuildContext context, WidgetRef ref, CartState cartState) {
    return Column(
      children: [
        // تحذير في حال وجود عملات مختلفة في السلة (وفق قيود قاعدة البيانات)
        if (cartState.hasCurrencyMismatch)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تنبيه: تحتوي السلة على منتجات بعملات مختلفة. تمنع قواعد المتجر إنشاء طلب بعملات مختلطة. يرجى إبقاء المنتجات بعملة واحدة.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: cartState.items.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = cartState.items[index];
              return _buildCartItemCard(context, ref, item);
            },
          ),
        ),

        // ملخص السلة وزر المتابعة
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border.all(color: const Color(0xFFE5EAF0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'إجمالي المنتجات:',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  Text(
                    '${cartState.itemCount} عنصر',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'المبلغ الإجمالي:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _navy,
                    ),
                  ),
                  Text(
                    cartState.hasCurrencyMismatch
                      ? 'عملات متعددة'
                      : '${cartState.totalAmount.toStringAsFixed(0)} ${cartState.currency}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _navy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: cartState.hasCurrencyMismatch || cartState.isLoading
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                        );
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: _navy,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text(
                  'متابعة إتمام الطلب',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCartItemCard(BuildContext context, WidgetRef ref, CartItem item) {
    final product = item.product;
    final imageUrl = product != null && product.images.isNotEmpty
        ? product.images.first.url
        : null;

    final unitPrice = product?.price ?? 0.0;
    final currency = product?.currency ?? 'YER';
    final sellingUnit = product?.sellingUnit ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EAF0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // صورة المنتج
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.black26,
                      ),
                    )
                  : const Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.black26,
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // تفاصيل المنتج
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product?.name ?? 'منتج غير متوفر',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${unitPrice.toStringAsFixed(0)} $currency ${sellingUnit.isNotEmpty ? "• لكل $sellingUnit" : ""}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 10),

                // أزرار التحكم بالكمية وحذف العنصر
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: _pageBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5EAF0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              ref.read(cartProvider.notifier).updateQuantity(
                                    cartItemId: item.id,
                                    newQuantity: item.quantity - 1,
                                  );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.remove, size: 16),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _navy,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              final stock = product?.stockQuantity ?? 999;
                              if (item.quantity < stock) {
                                ref.read(cartProvider.notifier).updateQuantity(
                                      cartItemId: item.id,
                                      newQuantity: item.quantity + 1,
                                    );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('الكمية المتاحة في المخزون هي $stock فقط'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.add, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      onPressed: () {
                        ref.read(cartProvider.notifier).removeItem(item.id);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClearCart(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إفراغ السلة'),
          content: const Text('هل أنت متأكد من رغبتك في حذف جميع المنتجات من السلة؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(cartProvider.notifier).clearCart();
              },
              child: const Text('إفراغ'),
            ),
          ],
        ),
      ),
    );
  }
}
