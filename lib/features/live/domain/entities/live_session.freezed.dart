// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'live_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

LiveSession _$LiveSessionFromJson(Map<String, dynamic> json) {
  return _LiveSession.fromJson(json);
}

/// @nodoc
mixin _$LiveSession {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get facebookUrl => throw _privateConstructorUsedError;
  String get sellerId => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  DateTime? get startedAt => throw _privateConstructorUsedError;

  /// Serializes this LiveSession to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LiveSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LiveSessionCopyWith<LiveSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LiveSessionCopyWith<$Res> {
  factory $LiveSessionCopyWith(
    LiveSession value,
    $Res Function(LiveSession) then,
  ) = _$LiveSessionCopyWithImpl<$Res, LiveSession>;
  @useResult
  $Res call({
    String id,
    String title,
    String facebookUrl,
    String sellerId,
    bool isActive,
    DateTime? startedAt,
  });
}

/// @nodoc
class _$LiveSessionCopyWithImpl<$Res, $Val extends LiveSession>
    implements $LiveSessionCopyWith<$Res> {
  _$LiveSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LiveSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? facebookUrl = null,
    Object? sellerId = null,
    Object? isActive = null,
    Object? startedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            facebookUrl: null == facebookUrl
                ? _value.facebookUrl
                : facebookUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            sellerId: null == sellerId
                ? _value.sellerId
                : sellerId // ignore: cast_nullable_to_non_nullable
                      as String,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            startedAt: freezed == startedAt
                ? _value.startedAt
                : startedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LiveSessionImplCopyWith<$Res>
    implements $LiveSessionCopyWith<$Res> {
  factory _$$LiveSessionImplCopyWith(
    _$LiveSessionImpl value,
    $Res Function(_$LiveSessionImpl) then,
  ) = __$$LiveSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String facebookUrl,
    String sellerId,
    bool isActive,
    DateTime? startedAt,
  });
}

/// @nodoc
class __$$LiveSessionImplCopyWithImpl<$Res>
    extends _$LiveSessionCopyWithImpl<$Res, _$LiveSessionImpl>
    implements _$$LiveSessionImplCopyWith<$Res> {
  __$$LiveSessionImplCopyWithImpl(
    _$LiveSessionImpl _value,
    $Res Function(_$LiveSessionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LiveSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? facebookUrl = null,
    Object? sellerId = null,
    Object? isActive = null,
    Object? startedAt = freezed,
  }) {
    return _then(
      _$LiveSessionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        facebookUrl: null == facebookUrl
            ? _value.facebookUrl
            : facebookUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        sellerId: null == sellerId
            ? _value.sellerId
            : sellerId // ignore: cast_nullable_to_non_nullable
                  as String,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        startedAt: freezed == startedAt
            ? _value.startedAt
            : startedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LiveSessionImpl implements _LiveSession {
  const _$LiveSessionImpl({
    required this.id,
    required this.title,
    required this.facebookUrl,
    required this.sellerId,
    this.isActive = false,
    this.startedAt,
  });

  factory _$LiveSessionImpl.fromJson(Map<String, dynamic> json) =>
      _$$LiveSessionImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String facebookUrl;
  @override
  final String sellerId;
  @override
  @JsonKey()
  final bool isActive;
  @override
  final DateTime? startedAt;

  @override
  String toString() {
    return 'LiveSession(id: $id, title: $title, facebookUrl: $facebookUrl, sellerId: $sellerId, isActive: $isActive, startedAt: $startedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LiveSessionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.facebookUrl, facebookUrl) ||
                other.facebookUrl == facebookUrl) &&
            (identical(other.sellerId, sellerId) ||
                other.sellerId == sellerId) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    facebookUrl,
    sellerId,
    isActive,
    startedAt,
  );

  /// Create a copy of LiveSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LiveSessionImplCopyWith<_$LiveSessionImpl> get copyWith =>
      __$$LiveSessionImplCopyWithImpl<_$LiveSessionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LiveSessionImplToJson(this);
  }
}

abstract class _LiveSession implements LiveSession {
  const factory _LiveSession({
    required final String id,
    required final String title,
    required final String facebookUrl,
    required final String sellerId,
    final bool isActive,
    final DateTime? startedAt,
  }) = _$LiveSessionImpl;

  factory _LiveSession.fromJson(Map<String, dynamic> json) =
      _$LiveSessionImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get facebookUrl;
  @override
  String get sellerId;
  @override
  bool get isActive;
  @override
  DateTime? get startedAt;

  /// Create a copy of LiveSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LiveSessionImplCopyWith<_$LiveSessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
