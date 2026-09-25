import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:live_shopping/core/providers/supabase_provider.dart';
import 'package:live_shopping/features/auth/domain/entities/user_profile.dart';
import 'package:live_shopping/features/delivery/data/services/livreur_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deliverer_provider.g.dart';

@riverpod
LivreurService livreurService(LivreurServiceRef ref) {
  return LivreurService(ref.watch(supabaseClientProvider));
}

@riverpod
class DelivererNotifier extends _$DelivererNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> createLivreur({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String? avatarUrl,
  }) async {
    state = await AsyncValue.guard(() async {
      await ref.read(livreurServiceProvider).createLivreur(
            email: email,
            password: password,
            fullName: fullName,
            phone: phone,
            avatarUrl: avatarUrl,
          );
    });
  }

  Future<void> deleteLivreur(String livreurId) async {
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(livreurServiceProvider).deleteLivreur(livreurId);
        debugPrint('DEBUG: Livreur supprimé avec succès: $livreurId');
      } catch (e) {
        debugPrint('DEBUG: Erreur lors de la suppression du livreur $livreurId: $e');
        rethrow;
      }
    });
  }

  Future<void> updateLivreur(String livreurId, Map<String, dynamic> data) async {
    state = await AsyncValue.guard(() async {
      await ref.read(livreurServiceProvider).updateLivreur(livreurId, data);
    });
  }
}

@riverpod
Stream<List<UserProfile>> sellerDeliverers(SellerDeliverersRef ref, String sellerId) {
  if (sellerId.isEmpty) return Stream.value([]);
  final supabase = ref.watch(supabaseClientProvider);
  return supabase
      .from('profiles')
      .stream(primaryKey: ['id'])
      .eq('added_by', sellerId)
      .eq('role', 'livreur')
      .map((data) => data.map((json) => UserProfile.fromJson(json)).toList());
}

/// Commandes en cours assignées au livreur (statut: in_delivery)
final delivererActiveDeliveriesProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, delivererId) {
  if (delivererId.isEmpty) return Stream.value([]);
  final supabase = ref.watch(supabaseClientProvider);
  return supabase
      .from('reservations')
      .stream(primaryKey: ['id'])
      .eq('deliverer_id', delivererId)
      .map((list) {
        final filtered = list.where((r) => r['status'] == 'in_delivery').toList();
        filtered.sort((a, b) {
          final dateA = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(1970);
          final dateB = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(1970);
          return dateB.compareTo(dateA);
        });
        return filtered;
      });
});

/// Historique des commandes livrées par le livreur (statut: delivered)
final delivererHistoryProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, delivererId) {
  if (delivererId.isEmpty) return Stream.value([]);
  final supabase = ref.watch(supabaseClientProvider);
  return supabase
      .from('reservations')
      .stream(primaryKey: ['id'])
      .eq('deliverer_id', delivererId)
      .map((list) {
        final filtered = list.where((r) => r['status'] == 'delivered').toList();
        filtered.sort((a, b) {
          final dateA = DateTime.tryParse(
                  a['delivered_at']?.toString() ?? a['created_at']?.toString() ?? '') ??
              DateTime(1970);
          final dateB = DateTime.tryParse(
                  b['delivered_at']?.toString() ?? b['created_at']?.toString() ?? '') ??
              DateTime(1970);
          return dateB.compareTo(dateA);
        });
        return filtered;
      });
});

/// Statistiques du livreur
final delivererStatsProvider =
    Provider.family<Map<String, dynamic>, String>((ref, delivererId) {
  final historyAsync = ref.watch(delivererHistoryProvider(delivererId));
  return historyAsync.maybeWhen(
    data: (orders) {
      final totalDelivered = orders.length;
      final now = DateTime.now();
      final todayCount = orders.where((o) {
        final deliveredAtStr = o['delivered_at']?.toString();
        if (deliveredAtStr == null) return false;
        final d = DateTime.tryParse(deliveredAtStr)?.toLocal();
        return d != null && d.year == now.year && d.month == now.month && d.day == now.day;
      }).length;

      final totalRevenue = orders.fold<double>(0.0, (sum, o) {
        final amount = (o['total_amount'] as num?)?.toDouble() ?? 0.0;
        return sum + amount;
      });

      return {
        'total_delivered': totalDelivered,
        'today_delivered': todayCount,
        'total_revenue': totalRevenue,
      };
    },
    orElse: () => {
      'total_delivered': 0,
      'today_delivered': 0,
      'total_revenue': 0.0,
    },
  );
});

