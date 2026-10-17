
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';
import 'product_data_source.dart';

class SupabaseProductDataSource implements ProductDataSource {
  final SupabaseClient client;

  SupabaseProductDataSource(this.client);

  static const String _productSelect = '''
    *,
    product_images (
      id,
      product_id,
      url,
      sort_order
    )
  ''';

  @override
  Future<List<Product>> getProducts() async {
    final response = await client
        .from('products')
        .select(_productSelect)
        .eq('is_active', true)
        .order('name');

    return response
        .map((json) => Product.fromJson(json))
        .toList();
  }

  @override
  Future<List<Product>> getProductsByCategory(String categoryId) async {
    final response = await client
        .from('products')
        .select(_productSelect)
        .eq('is_active', true)
        .eq('category_id', categoryId)
        .order('name');

    return response
        .map((json) => Product.fromJson(json))
        .toList();
  }

  @override
  Future<Product?> getProductById(String id) async {
    final response = await client
        .from('products')
        .select(_productSelect)
        .eq('id', id)
        .eq('is_active', true)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return Product.fromJson(response);
  }
}
