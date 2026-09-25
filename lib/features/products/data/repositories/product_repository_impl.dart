import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts();
  Future<void> createProduct(Product product);
  Future<void> updateProduct(Product product);
  Future<void> deleteProduct(String id);
}

class ProductRepositoryImpl implements ProductRepository {
  final SupabaseClient _client;

  ProductRepositoryImpl(this._client);

  @override
  Future<List<Product>> getProducts() async {
    final response = await _client.from('products').select();
    return (response as List).map((json) => Product.fromJson(json)).toList();
  }

  @override
  Future<void> createProduct(Product product) async {
    final data = product.toJson();
    // Since toJson() already uses snake_case due to @JsonKey, 
    // we don't need to manually remap keys.
    await _client.from('products').insert(data);
  }

  @override
  Future<void> updateProduct(Product product) async {
    final data = product.toJson();
    await _client.from('products').update(data).eq('id', product.id);
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _client.from('products').delete().eq('id', id);
  }
}
