// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reservation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Reservation _$ReservationFromJson(Map<String, dynamic> json) {
  return _Reservation.fromJson(json);
}

/// @nodoc
mixin _$Reservation {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_info')
  Map<String, dynamic> get clientInfo => throw _privateConstructorUsedError;
  @JsonKey(name: 'payment_method_id')
  String get paymentMethodId => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_amount', defaultValue: 0.0)
  double? get totalAmount => throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get products => throw _privateConstructorUsedError;
  @JsonKey(name: 'group_name')
  Map<String, dynamic>? get groupName => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this Reservation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Reservation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReservationCopyWith<Reservation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReservationCopyWith<$Res> {
  factory $ReservationCopyWith(
    Reservation value,
    $Res Function(Reservation) then,
  ) = _$ReservationCopyWithImpl<$Res, Reservation>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'user_id') String userId,
    @JsonKey(name: 'client_info') Map<String, dynamic> clientInfo,
    @JsonKey(name: 'payment_method_id') String paymentMethodId,
    @JsonKey(name: 'total_amount', defaultValue: 0.0) double? totalAmount,
    List<Map<String, dynamic>> products,
    @JsonKey(name: 'group_name') Map<String, dynamic>? groupName,
    String status,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  });
}

/// @nodoc
class _$ReservationCopyWithImpl<$Res, $Val extends Reservation>
    implements $ReservationCopyWith<$Res> {
  _$ReservationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Reservation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? clientInfo = null,
    Object? paymentMethodId = null,
    Object? totalAmount = freezed,
    Object? products = null,
    Object? groupName = freezed,
    Object? status = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            clientInfo: null == clientInfo
                ? _value.clientInfo
                : clientInfo // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
            paymentMethodId: null == paymentMethodId
                ? _value.paymentMethodId
                : paymentMethodId // ignore: cast_nullable_to_non_nullable
                      as String,
            totalAmount: freezed == totalAmount
                ? _value.totalAmount
                : totalAmount // ignore: cast_nullable_to_non_nullable
                      as double?,
            products: null == products
                ? _value.products
                : products // ignore: cast_nullable_to_non_nullable
                      as List<Map<String, dynamic>>,
            groupName: freezed == groupName
                ? _value.groupName
                : groupName // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReservationImplCopyWith<$Res>
    implements $ReservationCopyWith<$Res> {
  factory _$$ReservationImplCopyWith(
    _$ReservationImpl value,
    $Res Function(_$ReservationImpl) then,
  ) = __$$ReservationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'user_id') String userId,
    @JsonKey(name: 'client_info') Map<String, dynamic> clientInfo,
    @JsonKey(name: 'payment_method_id') String paymentMethodId,
    @JsonKey(name: 'total_amount', defaultValue: 0.0) double? totalAmount,
    List<Map<String, dynamic>> products,
    @JsonKey(name: 'group_name') Map<String, dynamic>? groupName,
    String status,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  });
}

