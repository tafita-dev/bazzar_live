import 'package:live_shopping/core/widgets/bazzar_ui.dart';
import 'package:live_shopping/core/theme/bazzar_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../auth/presentation/providers/profile_provider.dart';
import '../../../auth/presentation/widgets/logout_confirmation_dialog.dart';
import '../providers/deliverer_provider.dart';

class DeliveryProfilePage extends ConsumerWidget {
  const DeliveryProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final delivererId = user?.id ?? '';
    final profileAsync = ref.watch(profileProvider(delivererId));
    final stats = ref.watch(delivererStatsProvider(delivererId));

    return Scaffold(
      backgroundColor: BazzarColors.background,
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
        title: const BazzarPageTitle(
          title: Text(
            'Mon Profil',
            style: TextStyle(
              color: BazzarColors.ink,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          subtitle: 'Votre compte et votre activité',
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: BazzarColors.primary),
        ),
        error: (err, _) => Center(child: Text('Erreur: $err')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profil introuvable'));
          }

          final totalDelivered = stats['total_delivered'] ?? 0;
          final totalRevenue =
              (stats['total_revenue'] as num?)?.toDouble() ?? 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildHeader(profile),
                const SizedBox(height: 16),
                _buildQuickStats(totalDelivered, totalRevenue),
                const SizedBox(height: 16),
                _buildInfoCard(profile),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => confirmSignOut(context, ref),
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Colors.redAccent,
                    ),
                    label: const Text(
                      'Se déconnecter',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFECEB),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(UserProfile profile) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: BazzarColors.primary.withValues(alpha: 0.12),
              border: Border.all(color: BazzarColors.primary, width: 3),
            ),
            child: ClipOval(
              child: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                  ? Image.network(
                      profile.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        size: 50,
                        color: BazzarColors.primary,
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      size: 50,
                      color: BazzarColors.primary,
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            profile.fullName ?? 'Livreur',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: BazzarColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile.email,
            style: const TextStyle(fontSize: 13, color: BazzarColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(UserProfile profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations',
            style: TextStyle(
              color: BazzarColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _buildInfoRow(
            icon: Icons.badge_outlined,
            label: 'Rôle',
            value: 'Livreur',
          ),
          _buildInfoRow(
            icon: Icons.phone_outlined,
            label: 'Contact',
            value: profile.phone ?? 'Non renseigné',
          ),
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            label: 'Adresse',
            value: profile.address ?? 'Non renseignée',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(int totalDelivered, double totalRevenue) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: BazzarColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: BazzarColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Livrées',
                      style: TextStyle(
                        color: BazzarColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '$totalDelivered',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: BazzarColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.payments_rounded,
                        size: 16,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Encaissé',
                      style: TextStyle(
                        color: BazzarColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  CurrencyFormatter.format(totalRevenue),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF10B981),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 21, color: BazzarColors.muted),
          const SizedBox(width: 10),
          Text(
            '$label : ',
            style: const TextStyle(
              color: BazzarColors.body,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: BazzarColors.body, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
