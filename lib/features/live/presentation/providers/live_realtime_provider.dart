import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../products/presentation/providers/product_provider.dart';

// 1. Un provider qui gère la souscription au canal Realtime
final productRealtimeProvider = StreamProvider.family<dynamic, String>((ref, sellerId) {
  final supabase = Supabase.instance.client;
  final controller = StreamController<dynamic>();

  final channel = supabase
      .channel('public:products:seller_$sellerId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'products',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'seller_id',
          value: sellerId,
        ),
        callback: (payload) {
          // Au lieu d'invalider ici, on envoie le payload dans le stream
          controller.add(payload);
          // On invalide le provider des produits pour forcer le rafraîchissement global
          ref.invalidate(sellerProductsProvider(sellerId));
        },
      )
      .subscribe();

  ref.onDispose(() {
    supabase.removeChannel(channel);
    controller.close();
  });

  return controller.stream;
});
