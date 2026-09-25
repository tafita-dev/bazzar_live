// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deliverer_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$livreurServiceHash() => r'f08598401b92e812ea71ac954b69714b05c6880e';

/// See also [livreurService].
@ProviderFor(livreurService)
final livreurServiceProvider = AutoDisposeProvider<LivreurService>.internal(
  livreurService,
  name: r'livreurServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$livreurServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LivreurServiceRef = AutoDisposeProviderRef<LivreurService>;
String _$sellerDeliverersHash() => r'99f6542181508e3ee99497ac699c3e2f2ef899d7';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [sellerDeliverers].
@ProviderFor(sellerDeliverers)
const sellerDeliverersProvider = SellerDeliverersFamily();

/// See also [sellerDeliverers].
class SellerDeliverersFamily extends Family<AsyncValue<List<UserProfile>>> {
  /// See also [sellerDeliverers].
  const SellerDeliverersFamily();

  /// See also [sellerDeliverers].
  SellerDeliverersProvider call(String sellerId) {
    return SellerDeliverersProvider(sellerId);
  }

  @override
  SellerDeliverersProvider getProviderOverride(
    covariant SellerDeliverersProvider provider,
  ) {
    return call(provider.sellerId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'sellerDeliverersProvider';
}

/// See also [sellerDeliverers].
class SellerDeliverersProvider
    extends AutoDisposeStreamProvider<List<UserProfile>> {
  /// See also [sellerDeliverers].
  SellerDeliverersProvider(String sellerId)
    : this._internal(
        (ref) => sellerDeliverers(ref as SellerDeliverersRef, sellerId),
        from: sellerDeliverersProvider,
        name: r'sellerDeliverersProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$sellerDeliverersHash,
        dependencies: SellerDeliverersFamily._dependencies,
        allTransitiveDependencies:
            SellerDeliverersFamily._allTransitiveDependencies,
        sellerId: sellerId,
      );

  SellerDeliverersProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.sellerId,
  }) : super.internal();

  final String sellerId;

  @override
  Override overrideWith(
    Stream<List<UserProfile>> Function(SellerDeliverersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SellerDeliverersProvider._internal(
        (ref) => create(ref as SellerDeliverersRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        sellerId: sellerId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<UserProfile>> createElement() {
    return _SellerDeliverersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SellerDeliverersProvider && other.sellerId == sellerId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, sellerId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SellerDeliverersRef on AutoDisposeStreamProviderRef<List<UserProfile>> {
  /// The parameter `sellerId` of this provider.
  String get sellerId;
}

class _SellerDeliverersProviderElement
    extends AutoDisposeStreamProviderElement<List<UserProfile>>
    with SellerDeliverersRef {
  _SellerDeliverersProviderElement(super.provider);

  @override
  String get sellerId => (origin as SellerDeliverersProvider).sellerId;
}

String _$delivererNotifierHash() => r'143b2e389ebbe5af70fae8caa2d674b8581af984';

/// See also [DelivererNotifier].
@ProviderFor(DelivererNotifier)
final delivererNotifierProvider =
    AutoDisposeAsyncNotifierProvider<DelivererNotifier, void>.internal(
      DelivererNotifier.new,
      name: r'delivererNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$delivererNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DelivererNotifier = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
