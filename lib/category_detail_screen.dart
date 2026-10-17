
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/models/category.dart';
import 'data/providers/category_provider.dart';
import 'data/providers/product_provider.dart';
import 'widgets/product_card.dart';

const _navy = Color(0xFF18334F);
const _gold = Color(0xFFF0AD35);
const _pageBackground = Color(0xFFF3F6FA);
const _border = Color(0xFFE5EAF0);
const _mutedText = Color(0xFF687586);

class CategoryDetailScreen extends ConsumerStatefulWidget {
  const CategoryDetailScreen({
    super.key,
    required this.category,
  });

  final Category category;

  @override
  ConsumerState<CategoryDetailScreen> createState() =>
      _CategoryDetailScreenState();
}

class _CategoryDetailScreenState
    extends ConsumerState<CategoryDetailScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final childrenAsync =
        ref.watch(childCategoriesProvider(widget.category.id));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _pageBackground,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text(
            widget.category.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: _navy,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh_rounded, color: _navy),
              onPressed: () {
                ref.invalidate(
                  childCategoriesProvider(widget.category.id),
                );
                ref.invalidate(
                  productsByCategoryProvider(widget.category.id),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: childrenAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: _navy),
            ),
            error: (error, stackTrace) => _buildErrorState(
              'تعذر تحميل التصنيفات الفرعية.',
              () => ref.invalidate(
                childCategoriesProvider(widget.category.id),
              ),
            ),
            data: (children) {
              if (children.isNotEmpty) {
                return _buildSubcategoriesView(children);
              }
              return _buildLeafCategoryProducts();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSubcategoriesView(List<Category> children) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _buildSectionHeading(
          title: 'التصنيفات الفرعية',
          subtitle: 'اختر القسم المناسب للوصول إلى المنتجات',
          icon: Icons.category_rounded,
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 124,
          ),
          itemBuilder: (context, index) {
            final childCategory = children[index];

            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryDetailScreen(
                        category: childCategory,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF0F6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.subdirectory_arrow_left_rounded,
                          color: _navy,
                          size: 25,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        childCategory.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          fontWeight: FontWeight.w800,
                          color: _navy,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLeafCategoryProducts() {
    final productsAsync =
        ref.watch(productsByCategoryProvider(widget.category.id));

    return productsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: _navy),
      ),
      error: (error, stackTrace) => _buildErrorState(
        'تعذر تحميل منتجات هذا التصنيف.',
        () => ref.invalidate(
          productsByCategoryProvider(widget.category.id),
        ),
      ),
      data: (products) {
        final filteredProducts = products.where((product) {
          return product.name
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
        }).toList();

        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeading(
                    title: widget.category.name,
                    subtitle: '${products.length} منتج في هذا التصنيف',
                    icon: Icons.inventory_2_outlined,
                  ),
                  if (products.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() => _searchQuery = value.trim());
                      },
                      decoration: InputDecoration(
                        hintText: 'ابحث في منتجات التصنيف...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: _mutedText,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: _navy,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                tooltip: 'مسح البحث',
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: _border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: _border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: _navy,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (filteredProducts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 44,
                ),
                child: _buildEmptyState(
                  icon: _searchQuery.isNotEmpty
                      ? Icons.search_off_rounded
                      : Icons.inventory_2_outlined,
                  message: _searchQuery.isNotEmpty
                      ? 'لم نجد منتجات تطابق بحثك داخل هذا التصنيف.'
                      : 'لا توجد منتجات متاحة في هذا التصنيف حاليًا.',
                ),
              )
            else
              Padding(
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
              ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeading({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _gold.withValues(alpha: 0.17),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: _navy, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: _navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: _mutedText,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
  }) {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF0F6),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(icon, size: 38, color: _navy),
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: _mutedText,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEEE),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Color(0xFFB42318),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: _navy,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
              style: FilledButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
