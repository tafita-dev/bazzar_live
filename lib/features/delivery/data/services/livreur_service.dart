import 'package:supabase_flutter/supabase_flutter.dart';

class LivreurService {
  final SupabaseClient _supabase;

  LivreurService(this._supabase);

  Future<void> createLivreur({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String? avatarUrl,
  }) async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('Utilisateur non connecté');
      }

      await _supabase.functions.invoke(
        'create-livreur',
        body: {
          'email': email,
          'password': password,
          'fullName': fullName,
          'phone': phone,
          'avatarUrl': avatarUrl,
        },
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
        },
      );
    } catch (e) {
      throw Exception('Failed to create livreur: $e');
    }
  }

  Future<void> deleteLivreur(String livreurId) async {
    try {
      await _supabase.from('profiles').delete().eq('id', livreurId);
    } catch (e) {
      throw Exception('Failed to delete livreur: $e');
    }
  }

  Future<void> updateLivreur(String livreurId, Map<String, dynamic> data) async {
    try {
      await _supabase.from('profiles').update(data).eq('id', livreurId);
    } catch (e) {
      throw Exception('Failed to update livreur: $e');
    }
  }
}
