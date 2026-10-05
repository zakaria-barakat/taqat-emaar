import '../models/product.dart';

abstract class ProductDataSource {
  Future<List<Product>> getProducts();

  Future<List<Product>> getProductsByCategory(String categoryId);

  Future<Product?> getProductById(String id);
}