/// @nodoc
class __$$ReservationImplCopyWithImpl<$Res>
    extends _$ReservationCopyWithImpl<$Res, _$ReservationImpl>
    implements _$$ReservationImplCopyWith<$Res> {
  __$$ReservationImplCopyWithImpl(
    _$ReservationImpl _value,
    $Res Function(_$ReservationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Reservation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? clientInfo = null,
    Object? paymentMethodId = null,
    Object? totalAmount = freezed,
    Object? products = null,
    Object? groupName = freezed,
    Object? status = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$ReservationImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        clientInfo: null == clientInfo
            ? _value._clientInfo
            : clientInfo // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        paymentMethodId: null == paymentMethodId
            ? _value.paymentMethodId
            : paymentMethodId // ignore: cast_nullable_to_non_nullable
                  as String,
        totalAmount: freezed == totalAmount
            ? _value.totalAmount
            : totalAmount // ignore: cast_nullable_to_non_nullable
                  as double?,
        products: null == products
            ? _value._products
            : products // ignore: cast_nullable_to_non_nullable
                  as List<Map<String, dynamic>>,
        groupName: freezed == groupName
            ? _value._groupName
            : groupName // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ReservationImpl implements _Reservation {
  const _$ReservationImpl({
    required this.id,
    @JsonKey(name: 'user_id') required this.userId,
    @JsonKey(name: 'client_info')
    required final Map<String, dynamic> clientInfo,
    @JsonKey(name: 'payment_method_id') required this.paymentMethodId,
    @JsonKey(name: 'total_amount', defaultValue: 0.0) this.totalAmount,
    required final List<Map<String, dynamic>> products,
    @JsonKey(name: 'group_name') final Map<String, dynamic>? groupName,
    this.status = 'pending',
    @JsonKey(name: 'created_at') this.createdAt,
  }) : _clientInfo = clientInfo,
       _products = products,
       _groupName = groupName;

  factory _$ReservationImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReservationImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  final Map<String, dynamic> _clientInfo;
  @override
  @JsonKey(name: 'client_info')
  Map<String, dynamic> get clientInfo {
    if (_clientInfo is EqualUnmodifiableMapView) return _clientInfo;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_clientInfo);
  }

  @override
  @JsonKey(name: 'payment_method_id')
  final String paymentMethodId;
  @override
  @JsonKey(name: 'total_amount', defaultValue: 0.0)
  final double? totalAmount;
  final List<Map<String, dynamic>> _products;
  @override
  List<Map<String, dynamic>> get products {
    if (_products is EqualUnmodifiableListView) return _products;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_products);
  }

  final Map<String, dynamic>? _groupName;
  @override
  @JsonKey(name: 'group_name')
  Map<String, dynamic>? get groupName {
    final value = _groupName;
    if (value == null) return null;
    if (_groupName is EqualUnmodifiableMapView) return _groupName;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @override
  String toString() {
    return 'Reservation(id: $id, userId: $userId, clientInfo: $clientInfo, paymentMethodId: $paymentMethodId, totalAmount: $totalAmount, products: $products, groupName: $groupName, status: $status, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReservationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            const DeepCollectionEquality().equals(
              other._clientInfo,
              _clientInfo,
            ) &&
            (identical(other.paymentMethodId, paymentMethodId) ||
                other.paymentMethodId == paymentMethodId) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            const DeepCollectionEquality().equals(other._products, _products) &&
            const DeepCollectionEquality().equals(
              other._groupName,
              _groupName,
            ) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    const DeepCollectionEquality().hash(_clientInfo),
    paymentMethodId,
    totalAmount,
    const DeepCollectionEquality().hash(_products),
    const DeepCollectionEquality().hash(_groupName),
    status,
    createdAt,
  );

  /// Create a copy of Reservation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReservationImplCopyWith<_$ReservationImpl> get copyWith =>
      __$$ReservationImplCopyWithImpl<_$ReservationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReservationImplToJson(this);
  }
}

abstract class _Reservation implements Reservation {
  const factory _Reservation({
    required final String id,
    @JsonKey(name: 'user_id') required final String userId,
    @JsonKey(name: 'client_info')
    required final Map<String, dynamic> clientInfo,
    @JsonKey(name: 'payment_method_id') required final String paymentMethodId,
    @JsonKey(name: 'total_amount', defaultValue: 0.0) final double? totalAmount,
    required final List<Map<String, dynamic>> products,
    @JsonKey(name: 'group_name') final Map<String, dynamic>? groupName,
    final String status,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
  }) = _$ReservationImpl;

  factory _Reservation.fromJson(Map<String, dynamic> json) =
      _$ReservationImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'client_info')
  Map<String, dynamic> get clientInfo;
  @override
  @JsonKey(name: 'payment_method_id')
  String get paymentMethodId;
  @override
  @JsonKey(name: 'total_amount', defaultValue: 0.0)
  double? get totalAmount;
  @override
  List<Map<String, dynamic>> get products;
  @override
  @JsonKey(name: 'group_name')
  Map<String, dynamic>? get groupName;
  @override
  String get status;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Create a copy of Reservation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReservationImplCopyWith<_$ReservationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
