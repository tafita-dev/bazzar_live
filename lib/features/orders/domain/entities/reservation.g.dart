// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReservationImpl _$$ReservationImplFromJson(Map<String, dynamic> json) =>
    _$ReservationImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      clientInfo: json['client_info'] as Map<String, dynamic>,
      paymentMethodId: json['payment_method_id'] as String,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      products: (json['products'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      groupName: json['group_name'] as Map<String, dynamic>?,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$ReservationImplToJson(_$ReservationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'client_info': instance.clientInfo,
      'payment_method_id': instance.paymentMethodId,
      'total_amount': instance.totalAmount,
      'products': instance.products,
      'group_name': instance.groupName,
      'status': instance.status,
      'created_at': instance.createdAt?.toIso8601String(),
    };
