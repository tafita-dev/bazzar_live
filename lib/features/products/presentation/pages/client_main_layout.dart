import 'package:live_shopping/core/theme/bazzar_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../orders/presentation/providers/reservation_provider.dart';
import 'package:live_shopping/core/widgets/app_notification.dart';

class ClientMainLayout extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const ClientMainLayout({super.key, required this.navigationShell});

  @override
  ConsumerState<ClientMainLayout> createState() => _ClientMainLayoutState();
}

class _ClientMainLayoutState extends ConsumerState<ClientMainLayout> {
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _setupRealtimeSubscription();
  }

  void _setupRealtimeSubscription() {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId != null) {
      debugPrint(
        '[REALTIME_NOTIFICATION] Setting up realtime subscription for user=$userId',
      );
      _realtimeChannel = client
          .channel('public:reservations:client_notifications')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'reservations',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) {
              debugPrint(
                '[REALTIME_NOTIFICATION] Change received: event=${payload.eventType}',
              );

              // Invalidate reservation provider to refresh orders list
              ref.invalidate(clientReservationsProvider(userId));

              if (payload.eventType == PostgresChangeEvent.update) {
                final newRecord = payload.newRecord;
                final oldRecord = payload.oldRecord;

                if (newRecord.isNotEmpty) {
                  final status = newRecord['status'] as String?;
                  final oldStatus = oldRecord['status'] as String?;

                  // Only notify if status has actually changed
                  if (status != null && status != oldStatus) {
                    final orderId =
                        newRecord['id']
                            ?.toString()
                            .substring(0, 8)
                            .toUpperCase() ??
                        '';
                    final statusLabel = status == 'validated'
                        ? 'confirmée'
                        : (status == 'delivered'
                              ? 'livrée'
                              : (status == 'cancelled' ? 'annulée' : status));

                    if (mounted &&
                        (status == 'validated' ||
                            status == 'delivered' ||
                            status == 'cancelled')) {
                      final msg =
                          'Votre commande #$orderId a été $statusLabel !';
                      if (status == 'validated') {
                        AppNotification.showGlobal(msg);
                      } else if (status == 'delivered') {
                        AppNotification.showGlobal(msg, isInfo: true);
                      } else {
                        AppNotification.showGlobal(msg, isError: true);
                      }
                    }
                  }
                }
              }
            },
          );

      _realtimeChannel!.subscribe();
    }
  }

  @override
  void dispose() {
    if (_realtimeChannel != null) {
      debugPrint('[REALTIME_NOTIFICATION] Disposing realtime subscription');
      Supabase.instance.client.removeChannel(_realtimeChannel!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final reservationsAsync = ref.watch(clientReservationsProvider(userId));

    int pendingCount = 0;
    reservationsAsync.whenData((reservations) {
      pendingCount = reservations
          .where((r) => r.status.toLowerCase() == 'pending')
          .length;
    });

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: Container(
        height:
            80 +
            MediaQuery.paddingOf(context).bottom +
            (MediaQuery.textScalerOf(context).scale(12) - 12)
                .clamp(0, 48)
                .toDouble(),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: BazzarColors.border, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: BazzarColors.ink.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                0,
                Icons.home_rounded,
                Icons.home_outlined,
                'Accueil',
              ),
              _buildNavItem(
                context,
                1,
                Icons.shopping_bag_rounded,
                Icons.shopping_bag_outlined,
                'Commandes',
                badgeCount: pendingCount,
              ),
              _buildNavItem(
                context,
                2,
                Icons.person_rounded,
                Icons.person_outline_rounded,
                'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label, {
    int badgeCount = 0,
  }) {
    final isSelected = widget.navigationShell.currentIndex == index;
    const Color activeTextColor = BazzarColors.primary;
    const Color inactiveColor = Color(0xFF757086);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? BazzarColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      isSelected ? activeIcon : inactiveIcon,
                      color: isSelected ? activeTextColor : inactiveColor,
                      size: 22,
                    ),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -3,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEF4444), Color(0xFFEF4444)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFEF4444,
                              ).withValues(alpha: 0.45),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          badgeCount > 9 ? '9+' : '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? activeTextColor : inactiveColor,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
