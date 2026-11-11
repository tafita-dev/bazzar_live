import 'package:live_shopping/core/theme/bazzar_colors.dart';
import 'package:flutter/material.dart';
import 'package:live_shopping/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:live_shopping/core/widgets/app_notification.dart';
import '../../../auth/presentation/providers/profile_provider.dart';
import '../../../live/presentation/providers/live_provider.dart';

class ClientHomeScreen extends ConsumerStatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  ConsumerState<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends ConsumerState<ClientHomeScreen> {
  static const _ink = BazzarColors.ink;
  static const _muted = BazzarColors.muted;
  static const _line = BazzarColors.border;
  static const _surface = Color(0xFFFFFFFF);
  static const _background = AppTheme.bgLight;
  static const _accent = AppTheme.primaryColor;

  RealtimeChannel? _realtimeChannel;
  String _selectedFilter = 'Tous';

  @override
  void initState() {
    super.initState();
    _setupRealtimeSubscription();
  }

  void _setupRealtimeSubscription() {
    final client = Supabase.instance.client;

    debugPrint('[REALTIME_LIVES] Setting up realtime subscription for lives');
    _realtimeChannel = client
        .channel('public:lives:new_lives')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'lives',
          callback: (payload) {
            debugPrint(
              '[REALTIME_LIVES] New live created: ${payload.newRecord}',
            );
            ref.invalidate(allLivesProvider);
            AppNotification.showGlobal(
              'Un nouveau live est en direct !',
              isInfo: true,
            );
          },
        );

