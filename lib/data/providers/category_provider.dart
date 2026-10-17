
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category.dart';
import '../repositories/category_repository.dart';
import '../services/supabase_category_data_source.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final client = Supabase.instance.client;
  final dataSource = SupabaseCategoryDataSource(client);

  return CategoryRepository(dataSource);
});

final categoriesProvider = FutureProvider<List<Category>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getCategories();
});

final childCategoriesProvider =
    FutureProvider.family<List<Category>, String>((ref, parentId) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getChildCategories(parentId);
});

