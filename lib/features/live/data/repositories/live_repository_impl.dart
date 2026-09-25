import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/live_session.dart';

abstract class LiveRepository {
  Future<List<LiveSession>> getActiveLives();
  Future<void> createLive(LiveSession live);
  Future<void> updateLive(LiveSession live);
}

class LiveRepositoryImpl implements LiveRepository {
  final SupabaseClient _client;

  LiveRepositoryImpl(this._client);

  @override
  Future<List<LiveSession>> getActiveLives() async {
    final response = await _client.from('lives').select().eq('is_active', true);
    return (response as List).map((json) => LiveSession.fromJson(json)).toList();
  }

  @override
  Future<void> createLive(LiveSession live) async {
    await _client.from('lives').insert(live.toJson());
  }

  @override
  Future<void> updateLive(LiveSession live) async {
    await _client.from('lives').update(live.toJson()).eq('id', live.id);
  }
}
