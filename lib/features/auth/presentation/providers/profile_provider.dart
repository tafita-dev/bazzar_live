import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_profile.dart';

final profileProvider = StreamProvider.family<UserProfile?, String>((ref, userId) {
  if (userId.isEmpty) {
    return Stream.value(null);
  }
  final supabase = Supabase.instance.client;
  return supabase
      .from('profiles')
      .stream(primaryKey: ['id'])
      .eq('id', userId)
      .map((data) {
        if (data.isEmpty) return null;
        return UserProfile.fromJson(data.first);
      });
});
