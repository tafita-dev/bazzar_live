import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/user_profile.dart';

abstract class AuthRepository {
  Stream<AuthState> get authStateChanges;
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String role = 'client',
  });
  Future<void> signOut();
  Session? get currentSession;
  Future<UserProfile?> getProfile(String userId);
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? avatarUrl,
    String? phone,
    String? address,
    String? shopName,
    String? shopDescription,
  });

  Future<void> updateAvatar({
    required String userId,
    required String avatarUrl,
  });
}
