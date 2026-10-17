import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../category_detail_screen.dart';
import '../../data/models/category.dart';
import '../../data/models/product.dart';
import '../../data/providers/cart_provider.dart';
import '../../data/providers/category_provider.dart';
import '../../data/providers/product_provider.dart';
import '../../info_screens.dart';
import '../../widgets/product_card.dart';
import '../cart/cart_screen.dart';
import '../profile/profile_screen.dart';

const _navy = Color(0xFF18334F);
const _gold = Color(0xFFF0AD35);

class StoreHomeScreen extends ConsumerStatefulWidget {
  const StoreHomeScreen({super.key});

  @override
  ConsumerState<StoreHomeScreen> createState() => _StoreHomeScreenState();
}

class _StoreHomeScreenState extends ConsumerState<StoreHomeScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _categoriesKey = GlobalKey();

  int _selectedNavigation = 0;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final targetContext = key.currentContext;
    if (targetContext == null) return;

    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      alignment: 0.05,
    );
  }

  void _onNavigationTap(int index) {
    setState(() => _selectedNavigation = index);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(productsProvider);
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 18,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _navy,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.apartment_rounded,
                color: _gold,
                size: 26,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'طاقة إعمار',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: _navy,
                  ),
                ),
                Text(
                  'مواد البناء في مكان واحد',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'تحديث البيانات',
            onPressed: _handleRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _buildCurrentTab(categoriesAsync, productsAsync),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedNavigation,
        onDestinationSelected: _onNavigationTap,
        backgroundColor: Colors.white,
        indicatorColor: _gold.withValues(alpha: 0.20),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cartState.itemCount > 0,
              label: Text('${cartState.itemCount}'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: cartState.itemCount > 0,
              label: Text('${cartState.itemCount}'),
              child: const Icon(Icons.shopping_cart_rounded),
            ),
            label: 'السلة',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'الملف الشخصي',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTab(
    AsyncValue<List<Category>> categoriesAsync,
    AsyncValue<List<Product>> productsAsync,
  ) {
    switch (_selectedNavigation) {
      case 0:
        return _buildHomeBody(categoriesAsync, productsAsync);
      case 1:
        return CartScreen(
          onBrowseTap: () => setState(() => _selectedNavigation = 0),
        );
      case 2:
        return const ProfileScreen();
      default:
        return _buildHomeBody(categoriesAsync, productsAsync);
    }
  }

  Future<void> _handleRefresh() async {
    ref.read(categoryRepositoryProvider).clearCache();
    ref.read(productRepositoryProvider).clearCache();
    ref.invalidate(categoriesProvider);
    ref.invalidate(productsProvider);
    await ref.read(cartProvider.notifier).loadCart();
  }

  Widget _buildHomeBody(
    AsyncValue<List<Category>> categoriesAsync,
    AsyncValue<List<Product>> productsAsync,
  ) {
    return RefreshIndicator(
      color: _navy,
      backgroundColor: Colors.white,
      onRefresh: _handleRefresh,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
        _buildHeroBanner(),
        _buildSearch(),
        const SizedBox(height: 12),
        if (_searchQuery.isNotEmpty)
          _buildSearchResults(productsAsync)
        else ...[
          _buildSectionHeading(
            key: _categoriesKey,
            title: 'تسوّق حسب التصنيف',
            subtitle: 'اختر القسم الذي تبحث عنه',
          ),
          _buildCategories(categoriesAsync),
          const SizedBox(height: 16),
          _buildSectionHeading(
            title: 'المواد والمنتجات المتوفرة',
            subtitle: 'تصفح أحدث مواد البناء المتاحة للشراء المباشر',
          ),
          _buildProductsSection(productsAsync),
        ],
      ],
      ),
    );
  }

  Widget _buildInfoChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: _gold),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFF244B6A),
            Color(0xFF142A43),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'أهلًا بك 👋',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'خلّ مشروعك يبدأ صح',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'اكتشف مواد البناء التي تحتاجها لمشروعك بأسعار واضحة.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                label: 'نبذة عن التطبيق وخدماته',
                icon: Icons.info_outline_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AboutAppScreen(),
                    ),
                  );
                },
              ),
              _buildInfoChip(
                label: 'سياسة الاستخدام والضمان',
                icon: Icons.policy_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TermsPolicyScreen(),
                    ),
                  );
                },
              ),
              _buildInfoChip(
                label: 'التواصل والاستفسارات',
                icon: Icons.support_agent_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ContactUsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'طاقة إعمار',
                        style: TextStyle(
                          color: _gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'كل ما يحتاجه مشروعك\nفي مكان واحد',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: () => _scrollTo(_categoriesKey),
                      style: FilledButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: _navy,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                      ),
                      child: const Text(
                        'تصفّح التصنيفات',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.construction_rounded,
                size: 68,
                color: _gold,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        textInputAction: TextInputAction.search,
        onChanged: (value) {
          setState(() => _searchQuery = value.trim());
        },
        decoration: InputDecoration(
          hintText: 'ابحث عن أسمنت، حديد، بلوك، أدوات...',
          hintStyle: const TextStyle(
            color: Colors.black45,
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: _navy,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  tooltip: 'مسح البحث',
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: const Icon(Icons.close_rounded),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: const BorderSide(color: Color(0xFFE5EAF0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: const BorderSide(color: Color(0xFFE5EAF0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: const BorderSide(
              color: _navy,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(AsyncValue<List<Product>> productsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'نتائج البحث عن «$_searchQuery»',
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('إلغاء البحث'),
              ),
            ],
          ),
        ),
        productsAsync.when(
          loading: () => const SizedBox(
            height: 140,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => _errorMessage(
            'تعذر تحميل نتائج البحث.',
            () => ref.invalidate(productsProvider),
          ),
          data: (products) {
            final filteredProducts = products.where((product) {
              return product.name
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase());
            }).toList();

            if (filteredProducts.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 30,
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: Colors.black26,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'لم نجد منتجات تطابق بحثك.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 600 ? 3 : 2;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredProducts.length,
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 290,
                    ),
                    itemBuilder: (context, index) {
                      return ProductCard(
                        product: filteredProducts[index],
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeading({
    required String title,
    required String subtitle,
    GlobalKey? key,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _navy,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories(AsyncValue<List<Category>> categoriesAsync) {
    return categoriesAsync.when(
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => _errorMessage(
        'تعذر تحميل التصنيفات.',
        () => ref.invalidate(categoriesProvider),
      ),
      data: (categories) {
        if (categories.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('لا توجد تصنيفات متاحة حاليًا.'),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 600 ? 4 : 3;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 115,
                ),
                itemBuilder: (context, index) {
                  final category = categories[index];

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoryDetailScreen(
                            category: category,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFE5EAF0),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF0F6),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.category_outlined,
                              color: _navy,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProductsSection(AsyncValue<List<Product>> productsAsync) {
    return productsAsync.when(
      loading: () => const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => _errorMessage(
        'تعذر تحميل المنتجات.',
        () => ref.invalidate(productsProvider),
      ),
      data: (products) {
        if (products.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),
            child: Center(
              child: Text(
                'لا توجد منتجات معروضة حاليًا في المتجر.',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 600 ? 3 : 2;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length,
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 290,
                ),
                itemBuilder: (context, index) {
                  return ProductCard(
                    product: products[index],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _errorMessage(String message, VoidCallback onRetry) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EAF0)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                color: Colors.orange.shade800,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _navy,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'يرجى التأكد من اتصال الإنترنت ثم المحاولة مرة أخرى.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}