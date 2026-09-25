// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LiveSessionImpl _$$LiveSessionImplFromJson(Map<String, dynamic> json) =>
    _$LiveSessionImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      facebookUrl: json['facebookUrl'] as String,
      sellerId: json['sellerId'] as String,
      isActive: json['isActive'] as bool? ?? false,
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
    );

Map<String, dynamic> _$$LiveSessionImplToJson(_$LiveSessionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'facebookUrl': instance.facebookUrl,
      'sellerId': instance.sellerId,
      'isActive': instance.isActive,
      'startedAt': instance.startedAt?.toIso8601String(),
    };
