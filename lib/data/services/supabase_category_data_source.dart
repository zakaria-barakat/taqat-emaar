
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category.dart';
import 'category_data_source.dart';

class SupabaseCategoryDataSource implements CategoryDataSource {
  final SupabaseClient client;

  SupabaseCategoryDataSource(this.client);

  @override
  Future<List<Category>> getCategories() async {
    final response = await client
        .from('categories')
        .select()
        .isFilter('parent_id', null)
        .eq('is_active', true)
        .order('sort_order');

    return response
        .map((json) => Category.fromJson(json))
        .toList();
  }

  @override
  Future<List<Category>> getChildCategories(String parentId) async {
    final response = await client
        .from('categories')
        .select()
        .eq('parent_id', parentId)
        .eq('is_active', true)
        .order('sort_order');

    return response
        .map((json) => Category.fromJson(json))
        .toList();
  }
}
