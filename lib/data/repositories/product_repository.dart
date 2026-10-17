import '../models/product.dart';
import '../services/product_data_source.dart';

class ProductRepository {
  final ProductDataSource dataSource;

  ProductRepository(this.dataSource);

  static const Duration _cacheTtl = Duration(minutes: 5);

  List<Product>? _cachedProducts;
  DateTime? _productsCachedAt;

  final Map<String, List<Product>> _cachedCategoryProducts = {};
  final Map<String, DateTime> _categoryProductsCachedAt = {};

  final Map<String, Product> _cachedProductById = {};

  void clearCache() {
    _cachedProducts = null;
    _productsCachedAt = null;
    _cachedCategoryProducts.clear();
    _categoryProductsCachedAt.clear();
    _cachedProductById.clear();
  }

  Future<List<Product>> getProducts({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedProducts != null &&
        _productsCachedAt != null &&
        now.difference(_productsCachedAt!) < _cacheTtl) {
      return _cachedProducts!;
    }

    try {
      final fresh = await dataSource.getProducts();
      _cachedProducts = fresh;
      _productsCachedAt = now;
      for (final p in fresh) {
        _cachedProductById[p.id] = p;
      }
      return fresh;
    } catch (e) {
      if (_cachedProducts != null) {
        return _cachedProducts!;
      }
      rethrow;
    }
  }

  Future<List<Product>> getProductsByCategory(String categoryId, {bool forceRefresh = false}) async {
    final now = DateTime.now();
    final cached = _cachedCategoryProducts[categoryId];
    final cachedAt = _categoryProductsCachedAt[categoryId];

    if (!forceRefresh &&
        cached != null &&
        cachedAt != null &&
        now.difference(cachedAt) < _cacheTtl) {
      return cached;
    }

    try {
      final fresh = await dataSource.getProductsByCategory(categoryId);
      _cachedCategoryProducts[categoryId] = fresh;
      _categoryProductsCachedAt[categoryId] = now;
      for (final p in fresh) {
        _cachedProductById[p.id] = p;
      }
      return fresh;
    } catch (e) {
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }

  Future<Product?> getProductById(String id, {bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedProductById.containsKey(id)) {
      return _cachedProductById[id];
    }

    try {
      final fresh = await dataSource.getProductById(id);
      if (fresh != null) {
        _cachedProductById[id] = fresh;
      }
      return fresh;
    } catch (e) {
      if (_cachedProductById.containsKey(id)) {
        return _cachedProductById[id];
      }
      rethrow;
    }
  }
}