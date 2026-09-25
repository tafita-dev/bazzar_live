import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import 'package:live_shopping/features/products/domain/entities/category.dart';

final categoriesProvider = FutureProvider.family<List<Category>, String>((ref, sellerId) async {
  if (sellerId.isEmpty) return [];
  final client = ref.watch(supabaseClientProvider);

  final response = await client
      .from('categories')
      .select()
      .eq('seller_id', sellerId);

  return (response as List).map((json) => Category.fromJson(json)).toList();
});
