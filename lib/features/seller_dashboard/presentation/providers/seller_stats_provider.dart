import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:live_shopping/core/providers/supabase_provider.dart';
import '../../domain/entities/seller_stats.dart';

final sellerStatsProvider = FutureProvider.autoDispose<SellerStats>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;
  if (user == null) throw Exception('Utilisateur non connecté');

  final sellerId = user.id;

  // 1. Récupérer les réservations
  final reservationsResponse = await client
      .from('reservations')
      .select('status, total_amount, group_name');

  // Correction : Cast sécurisé vers List<Map<String, dynamic>>
  final List<Map<String, dynamic>> reservations = (reservationsResponse as List<dynamic>)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();

  // Filtrer les réservations pour ce vendeur
  final sellerReservations = reservations.where((r) {
    final groupName = r['group_name'] as Map<String, dynamic>?;
    // Utilisation sécurisée avec .toString() pour éviter les erreurs de type cast si la valeur est nulle
    return groupName != null && groupName['seller_id']?.toString() == sellerId;
  }).toList();
  
  int orders = sellerReservations.length;
  int sales = sellerReservations.where((r) => r['status'] == 'delivered' || r['status'] == 'validated').length;
  double revenue = sellerReservations
      .where((r) => r['status'] == 'delivered' || r['status'] == 'validated')
      .fold(0.0, (sum, r) => sum + ((r['total_amount'] as num?)?.toDouble() ?? 0.0));

  // 2. Récupérer les lives
  final livesResponse = await client
      .from('lives')
      .select('id')
      .eq('seller_id', sellerId);
  
  int activeLives = (livesResponse as List<dynamic>).length;

  return SellerStats(
    sales: sales,
    revenue: revenue,
    orders: orders,
    liveViews: activeLives * 150, // Estimation basée sur les lives
  );
});
