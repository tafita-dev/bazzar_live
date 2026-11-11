import 'package:live_shopping/core/theme/bazzar_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:live_shopping/features/delivery/presentation/providers/deliverer_provider.dart';
import 'create_livreur_screen.dart';

class SellerDelivererListScreen extends ConsumerWidget {
  final String sellerId;

  const SellerDelivererListScreen({super.key, required this.sellerId});

  static const Color primary = BazzarColors.primary;
  static const Color background = BazzarColors.background;
  static const Color dark = BazzarColors.ink;
  static const Color muted = BazzarColors.muted;
  static const Color border = BazzarColors.border;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliverersAsync = ref.watch(sellerDeliverersProvider(sellerId));

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: BazzarColors.surface,
        foregroundColor: BazzarColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 76,
        titleSpacing: 20,
        shape: const Border(bottom: BorderSide(color: BazzarColors.border)),

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mes livreurs',
              style: TextStyle(
                color: dark,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Gérez votre équipe de livraison',
              style: TextStyle(
                color: muted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),

      body: deliverersAsync.when(
        loading: () => const _LoadingState(),

        error: (error, stack) {
          return _ErrorState(
            message: 'Impossible de charger vos livreurs.',
            onRetry: () {
              ref.invalidate(sellerDeliverersProvider(sellerId));
            },
          );
        },

        data: (deliverers) {
          if (deliverers.isEmpty) {
            return _EmptyState(onAdd: () => _openCreateLivreur(context, ref));
          }

          return RefreshIndicator(
            color: primary,
            onRefresh: () async {
              ref.invalidate(sellerDeliverersProvider(sellerId));

              await ref.read(sellerDeliverersProvider(sellerId).future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildHeader(deliverers.length),
                      const SizedBox(height: 16),

                      ...List.generate(deliverers.length, (index) {
                        final deliverer = deliverers[index];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _DelivererCard(
                            deliverer: deliverer,
                            onEdit: () {
                              _showComingSoon(context);
                            },
                            onDelete: () async {
                              await _deleteDeliverer(context, ref, deliverer);
                            },
                          ),
                        );
                      }),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateLivreur(context, ref),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 8,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Ajouter un livreur',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BazzarColors.primary,
            BazzarColors.primaryDark,
            BazzarColors.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              color: Colors.white,
              size: 25,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Équipe de livraison',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count ${count > 1 ? 'livreurs' : 'livreur'} enregistré${count > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openCreateLivreur(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateLivreurScreen()),
    ).then((_) {
      ref.invalidate(sellerDeliverersProvider(sellerId));
    });
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text('La modification sera disponible prochainement.'),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Future<void> _deleteDeliverer(
    BuildContext context,
    WidgetRef ref,
    dynamic deliverer,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444),
                    size: 30,
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Supprimer ce livreur ?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: dark,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Cette action retirera ce livreur de votre équipe.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontSize: 13, height: 1.4),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext, false);
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          side: const BorderSide(color: border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Annuler',
                          style: TextStyle(
                            color: dark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Supprimer',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(delivererNotifierProvider.notifier)
          .deleteLivreur(deliverer.id);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text('Livreur supprimé avec succès'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF16A34A),
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );

      ref.invalidate(sellerDeliverersProvider(sellerId));
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Impossible de supprimer le livreur.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFEF4444),
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
    }
  }
}

/* -------------------------------------------------------------------------- */
/*                              DELIVERER CARD                                */
/* -------------------------------------------------------------------------- */

class _DelivererCard extends StatelessWidget {
  final dynamic deliverer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DelivererCard({
    required this.deliverer,
    required this.onEdit,
    required this.onDelete,
  });

  static const Color dark = BazzarColors.ink;
  static const Color muted = BazzarColors.muted;
  static const Color border = BazzarColors.border;
  static const Color primary = BazzarColors.primary;

  @override
  Widget build(BuildContext context) {
    final hasAvatar =
        deliverer.avatarUrl != null && deliverer.avatarUrl!.isNotEmpty;

    final name = deliverer.fullName?.trim().isNotEmpty == true
        ? deliverer.fullName!
        : 'Sans nom';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          /* Avatar */
          Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  color: BazzarColors.lavender,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: hasAvatar
                      ? Image.network(
                          deliverer.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return const Icon(
                              Icons.person_rounded,
                              color: primary,
                              size: 28,
                            );
                          },
                        )
                      : const Icon(
                          Icons.person_rounded,
                          color: primary,
                          size: 28,
                        ),
                ),
              ),

              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 17,
                  height: 17,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          /* Informations */
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: dark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 14, color: muted),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        deliverer.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 7),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 7, color: Color(0xFF22C55E)),
                      SizedBox(width: 5),
                      Text(
                        'Actif',
                        style: TextStyle(
                          color: Color(0xFF15803D),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          /* Menu */
          Container(
            decoration: BoxDecoration(
              color: BazzarColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: PopupMenuButton<String>(
              tooltip: 'Options',
              icon: const Icon(Icons.more_horiz_rounded, color: muted),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                }

                if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) {
                return [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 19, color: dark),
                        SizedBox(width: 12),
                        Text(
                          'Modifier',
                          style: TextStyle(
                            color: dark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 19,
                          color: Color(0xFFEF4444),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Supprimer',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                               EMPTY STATE                                  */
/* -------------------------------------------------------------------------- */

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [BazzarColors.lavender, Color(0xFFE0E7FF)],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                color: BazzarColors.primary,
                size: 42,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Aucun livreur',
              style: TextStyle(
                color: BazzarColors.ink,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Ajoutez votre premier livreur pour commencer à gérer vos livraisons.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: BazzarColors.muted,
                fontSize: 13,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Ajouter un livreur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: BazzarColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              LOADING STATE                                 */
/* -------------------------------------------------------------------------- */

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          height: 86,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        const SizedBox(height: 18),
        ...List.generate(
          4,
          (index) => Container(
            height: 96,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                               ERROR STATE                                  */
/* -------------------------------------------------------------------------- */

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: Color(0xFFEF4444),
                size: 32,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Une erreur est survenue',
              style: TextStyle(
                color: BazzarColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: BazzarColors.muted, fontSize: 13),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: BazzarColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Réessayer',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
