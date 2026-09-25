import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/error_helper.dart';
import '../../../../core/widgets/app_notification.dart';
import '../providers/deliverer_provider.dart';

class ReservationDetailsPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> reservation;

  const ReservationDetailsPage({super.key, required this.reservation});

  @override
  ConsumerState<ReservationDetailsPage> createState() =>
      _ReservationDetailsPageState();
}

class _ReservationDetailsPageState
    extends ConsumerState<ReservationDetailsPage> {
  bool _isSubmitting = false;
  late Map<String, dynamic> _currentReservation;

  @override
  void initState() {
    super.initState();
    _currentReservation = Map<String, dynamic>.from(widget.reservation);
  }

  bool get _isDelivered => _currentReservation['status'] == 'delivered';

  Future<void> _handleConfirmDelivery() async {
    final delivererId =
        Supabase.instance.client.auth.currentUser?.id ?? '';
    if (delivererId.isEmpty) {
      AppNotification.showError(
          context, 'Vous devez être connecté pour livrer');
      return;
    }

    final totalAmount =
        (widget.reservation['total_amount'] as num?)?.toDouble() ?? 0.0;
    final clientName =
        _currentReservation['client_info']?['nom'] ?? 'le client';

    // Afficher une boîte de dialogue de confirmation d'encaissement
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _DeliveryConfirmationSheet(
        clientName: clientName.toString(),
        totalAmount: totalAmount,
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);

    try {
      final supabase = ref.read(supabaseClientProvider);
      final reservationId = _currentReservation['id'].toString();

      await markReservationDelivered(
        supabase: supabase,
        reservationId: reservationId,
        delivererId: delivererId,
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _currentReservation['status'] = 'delivered';
        _currentReservation['delivered_at'] =
            DateTime.now().toUtc().toIso8601String();
      });

      AppNotification.showSuccess(
        context,
        'Commande livrée et paiement encaissé avec succès !',
      );

      // Attendre brièvement avant de fermer la page pour afficher le statut vert
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppNotification.showError(
        context,
        'Erreur : ${getFriendlyErrorMessage(e)}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientInfo =
        _currentReservation['client_info'] as Map<String, dynamic>? ?? {};
    final products =
        _currentReservation['products'] as List<dynamic>? ?? [];
    final totalAmount =
        (_currentReservation['total_amount'] as num?)?.toDouble() ?? 0.0;
    final groupName = _currentReservation['group_name'];
    final shopName = groupName is Map
        ? (groupName['shop_name'] ?? groupName['name'])?.toString()
        : groupName?.toString();

    final orderId = _currentReservation['id']
            ?.toString()
            .substring(0, 8)
            .toUpperCase() ??
        'N/A';

    final isDelivered = _isDelivered;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Commande #$orderId',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: _buildStatusPill(isDelivered),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Bannière Encaissement / Paiement
            _buildPaymentBanner(totalAmount, isDelivered),
            const SizedBox(height: 16),

            // 2. Fiche Client & Contact
            _buildClientCard(clientInfo),
            const SizedBox(height: 16),

            // 3. Boutique vendeuse (si dispo)
            if (shopName != null && shopName.isNotEmpty) ...[
              _buildShopCard(shopName),
              const SizedBox(height: 16),
            ],

            // 4. Liste des articles commandés
            _buildProductsSection(products),
            const SizedBox(height: 24),

            // 5. Bouton d'action Livré / Statut
            if (isDelivered)
              _buildDeliveredSuccessCard()
            else
              _buildActionDeliveryButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(bool isDelivered) {
    final status = _currentReservation['status']?.toString() ?? 'in_delivery';
    final (label, color, bgColor) = isDelivered
        ? ('Livrée', Colors.white, const Color(0xFF10B981))
        : status == 'in_delivery'
            ? ('En livraison', Colors.white, const Color(0xFF3B82F6))
            : ('Validée', Colors.white, const Color(0xFFF59E0B));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPaymentBanner(double totalAmount, bool isDelivered) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDelivered
              ? [const Color(0xFF10B981), const Color(0xFF059669)]
              : [const Color(0xFF7C3AED), const Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isDelivered
                    ? const Color(0xFF10B981)
                    : const Color(0xFF7C3AED))
                .withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDelivered
                  ? Icons.check_circle_rounded
                  : Icons.payments_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDelivered
                      ? 'Montant encaissé'
                      : 'Montant à encaisser (COD)',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(totalAmount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(Map<String, dynamic> clientInfo) {
    final name = clientInfo['nom']?.toString() ?? 'Client sans nom';
    final contact = clientInfo['contact']?.toString() ?? 'Non renseigné';
    final address = clientInfo['adresse']?.toString() ?? 'Adresse non spécifiée';
    final remark = clientInfo['remarque']?.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_pin_rounded,
                  color: Color(0xFF7C3AED),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Informations Client',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFF3F4F6)),
          _buildInfoRow(
            icon: Icons.person_rounded,
            title: 'Nom',
            value: name,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.phone_rounded,
            title: 'Téléphone',
            value: contact,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.location_on_rounded,
            title: 'Adresse de livraison',
            value: address,
          ),
          if (remark != null && remark.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.notes_rounded,
              title: 'Remarque / Indication',
              value: remark,
              isHighlight: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShopCard(String shopName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Color(0xFFF59E0B),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Boutique Vendeur',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  shopName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection(List<dynamic> products) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_rounded,
                      color: Color(0xFF3B82F6),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Articles à livrer',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${products.length} article${products.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFF3F4F6)),
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Aucun détail de produit disponible.',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 20, color: Color(0xFFF9FAFB)),
              itemBuilder: (context, index) {
                final product = products[index] as Map<dynamic, dynamic>;
                return _buildProductItem(product);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProductItem(Map<dynamic, dynamic> product) {
    final name =
        (product['nom'] ?? product['name'] ?? 'Article sans nom').toString();
    final quantity =
        product['quantité'] as int? ?? product['quantity'] as int? ?? 1;
    final price = num.tryParse(
            (product['prix_unitaire'] ?? product['price'] ?? 0).toString()) ??
        0;
    final imageUrl =
        (product['image'] ?? product['image_url'])?.toString();
    final itemTotal = price * quantity;

    return Row(
      children: [
        // Image du produit
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 56,
            height: 56,
            color: const Color(0xFFF3F4F6),
            child: (imageUrl != null && imageUrl.isNotEmpty)
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.image_not_supported_rounded,
                      color: Color(0xFF9CA3AF),
                      size: 24,
                    ),
                  )
                : const Icon(
                    Icons.inventory_2_rounded,
                    color: Color(0xFF9CA3AF),
                    size: 24,
                  ),
          ),
        ),
        const SizedBox(width: 14),

        // Détails produit
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF111827),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Qté : $quantity',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${CurrencyFormatter.format(price.toDouble())} / unité',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Sous-total
        Text(
          CurrencyFormatter.format(itemTotal.toDouble()),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    bool isHighlight = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isHighlight ? FontWeight.w600 : FontWeight.w600,
                  color: isHighlight
                      ? const Color(0xFFD97706)
                      : const Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionDeliveryButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handleConfirmDelivery,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981), // Green
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: const Color(0xFF10B981).withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Confirmer la livraison & Encaissement',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDeliveredSuccessCard() {
    final deliveredAtStr = _currentReservation['delivered_at']?.toString();
    final dateStr = deliveredAtStr != null
        ? DateTime.tryParse(deliveredAtStr)?.toLocal().toString().split('.')[0]
        : 'Date inconnue';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_rounded,
            color: Color(0xFF10B981),
            size: 32,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Commande livrée et encaissée',
                  style: TextStyle(
                    color: Color(0xFF065F46),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Date: $dateStr',
                  style: const TextStyle(
                    color: Color(0xFF047857),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Feuille de confirmation d'encaissement
class _DeliveryConfirmationSheet extends StatelessWidget {
  final String clientName;
  final double totalAmount;

  const _DeliveryConfirmationSheet({
    required this.clientName,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.attach_money_rounded,
              color: Color(0xFF10B981),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Confirmation de livraison',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Confirmez-vous avoir remis les articles à $clientName et encaissé le montant suivant en espèces ?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              CurrencyFormatter.format(totalAmount),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF10B981),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4B5563),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Annuler',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Oui, Livré',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
