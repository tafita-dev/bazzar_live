import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../domain/entities/product.dart';

final productsByCategoryProvider = FutureProvider.family<List<Product>, String>((ref, categoryId) async {
  if (categoryId.isEmpty) return [];
  final client = ref.watch(supabaseClientProvider);
  final response = await client.from('products').select().eq('category_id', categoryId);
  return (response as List).map((json) => Product.fromJson(json)).toList();
});

final sellerProductsProvider = FutureProvider.family<List<Product>, String>((ref, sellerId) async {
  if (sellerId.isEmpty) return [];
  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('products')
      .select()
      .eq('seller_id', sellerId)
      .order('created_at', ascending: false);
  return (response as List).map((json) => Product.fromJson(json)).toList();
});