/// Récupérer une réservation par QR token ou ID
Future<Map<String, dynamic>> lookupReservationByQr({
  required SupabaseClient supabase,
  required String qrValue,
  required String delivererId,
}) async {
  // 1. Nettoyage de la valeur scannée / saisie
  String cleanValue = qrValue.trim();

  // Enlever le préfixe '#' si présent
  if (cleanValue.startsWith('#')) {
    cleanValue = cleanValue.substring(1).trim();
  }

  // Si c'est un format JSON (ex: {"id": "..."} ou {"reservation_id": "..."})
  if (cleanValue.startsWith('{') && cleanValue.endsWith('}')) {
    try {
      final decoded = jsonDecode(cleanValue);
      if (decoded is Map) {
        cleanValue = (decoded['id'] ??
                decoded['reservation_id'] ??
                decoded['qr_token'] ??
                cleanValue)
            .toString()
            .trim();
      }
    } catch (_) {}
  } else if (cleanValue.contains('id=')) {
    // Si c'est une URL avec paramètre id=...
    final uri = Uri.tryParse(cleanValue);
    if (uri != null && uri.queryParameters.containsKey('id')) {
      cleanValue = uri.queryParameters['id']!.trim();
    }
  }

  final isFullUuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(cleanValue);

  // 2. Essai via la fonction RPC get_reservation_for_deliverer
  try {
    final response = await supabase.rpc('get_reservation_for_deliverer', params: {
      'p_qr_value': cleanValue,
      'p_deliverer_id': delivererId.isNotEmpty ? delivererId : null,
    });
    if (response != null && response is Map) {
      return Map<String, dynamic>.from(response);
    }
  } catch (e) {
    debugPrint('[DELIVERER_LOOKUP] RPC error: $e, executing direct fallback queries');
  }

  // 3. Fallback: recherche directe sur la table reservations
  List<dynamic> results = [];

  // 3a. Recherche par ID UUID exact
  if (isFullUuid) {
    try {
      results = await supabase
          .from('reservations')
          .select('*')
          .eq('id', cleanValue.toLowerCase())
          .limit(1);
    } catch (e) {
      debugPrint('[DELIVERER_LOOKUP] direct id lookup error: $e');
    }
  }

  // 3b. Recherche par préfixe d'ID (au moins 8 caractères hexadécimaux)
  if (results.isEmpty &&
      cleanValue.length >= 8 &&
      RegExp(r'^[0-9a-fA-F\-]+$').hasMatch(cleanValue)) {
    try {
      results = await supabase
          .from('reservations')
          .select('*')
          .ilike('id', '${cleanValue.toLowerCase()}%')
          .order('created_at', ascending: false)
          .limit(1);
    } catch (e) {
      debugPrint('[DELIVERER_LOOKUP] direct id prefix lookup error: $e');
    }
  }

  // 3c. Recherche par qr_token
  if (results.isEmpty) {
    try {
      results = await supabase
          .from('reservations')
          .select('*')
          .eq('qr_token', cleanValue)
          .limit(1);
    } catch (e) {
      debugPrint('[DELIVERER_LOOKUP] direct qr_token lookup error: $e');
    }
  }

  // 3d. Recherche par order_group_id (si UUID complet)
  if (results.isEmpty && isFullUuid) {
    try {
      results = await supabase
          .from('reservations')
          .select('*')
          .eq('order_group_id', cleanValue.toLowerCase())
          .limit(1);
    } catch (e) {
      debugPrint('[DELIVERER_LOOKUP] direct order_group_id lookup error: $e');
    }
  }

  if (results.isEmpty) {
    throw Exception('Aucune commande trouvée pour ce QR code / identifiant');
  }

  final reservation = Map<String, dynamic>.from(results.first as Map);
  final assignedDeliverer = reservation['deliverer_id']?.toString();

  if (delivererId.isNotEmpty &&
      assignedDeliverer != null &&
      assignedDeliverer.isNotEmpty &&
      assignedDeliverer != delivererId) {
    throw Exception('Cette commande est assignée à un autre livreur');
  }

  return reservation;
}

/// Marquer une réservation comme livrée
Future<void> markReservationDelivered({
  required SupabaseClient supabase,
  required String reservationId,
  required String delivererId,
}) async {
  try {
    await supabase.rpc('mark_reservation_delivered_by_deliverer', params: {
      'p_reservation_id': reservationId,
      'p_deliverer_id': delivererId,
    });
  } catch (_) {
    // Fallback: mise à jour directe
    await supabase
        .from('reservations')
        .update({
          'status': 'delivered',
          'deliverer_id': delivererId,
          'delivered_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', reservationId);
  }
}
