import 'package:live_shopping/core/theme/bazzar_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/profile_provider.dart';
import '../widgets/logout_confirmation_dialog.dart';

class RootRoleRedirectScreen extends ConsumerStatefulWidget {
  const RootRoleRedirectScreen({super.key});

  @override
  ConsumerState<RootRoleRedirectScreen> createState() =>
      _RootRoleRedirectScreenState();
}

class _RootRoleRedirectScreenState
    extends ConsumerState<RootRoleRedirectScreen> {
  bool _redirecting = false;

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    // Aucun utilisateur connecté
    if (user == null) {
      _redirectToLogin();
      return const _PremiumLoading();
    }

    final profileAsync = ref.watch(profileProvider(user.id));

    return profileAsync.when(
      loading: () => const _PremiumLoading(),

      error: (error, stackTrace) {
        return _ProfileError(
          error: error,
          onRetry: () {
            ref.invalidate(profileProvider(user.id));
          },
        );
      },

      data: (profile) {
        if (profile == null) {
          return _ProfileNotFound(onLogout: () => confirmSignOut(context, ref));
        }

        _redirectByRole(profile.role);

        return const _PremiumLoading(message: 'Préparation de votre espace...');
      },
    );
  }

  void _redirectToLogin() {
    if (_redirecting || !mounted) return;

    _redirecting = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (context.mounted) {
        context.go('/login');
      }
    });
  }

  void _redirectByRole(String? role) {
    if (_redirecting || !mounted) return;

    _redirecting = true;

    String route;

    switch (role) {
      case 'vendeur':
        route = '/seller/dashboard';
        break;

      case 'livreur':
        route = '/delivery/scanner';
        break;

      case 'client':
      default:
        route = '/client';
        break;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (context.mounted) {
        context.go(route);
      }
    });
  }
}

// ============================================================
// PREMIUM LOADING
// ============================================================

class _PremiumLoading extends StatelessWidget {
  final String message;

  const _PremiumLoading({this.message = 'Chargement de votre espace...'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BazzarColors.background,
      body: Stack(
        children: [
          // Glow haut droite
          const Positioned(
            top: -130,
            right: -100,
            child: _GlowCircle(size: 300, color: BazzarColors.primary),
          ),

          // Glow bas gauche
          const Positioned(
            bottom: -150,
            left: -120,
            child: _GlowCircle(size: 320, color: Color(0xFF8B5CF6)),
          ),

          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 92,
                      height: 92,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.07),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'sary/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'Bazzar Live',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        color: BazzarColors.ink,
                        letterSpacing: 0,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: BazzarColors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Progress indicator premium
                    Container(
                      width: 48,
                      height: 48,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: BazzarColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: BazzarColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// GLOW
// ============================================================

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.06),
        ),
      ),
    );
  }
}

// ============================================================
// PROFILE ERROR
// ============================================================

class _ProfileError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ProfileError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BazzarColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.09),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    color: Color(0xFFEF4444),
                    size: 38,
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Impossible de charger',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: BazzarColors.ink,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Une erreur est survenue lors du chargement de votre profil.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: BazzarColors.muted,
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: const Text(
                      'Réessayer',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BazzarColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  error.toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: BazzarColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PROFILE NOT FOUND
// ============================================================

class _ProfileNotFound extends StatelessWidget {
  final VoidCallback onLogout;

  const _ProfileNotFound({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BazzarColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: BazzarColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_search_rounded,
                    color: BazzarColors.primary,
                    size: 40,
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Profil introuvable',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: BazzarColors.ink,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Nous ne trouvons pas les informations associées à votre compte.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: BazzarColors.muted,
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout_rounded, size: 19),
                    label: const Text(
                      'Se déconnecter',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BazzarColors.ink,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
