import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/reservation.dart';

abstract class ReservationRepository {
  Future<List<Reservation>> getReservationsBySeller(String sellerId);
  Future<List<Reservation>> getReservationsByClient(String clientId);
  Future<Reservation?> getReservationById(String id);
  Future<void> updateReservationStatus(String id, String status);
  Future<void> createReservation(Reservation reservation);
}

class ReservationRepositoryImpl implements ReservationRepository {
  final SupabaseClient _client;

  ReservationRepositoryImpl(this._client);

  @override
  Future<List<Reservation>> getReservationsBySeller(String sellerId) async {
    print('--------------------------------------------------');
    print('DEBUG: FETCHING ALL RESERVATIONS FOR INSPECTION');
    print('--------------------------------------------------');
    
    try {
      final response = await _client
          .from('reservations')
          .select('*');
      
      final List<dynamic> data = response as List;
      
      print('DEBUG: TOTAL RESERVATIONS FETCHED FROM DB: ${data.length}');
      
      if (data.isNotEmpty) {
        print('DEBUG: SAMPLE RESERVATION STRUCTURE: ${data.first}');
      } else {
        print('DEBUG: NO RESERVATIONS FOUND IN DATABASE AT ALL.');
      }
      
      final filtered = data.where((res) {
        final List products = res['products'] as List;
        final isMatch = products.any((prod) => prod['seller_id'] == sellerId);
        if (isMatch) {
            print('DEBUG: FOUND MATCHING RESERVATION ID: ${res['id']}');
        }
        return isMatch;
      }).toList();
      
      print('RESERVATION REPOSITORY: FINAL FILTERED COUNT: ${filtered.length}');
      
      return filtered.map((json) => Reservation.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      print('RESERVATION REPOSITORY: POSTGREST ERROR: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      print('RESERVATION REPOSITORY: GENERAL ERROR: $e');
      print('RESERVATION REPOSITORY: STACKTRACE: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<List<Reservation>> getReservationsByClient(String clientId) async {
    final response = await _client
        .from('reservations')
        .select('*')
        .eq('user_id', clientId)
        .order('created_at', ascending: false);
        
    return (response as List).map((json) => Reservation.fromJson(json)).toList();
  }

  @override
  Future<Reservation?> getReservationById(String id) async {
    final response = await _client
        .from('reservations')
        .select('*')
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return Reservation.fromJson(response);
  }

  @override
  Future<void> updateReservationStatus(String id, String status) async {
    await _client.from('reservations').update({'status': status}).eq('id', id);
  }

  @override
  Future<void> createReservation(Reservation reservation) async {
    await _client.from('reservations').insert(reservation.toJson());
  }
}
