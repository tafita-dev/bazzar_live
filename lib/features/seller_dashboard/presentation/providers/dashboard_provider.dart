import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:live_shopping/core/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final dashboardStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, sellerId) async {
  if (sellerId.isEmpty) return {};
  final supabase = ref.read(supabaseClientProvider);

  try {
    final response = await supabase.rpc('get_seller_dashboard_stats', params: {
      'p_seller_id': sellerId,
    });

    return Map<String, dynamic>.from(response);
  } catch (e) {
    debugPrint('Error getting dashboard stats: $e');
    return {};
  }
});

// Provider pour gérer la souscription Realtime
final dashboardRealtimeProvider = StreamProvider.family<dynamic, String>((ref, sellerId) {
  if (sellerId.isEmpty) return const Stream.empty();
  final supabase = ref.read(supabaseClientProvider);
  final controller = StreamController<dynamic>();

  final channel = supabase
      .channel('public:reservations:seller_$sellerId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'reservations',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'seller_id',
          value: sellerId,
        ),
        callback: (payload) {
          // Invalider le provider pour forcer le rafraîchissement
          ref.invalidate(dashboardStatsProvider(sellerId));
          controller.add(payload);
        },
      )
      .subscribe(
        (status, reason) => debugPrint('Realtime status: $status'),
      );

  ref.onDispose(() {
    supabase.removeChannel(channel);
    controller.close();
  });

  return controller.stream;
});
