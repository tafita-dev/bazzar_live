import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';

final dashboardStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, sellerId) async {
  final client = ref.watch(supabaseClientProvider);
  
  // Fetch reservations count
  final reservationsData = await client
      .from('reservations')
      .select('id, products!inner(seller_id)')
      .eq('products.seller_id', sellerId);
  final reservationsCount = (reservationsData as List).length;

  // Fetch products count
  final productsData = await client
      .from('products')
      .select('id')
      .eq('seller_id', sellerId);
  final productsCount = (productsData as List).length;
      
  return {
    'reservations': reservationsCount,
    'products': productsCount,
    'sales': 0, // Placeholder
    'balance': 0.0, // Placeholder
  };
});
