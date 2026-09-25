import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user_profile.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _client;

  AuthRepositoryImpl(this._client);

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String role = 'client',
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'role': role},
    );
    final user = response.user;
    if (user != null) {
      debugPrint('Sign-up completed for user ${user.id} with role $role');
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Session? get currentSession => _client.auth.currentSession;

  @override
  Future<UserProfile?> getProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    debugPrint('Supabase profile response: $userId');
    if (response == null) return null;
    return UserProfile.fromJson(response);
  }

  @override
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? avatarUrl,
    String? phone,
    String? address,
    String? shopName,
    String? shopDescription,
  }) async {
    await _client
        .from('profiles')
        .update({
          'full_name': fullName,
          'avatar_url': avatarUrl,
          'phone': phone,
          'address': address,
          'shop_name': shopName,
          'shop_description': shopDescription,
        })
        .eq('id', userId);
  }

  @override
  Future<void> updateAvatar({
    required String userId,
    required String avatarUrl,
  }) async {
    await _client
        .from('profiles')
        .update({'avatar_url': avatarUrl})
        .eq('id', userId);
  }
}