    _realtimeChannel!.subscribe();
  }

  @override
  void dispose() {
    if (_realtimeChannel != null) {
      debugPrint('[REALTIME_LIVES] Disposing realtime subscription');
      Supabase.instance.client.removeChannel(_realtimeChannel!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allLivesAsync = ref.watch(allLivesProvider);
    final user = Supabase.instance.client.auth.currentUser;
    final profileAsync = ref.watch(profileProvider(user?.id ?? ''));
    final clientName = profileAsync.value?.fullName?.trim();
    final displayName = clientName == null || clientName.isEmpty
        ? 'Acheteur'
        : clientName;

    return Scaffold(
      backgroundColor: _background,
      appBar: _buildAppBar(user?.id),
      body: RefreshIndicator(
        color: _accent,
        onRefresh: () async {
          ref.invalidate(allLivesProvider);
          if (user?.id != null) {
            ref.invalidate(profileProvider(user!.id));
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: _TopSection(
                displayName: displayName,
                selectedFilter: _selectedFilter,
                onFilterChanged: (filter) =>
                    setState(() => _selectedFilter = filter),
              ),
            ),
            allLivesAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: CircularProgressIndicator(color: _accent),
                  ),
                ),
              ),
              error: (_, __) => SliverToBoxAdapter(
                child: _MessagePanel(
                  icon: Icons.error_outline_rounded,
                  title: 'Impossible de charger le fil',
                  message:
                      'Les lives ne sont pas disponibles pour le moment. Vérifiez votre connexion puis réessayez.',
                  color: const Color(0xFFDC2626),
                  onRetry: () => ref.invalidate(allLivesProvider),
                ),
              ),
              data: (lives) {
                final filteredLives = _filterLives(lives);

                if (filteredLives.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: _MessagePanel(
                      icon: Icons.live_tv_rounded,
                      title: 'Aucun live pour le moment',
                      message:
                          'Les nouvelles ventes apparaîtront ici dès leur publication.',
                      color: _accent,
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final live = filteredLives[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == filteredLives.length - 1 ? 0 : 12,
                        ),
                        child: _LivePostCard(
                          live: live,
                          onTap: () => context.go('/client/live/${live.id}'),
                        ),
                      );
                    }, childCount: filteredLives.length),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String? userId) {
    return AppBar(
      backgroundColor: _surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: 64,
      shape: const Border(bottom: BorderSide(color: _line)),
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.shopping_bag_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          const Flexible(
            child: Text(
              'Bazzar',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _ink,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
      actions: [
        _RoundIconButton(
          icon: Icons.refresh_rounded,
          onPressed: () {
            ref.invalidate(allLivesProvider);
            if (userId != null) {
              ref.invalidate(profileProvider(userId));
            }
          },
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  List<LiveFeed> _filterLives(List<LiveFeed> lives) {
    return lives.where((live) {
      final isActive = _isActiveLive(live);
      if (_selectedFilter == 'En direct') {
        return isActive;
      }
      if (_selectedFilter == 'Replays') {
        return !isActive;
      }
      return true;
    }).toList();
  }

  static bool _isActiveLive(LiveFeed live) {
    return live.startedAt != null &&
        live.startedAt!.isAfter(
          DateTime.now().subtract(const Duration(hours: 4)),
        );
  }
}

class _TopSection extends StatelessWidget {
  const _TopSection({
    required this.displayName,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final String displayName;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WelcomeBanner(displayName: displayName),
          const SizedBox(height: 18),
          _Filters(selectedFilter: selectedFilter, onChanged: onFilterChanged),
          const SizedBox(height: 16),
          const Text(
            'À découvrir',
            style: TextStyle(
              color: _ClientHomeScreenState._ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF30205C), BazzarColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.softShadow(
          color: AppTheme.primaryColor,
          opacity: 0.14,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Bonjour $displayName',
                  style: const TextStyle(
                    color: Color(0xFFE9DDFB),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFFF6CC78),
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Vos envies.\nEn direct.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Découvrez les boutiques et leurs nouveautés en vidéo.',
            style: TextStyle(
              color: Color(0xFFE9DDFB),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.selectedFilter, required this.onChanged});

  final String selectedFilter;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const filters = [
      ('Tous', Icons.grid_view_rounded),
      ('En direct', Icons.bolt_rounded),
      ('Replays', Icons.history_rounded),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final selected = selectedFilter == filter.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selected,
              showCheckmark: false,
              avatar: Icon(
                filter.$2,
                size: 18,
                color: selected ? Colors.white : AppTheme.textMuted,
              ),
              label: Text(filter.$1),
              labelStyle: TextStyle(
                color: selected ? Colors.white : AppTheme.mediumSlate,
                fontWeight: FontWeight.w700,
              ),
              selectedColor: AppTheme.primaryColor,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: selected ? AppTheme.primaryColor : AppTheme.borderLight,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (_) => onChanged(filter.$1),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LivePostCard extends StatelessWidget {
  const _LivePostCard({required this.live, required this.onTap});

  final LiveFeed live;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = _ClientHomeScreenState._isActiveLive(live);
    final shopName = live.shopName?.trim();
    final sellerName = live.sellerName.trim();
    final title = shopName != null && shopName.isNotEmpty
        ? shopName
        : sellerName.isNotEmpty
        ? sellerName
        : 'Boutique';
    final avatarUrl = live.sellerAvatarUrl?.trim();

    return Container(
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 46,
                    height: 46,
                    child: avatarUrl == null || avatarUrl.isEmpty
                        ? const _ShopAvatarFallback()
                        : Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            excludeFromSemantics: true,
                            errorBuilder: (_, __, ___) =>
                                const _ShopAvatarFallback(),
                          ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ClientHomeScreenState._ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isActive ? 'En direct maintenant' : 'Replay disponible',
                        style: TextStyle(
                          color: isActive
                              ? const Color(0xFFDC2626)
                              : _ClientHomeScreenState._muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Text(
              live.title.trim().isEmpty
                  ? 'Découvrez cette boutique'
                  : live.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ClientHomeScreenState._ink,
                fontSize: 16,
                height: 1.3,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Semantics(
            button: true,
            label:
                '${isActive ? 'Regarder le live' : 'Voir le replay'} de $title',
            child: InkWell(
              onTap: onTap,
              child: AspectRatio(
                aspectRatio: 1.35,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _LiveCover(imageUrl: live.coverImageUrl),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.04),
                            Colors.black.withValues(alpha: 0.38),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      top: 14,
                      child: _StatusPill(isActive: isActive),
                    ),
                    Positioned(
                      right: 14,
                      bottom: 14,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: _ClientHomeScreenState._ink,
                          size: 34,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onTap,
                icon: Icon(
                  isActive ? Icons.play_arrow_rounded : Icons.replay_rounded,
                ),
                label: Text(isActive ? 'Regarder le live' : 'Voir le replay'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopAvatarFallback extends StatelessWidget {
  const _ShopAvatarFallback();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: BazzarColors.lavender,
    child: Icon(Icons.storefront_rounded, color: BazzarColors.primary),
  );
}

class _LiveCover extends StatelessWidget {
  const _LiveCover({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) return const _CoverFallback();

    return Image.network(
      url,
      fit: BoxFit.cover,
      excludeFromSemantics: true,
      errorBuilder: (_, __, ___) => const _CoverFallback(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const ColoredBox(
          color: BazzarColors.soft,
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                semanticsLabel: 'Chargement de la couverture',
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(gradient: BazzarColors.hero),
    child: Center(
      child: Padding(
        padding: EdgeInsets.all(64),
        child: Icon(Icons.storefront_outlined, color: Colors.white70, size: 64),
      ),
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFDC2626)
            : Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.fiber_manual_record_rounded : Icons.replay_rounded,
            color: Colors.white,
            size: isActive ? 9 : 14,
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'LIVE' : 'REPLAY',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: IconButton(
        tooltip: 'Actualiser les lives',
        onPressed: onPressed,
        icon: Icon(icon, color: _ClientHomeScreenState._ink),
        style: IconButton.styleFrom(
          backgroundColor: BazzarColors.soft,
          minimumSize: const Size(48, 48),
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ClientHomeScreenState._ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ClientHomeScreenState._muted,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: _ClientHomeScreenState._surface,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: _ClientHomeScreenState._line),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.045),
        blurRadius: 22,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
