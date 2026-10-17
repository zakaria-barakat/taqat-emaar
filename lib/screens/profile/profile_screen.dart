
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/profile.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/cart_provider.dart';
import '../../data/providers/order_provider.dart';
import '../auth/welcome_screen.dart';
import '../orders/my_orders_screen.dart';

const _navy = Color(0xFF18334F);
const _navyLight = Color(0xFF294663);
const _gold = Color(0xFFF0AD35);
const _pageBackground = Color(0xFFF1F3F6);
const _border = Color(0xFFE5EAF0);
const _mutedText = Color(0xFF687586);
const _danger = Color(0xFFC62828);

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  void _editProfile(Profile? profile) {
    if (profile == null) return;

    final nameController = TextEditingController(text: profile.fullName);
    final phoneController = TextEditingController(text: profile.phone ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              left: 22,
              right: 22,
              top: 26,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _border,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: _gold.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: _navy,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تعديل البيانات الشخصية',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: _navy,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'حدّث معلومات حسابك',
                              style: TextStyle(
                                fontSize: 12,
                                color: _mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _FieldLabel('الاسم الكامل'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: _inputDecoration(
                      hint: 'أدخل اسمك الكامل',
                      icon: Icons.person_outline_rounded,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _FieldLabel('رقم الهاتف للتواصل'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                    decoration: _inputDecoration(
                      hint: '77XXXXXXX',
                      icon: Icons.phone_outlined,
                    ),
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final name = nameController.text.trim();

                              if (name.isEmpty) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('يرجى إدخال الاسم الكامل'),
                                  ),
                                );
                                return;
                              }

                              setModalState(() => isSaving = true);

                              try {
                                final repo = ref.read(authRepositoryProvider);

                                await repo.updateProfile(
                                  userId: profile.id,
                                  fullName: name,
                                  phone: phoneController.text.trim().isEmpty
                                      ? null
                                      : phoneController.text.trim(),
                                );

                                ref.invalidate(profileProvider);

                                if (ctx.mounted) Navigator.pop(ctx);
                              } catch (e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      backgroundColor: _danger,
                                      content: Text('تعذر حفظ التعديل: $e'),
                                    ),
                                  );
                                }
                              } finally {
                                if (ctx.mounted) {
                                  setModalState(() => isSaving = false);
                                }
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: _navy,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 21,
                              height: 21,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'حفظ التعديلات',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: _mutedText),
      prefixIcon: Icon(icon, color: _navy, size: 21),
      filled: true,
      fillColor: _pageBackground,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _navy, width: 1.5),
      ),
    );
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: _navy),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'تسجيل الخروج',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _navy,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'هل أنت متأكد من رغبتك في تسجيل الخروج من حسابك؟',
            style: TextStyle(height: 1.6, color: _mutedText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: _mutedText),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(authRepositoryProvider).signOut();
                ref.invalidate(profileProvider);
                ref.invalidate(myOrdersProvider);
                ref.read(cartProvider.notifier).loadCart();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              },
              child: const Text('تسجيل الخروج'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isAuthenticated = user != null;
    final profileAsync = ref.watch(profileProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _pageBackground,
        appBar: AppBar(
          backgroundColor: _pageBackground,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 20,
          title: const Row(
            children: [
              Icon(Icons.person_outline_rounded, color: _navy, size: 25),
              SizedBox(width: 10),
              Text(
                'الملف الشخصي',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: _navy,
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              _buildMainProfileCard(
                isAuthenticated: isAuthenticated,
                userEmail: user?.email ?? '',
                profileAsync: profileAsync,
              ),
              const SizedBox(height: 22),
              _buildOrdersTile(isAuthenticated),
              if (isAuthenticated) ...[
                const SizedBox(height: 14),
                _buildSignOutButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainProfileCard({
    required bool isAuthenticated,
    required String userEmail,
    required AsyncValue<Profile?> profileAsync,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isAuthenticated)
            profileAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(22),
                child: CircularProgressIndicator(color: _gold),
              ),
              error: (error, stackTrace) => _buildUserHeader(userEmail, null),
              data: (profile) => _buildUserHeader(userEmail, profile),
            )
          else
            _buildGuestHeader(),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: _navyLight,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      color: _gold,
                      size: 19,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'حالة الحساب',
                      style: TextStyle(
                        color: _gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'حسابك الشخصي',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader(String email, Profile? profile) {
    final name = profile?.fullName.trim().isNotEmpty == true
        ? profile!.fullName.trim()
        : 'عميل طاقة إعمار';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _avatar(name),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'بيانات حسابك الشخصي',
                style: TextStyle(
                  color: Color(0xFFDCE5EF),
                  fontSize: 12,
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFDCE5EF),
                    fontSize: 11,
                  ),
                ),
              ],
              if (profile?.phone?.isNotEmpty == true) ...[
                const SizedBox(height: 3),
                Text(
                  profile!.phone!,
                  style: const TextStyle(
                    color: Color(0xFFDCE5EF),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'تعديل البيانات',
          onPressed: profile == null ? null : () => _editProfile(profile),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.08),
          ),
          icon: const Icon(
            Icons.edit_outlined,
            color: _gold,
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _buildGuestHeader() {
    return Row(
      children: [
        _avatar('ط'),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'عميل طاقة إعمار',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'بيانات حسابك الشخصي',
                style: TextStyle(
                  color: Color(0xFFDCE5EF),
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'تتصفح المتجر كزائر',
                style: TextStyle(
                  color: Color(0xFFDCE5EF),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'تسجيل الدخول',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const WelcomeScreen(),
              ),
            );
          },
          icon: const Icon(
            Icons.login_rounded,
            color: _gold,
            size: 23,
          ),
        ),
      ],
    );
  }

  Widget _avatar(String initial) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: _gold,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          initial.isNotEmpty ? initial.substring(0, 1) : 'ط',
          style: const TextStyle(
            color: _navy,
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersTile(bool isAuthenticated) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => isAuthenticated
                  ? const MyOrdersScreen()
                  : const WelcomeScreen(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 17,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _border),
        ),
          child: Row(
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: _navy,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'طلباتي السابقة والحالية',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: _navy,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'متابعة الدفع والتجهيز والتوصيل',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: _mutedText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_left_rounded,
                color: _navy,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: _confirmSignOut,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 17,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFF0DADA),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: _danger,
                size: 23,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'تسجيل الخروج',
                  style: TextStyle(
                    color: _danger,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_back_rounded,
                color: _danger,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: _navy,
      ),
    );
  }
}
