import 'package:flutter/material.dart';
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
  static const _ink = Color(0xFF101828);
  static const _muted = Color(0xFF667085);
  static const _line = Color(0xFFE6E8EC);
  static const _surface = Color(0xFFFFFFFF);
  static const _background = Color(0xFFF4F6F8);
  static const _gold = Color(0xFFB7791F);
  static const _accent = Color(0xFF2563EB);

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
              error: (error, _) => SliverToBoxAdapter(
                child: _MessagePanel(
                  icon: Icons.error_outline_rounded,
                  title: 'Impossible de charger le fil',
                  message: '$error',
                  color: const Color(0xFFDC2626),
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
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
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
      titleSpacing: 14,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _ink,
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
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4D6),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: const Color(0xFFF2D18B)),
            ),
            child: const Text(
              'PREMIUM',
              style: TextStyle(
                color: _gold,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.7,
              ),
            ),
          ),
        ],
      ),
      actions: [
        _RoundIconButton(icon: Icons.search_rounded, onPressed: () {}),
        _RoundIconButton(
          icon: Icons.notifications_none_rounded,
          onPressed: () {},
        ),
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WelcomeBanner(displayName: displayName),
          const SizedBox(height: 18),
          _Filters(selectedFilter: selectedFilter, onChanged: onFilterChanged),
          const SizedBox(height: 16),
          const Text(
            'Fil premium',
            style: TextStyle(
              color: _ClientHomeScreenState._ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
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
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF26334A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF111827).withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white.withValues(alpha: 0.14),
            child: Text(
              displayName.characters.first.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour $displayName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Les meilleures offres vous attendent',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Colors.white,
              size: 24,
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

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFECEFF3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(filter.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      filter.$2,
                      size: 17,
                      color: isSelected
                          ? _ClientHomeScreenState._ink
                          : _ClientHomeScreenState._muted,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        filter.$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected
                              ? _ClientHomeScreenState._ink
                              : _ClientHomeScreenState._muted,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w900
                              : FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
    final title = live.shopName ?? live.sellerName;

    return Container(
      decoration: _premiumDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: const Color(0xFFEFF6FF),
                  backgroundImage: live.sellerAvatarUrl != null
                      ? NetworkImage(live.sellerAvatarUrl!)
                      : null,
                  child: live.sellerAvatarUrl == null
                      ? const Icon(
                          Icons.storefront_rounded,
                          color: _ClientHomeScreenState._accent,
                        )
                      : null,
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
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () {},
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: _ClientHomeScreenState._muted,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Text(
              live.title,
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
          GestureDetector(
            onTap: onTap,
            child: AspectRatio(
              aspectRatio: 1.18,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    live.coverImageUrl ??
                        'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=1000',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFECEFF3),
                        child: const Icon(
                          Icons.image_not_supported_rounded,
                          color: _ClientHomeScreenState._muted,
                          size: 44,
                        ),
                      );
                    },
                  ),
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                _ActionButton(
                  icon: Icons.favorite_border_rounded,
                  label: 'J’aime',
                ),
                _ActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Commenter',
                ),
                _ActionButton(
                  icon: Icons.bookmark_border_rounded,
                  label: 'Garder',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
        borderRadius: BorderRadius.circular(18),
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 19),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: TextButton.styleFrom(
          foregroundColor: _ClientHomeScreenState._muted,
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
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
        onPressed: onPressed,
        icon: Icon(icon, color: _ClientHomeScreenState._ink),
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFFF2F4F7),
          fixedSize: const Size(40, 40),
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
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
      decoration: _premiumDecoration(),
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
        ],
      ),
    );
  }
}

BoxDecoration _premiumDecoration() {
  return BoxDecoration(
    color: _ClientHomeScreenState._surface,
    borderRadius: BorderRadius.circular(16),
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
