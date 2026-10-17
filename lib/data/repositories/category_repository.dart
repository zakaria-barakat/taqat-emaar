import '../models/category.dart';
import '../services/category_data_source.dart';

class CategoryRepository {
  final CategoryDataSource dataSource;

  CategoryRepository(this.dataSource);

  static const Duration _cacheTtl = Duration(minutes: 5);

  List<Category>? _cachedCategories;
  DateTime? _categoriesCachedAt;

  final Map<String, List<Category>> _cachedChildCategories = {};
  final Map<String, DateTime> _childCategoriesCachedAt = {};

  void clearCache() {
    _cachedCategories = null;
    _categoriesCachedAt = null;
    _cachedChildCategories.clear();
    _childCategoriesCachedAt.clear();
  }

  Future<List<Category>> getCategories({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedCategories != null &&
        _categoriesCachedAt != null &&
        now.difference(_categoriesCachedAt!) < _cacheTtl) {
      return _cachedCategories!;
    }

    try {
      final fresh = await dataSource.getCategories();
      _cachedCategories = fresh;
      _categoriesCachedAt = now;
      return fresh;
    } catch (e) {
      if (_cachedCategories != null) {
        return _cachedCategories!;
      }
      rethrow;
    }
  }

  Future<List<Category>> getChildCategories(String parentId, {bool forceRefresh = false}) async {
    final now = DateTime.now();
    final cached = _cachedChildCategories[parentId];
    final cachedAt = _childCategoriesCachedAt[parentId];

    if (!forceRefresh &&
        cached != null &&
        cachedAt != null &&
        now.difference(cachedAt) < _cacheTtl) {
      return cached;
    }

    try {
      final fresh = await dataSource.getChildCategories(parentId);
      _cachedChildCategories[parentId] = fresh;
      _childCategoriesCachedAt[parentId] = now;
      return fresh;
    } catch (e) {
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }
}