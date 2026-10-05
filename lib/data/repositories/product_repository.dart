import '../models/product.dart';
import '../services/product_data_source.dart';

class ProductRepository {
  final ProductDataSource dataSource;

  const ProductRepository(this.dataSource);

  Future<List<Product>> getProducts() {
    return dataSource.getProducts();
  }

  Future<List<Product>> getProductsByCategory(String categoryId) {
    return dataSource.getProductsByCategory(categoryId);
  }

  Future<Product?> getProductById(String id) {
    return dataSource.getProductById(id);
  }
}