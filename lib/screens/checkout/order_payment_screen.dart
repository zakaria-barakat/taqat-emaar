import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/payment_method.dart';
import '../../data/providers/order_provider.dart';
import '../../data/providers/payment_provider.dart';
import '../orders/my_orders_screen.dart';

const _navy = Color(0xFF18334F);
const _gold = Color(0xFFF0AD35);
const _pageBackground = Color(0xFFF6F8FB);

class OrderPaymentScreen extends ConsumerStatefulWidget {
  const OrderPaymentScreen({
    super.key,
    required this.orderId,
    required this.totalAmount,
    required this.currency,
  });

  final String orderId;
  final double totalAmount;
  final String currency;

  @override
  ConsumerState<OrderPaymentScreen> createState() => _OrderPaymentScreenState();
}

class _OrderPaymentScreenState extends ConsumerState<OrderPaymentScreen> {
  PaymentMethodModel? _selectedMethod;
  final _refNumberController = TextEditingController();
  final _picker = ImagePicker();

  Uint8List? _receiptBytes;
  String? _receiptFileName;
  bool _isUploading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _refNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _receiptBytes = bytes;
          _receiptFileName = picked.name;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'تعذر اختيار الصورة: ${e.toString()}';
      });
    }
  }

  Future<void> _handleSubmitReceipt() async {
    if (_selectedMethod == null) {
      setState(() => _errorMessage = 'يرجى اختيار طريقة الدفع المستخدمة للتحويل.');
      return;
    }

    if (_receiptBytes == null) {
      setState(() => _errorMessage = 'يرجى إرفاق صورة إيصال التحويل للمتابعة.');
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final paymentRepo = ref.read(paymentRepositoryProvider);
      await paymentRepo.submitOrderReceipt(
        orderId: widget.orderId,
        paymentMethod: _selectedMethod!.name,
        imageBytes: _receiptBytes!,
        referenceNumber: _refNumberController.text.trim().isEmpty
            ? null
            : _refNumberController.text.trim(),
      );

      // تحديث الطلبات
      ref.invalidate(myOrdersProvider);
      ref.invalidate(orderDetailProvider(widget.orderId));

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'فشل إرسال الإيصال: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 54,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'تم إرسال الإيصال بنجاح',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _navy,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'طلبك الآن قيد التحقق المالي والمراجعة من قبل الإدارة. سيتم إشعارك واعتماد التجهيز فور تدقيق التحويل.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.5, color: Colors.black54),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _navy,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('الانتقال إلى طلباتي'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentMethodsAsync = ref.watch(activePaymentMethodsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _pageBackground,
        appBar: AppBar(
          title: const Text(
            'سداد الطلب وإرسال الإيصال',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ملخص المبلغ ورقم الطلب
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5EAF0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'المبلغ المطلوب تحويله:',
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.totalAmount.toStringAsFixed(0)} ${widget.currency}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: _navy,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _navy.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'طلب #${widget.orderId.substring(0, 8)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _navy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: Colors.red.shade700),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // اختيار وسيلة الدفع
                const Text(
                  '1. اختر وسيلة التحويل المعتمدة',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _navy),
                ),
                const SizedBox(height: 10),

                paymentMethodsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('تعذر تحميل وسائل الدفع: $e'),
                  data: (methods) {
                    if (methods.isEmpty) {
                      return const Text('لا توجد وسائل دفع متاحة حاليًا.');
                    }

                    if (_selectedMethod == null && methods.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() => _selectedMethod = methods.first);
                      });
                    }

                    return Column(
                      children: methods.map((method) {
                        final isSelected = _selectedMethod?.id == method.id;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? _gold : const Color(0xFFE5EAF0),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: () => setState(() => _selectedMethod = method),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    margin: const EdgeInsets.only(top: 2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? _gold : Colors.grey.shade400,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? Center(
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: _gold,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          method.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: _navy,
                                          ),
                                        ),
                                        if (method.accountNumber != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'رقم الحساب: ${method.accountNumber} ${method.accountName != null ? "(${method.accountName})" : ""}',
                                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                                          ),
                                        ],
                                        if (method.instructions != null && method.instructions!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            method.instructions!,
                                            style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // إرفاق الإيصال
                const Text(
                  '2. إرفاق إيصال التحويل',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _navy),
                ),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5EAF0)),
                  ),
                  child: Column(
                    children: [
                      if (_receiptBytes != null) ...[
                        Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE5EAF0)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.memory(
                              _receiptBytes!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _receiptFileName ?? 'تم تحديد الصورة',
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.change_circle_outlined),
                          label: const Text('تغيير صورة الإيصال'),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickImage(ImageSource.gallery),
                                icon: const Icon(Icons.photo_library_outlined),
                                label: const Text('المعرض'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickImage(ImageSource.camera),
                                icon: const Icon(Icons.camera_alt_outlined),
                                label: const Text('الكاميرا'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),

                      // رقم المرجع / الحوالة
                      TextFormField(
                        controller: _refNumberController,
                        decoration: InputDecoration(
                          labelText: 'رقم الحوالة أو السند (اختياري)',
                          hintText: 'مثال: 987654321',
                          prefixIcon: const Icon(Icons.tag_rounded),
                          filled: true,
                          fillColor: _pageBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE5EAF0)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                FilledButton(
                  onPressed: _isUploading ? null : _handleSubmitReceipt,
                  style: FilledButton.styleFrom(
                    backgroundColor: _navy,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'إرسال إيصال التحويل',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),

                const SizedBox(height: 12),

                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                      );
                    },
                    child: const Text('رفع الإيصال لاحقًا من شاشة طلباتي'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
