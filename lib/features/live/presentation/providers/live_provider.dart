import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';

class LiveFeed {
  final String id;
  final String title;
  final String description;
  final String facebookUrl;
  final String sellerId;
  final String? shopName;
  final String sellerName;
  final String? sellerAvatarUrl;
  final String? coverImageUrl;
  final DateTime? startedAt;

  const LiveFeed({
    required this.id,
    required this.title,
    required this.description,
    required this.facebookUrl,
    required this.sellerId,
    this.shopName,
    this.sellerName = 'Vendeur',
    this.sellerAvatarUrl,
    this.coverImageUrl,
    this.startedAt,
  });

  factory LiveFeed.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? profile;
    if (json['profiles'] is Map) {
      profile = json['profiles'] as Map<String, dynamic>?;
    } else if (json['profiles'] is List && (json['profiles'] as List).isNotEmpty) {
      profile = (json['profiles'] as List).first as Map<String, dynamic>?;
    }
    
    final fullName = profile?['full_name'] as String?;
    final avatarUrl = profile?['avatar_url'] as String?;

    return LiveFeed(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Live shopping',
      description: json['description'] as String? ?? '',
      facebookUrl: json['facebook_url'] as String? ?? '',
      sellerId: json['seller_id'] as String? ?? '',
      shopName: json['shop_name'] as String?,
      sellerName: fullName != null && fullName.trim().isNotEmpty
          ? fullName.trim()
          : (json['seller_name'] as String? ?? 'Vendeur'),
      sellerAvatarUrl: avatarUrl != null && avatarUrl.trim().isNotEmpty
          ? avatarUrl.trim()
          : json['seller_avatar_url'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      startedAt: json['started_at'] == null
          ? null
          : DateTime.tryParse(json['started_at'] as String),
    );
  }

  LiveFeed copyWith({
    String? shopName,
    String? sellerName,
    String? sellerAvatarUrl,
    String? coverImageUrl,
  }) {
    return LiveFeed(
      id: id,
      title: title,
      description: description,
      facebookUrl: facebookUrl,
      sellerId: sellerId,
      shopName: shopName ?? this.shopName,
      sellerName: sellerName ?? this.sellerName,
      sellerAvatarUrl: sellerAvatarUrl ?? this.sellerAvatarUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      startedAt: startedAt,
    );
  }
}

final allLivesProvider = FutureProvider<List<LiveFeed>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('lives')
      .select('*, profiles (full_name, avatar_url)')
      .order('started_at', ascending: false);

  final lives = (response as List)
      .map((json) => LiveFeed.fromJson(json as Map<String, dynamic>))
      .toList();

  final sellerIds = lives.map((live) => live.sellerId).toSet().toList();
  
  final Map<String, String> sellerCovers = {};
  if (sellerIds.isNotEmpty) {
    try {
      final productsResponse = await client
          .from('products')
          .select('seller_id, image_url')
          .inFilter('seller_id', sellerIds);
      
      for (final product in productsResponse as List) {
        final sellerId = product['seller_id']?.toString();
        final imageUrl = product['image_url']?.toString().trim();
        if (sellerId != null && imageUrl != null && imageUrl.isNotEmpty) {
          sellerCovers[sellerId] ??= imageUrl;
        }
      }
    } catch (_) {}
  }

  return lives.map((live) {
    final cover = sellerCovers[live.sellerId] ?? live.coverImageUrl;
    return live.copyWith(coverImageUrl: cover);
  }).toList();
});

final activeLivesProvider = Provider<AsyncValue<List<LiveFeed>>>((ref) {
  return ref.watch(allLivesProvider);
});

final liveByIdProvider = FutureProvider.family<LiveFeed, String>((
  ref,
  liveId,
) async {
  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('lives')
      .select('*, profiles (full_name, avatar_url)')
      .eq('id', liveId)
      .single();

  return LiveFeed.fromJson(response);
});
