import '../models/category.dart';

abstract class CategoryDataSource {
  Future<List<Category>> getCategories();

  Future<List<Category>> getChildCategories(String parentId);
}