import 'package:freezed_annotation/freezed_annotation.dart';

part 'reservation.freezed.dart';
part 'reservation.g.dart';

@freezed
class Reservation with _$Reservation {
  const factory Reservation({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'client_info') required Map<String, dynamic> clientInfo,
    @JsonKey(name: 'payment_method_id') required String paymentMethodId,
    @JsonKey(name: 'total_amount', defaultValue: 0.0) double? totalAmount,
    required List<Map<String, dynamic>> products,
    @JsonKey(name: 'group_name') Map<String, dynamic>? groupName,
    @Default('pending') String status,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Reservation;

  factory Reservation.fromJson(Map<String, dynamic> json) => _$ReservationFromJson(json);
}
