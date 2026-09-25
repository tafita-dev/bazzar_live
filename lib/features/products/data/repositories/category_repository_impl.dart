import 'package:supabase_flutter/supabase_flutter.dart';

abstract class CategoryRepository {
  Future<void> createCategory(String name, String sellerId);
  Future<void> updateCategory(String categoryId, String newName);
  Future<void> deleteCategory(String categoryId);
}

class CategoryRepositoryImpl implements CategoryRepository {
  final SupabaseClient _client;

  CategoryRepositoryImpl(this._client);

  @override
  Future<void> createCategory(String name, String sellerId) async {
    await _client.from('categories').insert({
      'name': name,
      'seller_id': sellerId,
    });
  }

  @override
  Future<void> updateCategory(String categoryId, String newName) async {
    await _client.from('categories').update({
      'name': newName,
    }).eq('id', categoryId);
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    // Delete all products in this category first
    await _client.from('products').delete().eq('category_id', categoryId);
    // Delete the category itself
    await _client.from('categories').delete().eq('id', categoryId);
  }
}
