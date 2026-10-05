import '../models/category.dart';
import '../services/category_data_source.dart';

class CategoryRepository {
  final CategoryDataSource dataSource;

  const CategoryRepository(this.dataSource);

  Future<List<Category>> getCategories() {
    return dataSource.getCategories();
  }

  Future<List<Category>> getChildCategories(String parentId) {
    return dataSource.getChildCategories(parentId);
  }
}