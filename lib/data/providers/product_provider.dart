import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';
import '../repositories/product_repository.dart';
import '../services/supabase_product_data_source.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final client = Supabase.instance.client;
  final dataSource = SupabaseProductDataSource(client);

  return ProductRepository(dataSource);
});

final productsProvider = FutureProvider<List<Product>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getProducts();
});

final productsByCategoryProvider =
    FutureProvider.family<List<Product>, String>((ref, categoryId) {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getProductsByCategory(categoryId);
});

final productByIdProvider =
    FutureProvider.family<Product?, String>((ref, productId) {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getProductById(productId);
});
