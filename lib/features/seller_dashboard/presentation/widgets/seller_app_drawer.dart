import 'package:live_shopping/core/theme/bazzar_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:live_shopping/core/theme/app_theme.dart';

import '../../../auth/presentation/providers/profile_provider.dart';
import '../../../auth/presentation/widgets/logout_confirmation_dialog.dart';

class SellerAppDrawer extends ConsumerWidget {
  final String sellerId;

  const SellerAppDrawer({super.key, required this.sellerId});

  void _navigateTo(BuildContext context, String route) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    context.go(route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider(sellerId));
    final sellerName = profileAsync.value?.fullName ?? 'Vendeur';
    final avatarUrl = profileAsync.value?.avatarUrl;

    return Drawer(
      backgroundColor: Colors.white,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(
                    sellerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                      letterSpacing: 0,
                    ),
                  ),
                  accountEmail: Text(
                    profileAsync.value?.email ?? sellerId,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  currentAccountPicture: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _DrawerAvatar(
                      imageUrl:
                          avatarUrl ??
                          'https://api.dicebear.com/7.x/adventurer/png?seed=$sellerName',
                      fallbackIcon: Icons.storefront_rounded,
                      onTap: () => _navigateTo(context, '/seller/profile'),
                    ),
                  ),
                  decoration: const BoxDecoration(
                    gradient: AppTheme.sunsetAuroraGradient,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      _buildDrawerItem(
                        icon: Icons.dashboard_rounded,
                        title: 'Tableau de bord',
                        onTap: () => _navigateTo(context, '/seller/dashboard'),
                      ),
                      _buildDrawerItem(
                        icon: Icons.shopping_bag_rounded,
                        title: 'Mes produits',
                        onTap: () => _navigateTo(context, '/seller/products'),
                      ),
                      _buildDrawerItem(
                        icon: Icons.list_alt_rounded,
                        title: 'Commandes',
                        onTap: () => _navigateTo(context, '/seller/orders'),
                      ),
                      _buildDrawerItem(
                        icon: Icons.live_tv_rounded,
                        title: 'Live Shopping',
                        onTap: () =>
                            _navigateTo(context, '/seller/live_shopping'),
                      ),
                      _buildDrawerItem(
                        icon: Icons.delivery_dining_rounded,
                        title: 'Mes livreurs',
                        onTap: () => _navigateTo(context, '/seller/deliverers'),
                      ),
                      _buildDrawerItem(
                        icon: Icons.person_rounded,
                        title: 'Profil',
                        onTap: () => _navigateTo(context, '/seller/profile'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: _buildDrawerItem(
              icon: Icons.logout_rounded,
              title: 'Déconnexion',
              textColor: Colors.redAccent,
              iconColor: Colors.redAccent,
              onTap: () async {
                await confirmSignOut(context, ref, closeDrawer: true);
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color textColor = BazzarColors.ink,
    Color iconColor = BazzarColors.muted,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        dense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(icon, color: iconColor, size: 22),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: textColor,
          ),
        ),
        onTap: onTap,
        splashColor: Colors.deepPurple.withValues(alpha: 0.05),
      ),
    );
  }
}

class _DrawerAvatar extends StatelessWidget {
  final String imageUrl;
  final IconData fallbackIcon;
  final VoidCallback onTap;

  const _DrawerAvatar({
    required this.imageUrl,
    required this.fallbackIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ouvrir le profil',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: const BoxDecoration(
              color: BazzarColors.soft,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.network(
                imageUrl,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) =>
                    Icon(fallbackIcon, color: BazzarColors.muted, size: 34),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
