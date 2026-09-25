import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../data/repositories/reservation_repository_impl.dart';
import '../../domain/entities/reservation.dart';

final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  return ReservationRepositoryImpl(ref.watch(supabaseClientProvider));
});

final sellerReservationsProvider = FutureProvider.family<List<Reservation>, String>((ref, sellerId) async {
  debugPrint('--------------------------------------------------');
  debugPrint('RESERVATION_PROVIDER: EXECUTING. SELLER_ID: $sellerId');
  debugPrint('--------------------------------------------------');
  final repository = ref.watch(reservationRepositoryProvider);
  return await repository.getReservationsBySeller(sellerId);
});

final clientReservationsProvider = FutureProvider.family<List<Reservation>, String>((ref, clientId) async {
  final repository = ref.watch(reservationRepositoryProvider);
  return await repository.getReservationsByClient(clientId);
});
