import 'package:freezed_annotation/freezed_annotation.dart';

part 'live_session.freezed.dart';
part 'live_session.g.dart';

@freezed
class LiveSession with _$LiveSession {
  const factory LiveSession({
    required String id,
    required String title,
    required String facebookUrl,
    required String sellerId,
    @Default(false) bool isActive,
    DateTime? startedAt,
  }) = _LiveSession;

  factory LiveSession.fromJson(Map<String, dynamic> json) => _$LiveSessionFromJson(json);
}
