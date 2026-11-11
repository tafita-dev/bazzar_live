import 'package:live_shopping/core/widgets/bazzar_ui.dart';
import 'package:live_shopping/core/theme/bazzar_colors.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/utils/gallery_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/notification_service.dart';
import '../../domain/entities/reservation.dart';

class ReservationDetailsPage extends StatefulWidget {
  final Reservation reservation;

  const ReservationDetailsPage({super.key, required this.reservation});

  @override
  State<ReservationDetailsPage> createState() => _ReservationDetailsPageState();
}

class _ReservationDetailsPageState extends State<ReservationDetailsPage> {
  final GlobalKey _qrKey = GlobalKey();

  Future<void> _downloadQrCode(BuildContext context) async {
    try {
      RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/qr_code_${widget.reservation.id}.png',
      );
      await tempFile.writeAsBytes(pngBytes);

      final success = await GalleryService.saveImageToGallery(tempFile.path);

      if (context.mounted) {
        if (success) {
          NotificationService.showSuccess(context, 'QR Code enregistré');
        } else {
          NotificationService.showError(context, 'Erreur enregistrement');
        }
      }
    } catch (e) {
      if (context.mounted) {
        NotificationService.showError(context, 'Erreur: $e');
      }
    }
  }

  Color _getStatusColor() {
    switch (widget.reservation.status.toLowerCase()) {
      case 'validated':
        return const Color(0xFF10B981); // Emerald 500
      case 'pending':
        return const Color(0xFFF59E0B); // Amber 500
      case 'delivered':
        return const Color(0xFF3B82F6); // Blue 500
      case 'in_delivery':
        return const Color(0xFF8B5CF6); // Violet 500
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel() {
    switch (widget.reservation.status.toLowerCase()) {
      case 'pending':
        return 'EN ATTENTE';
      case 'validated':
        return 'CONFIRMÉE';
      case 'delivered':
        return 'LIVRÉE';
      case 'cancelled':
        return 'ANNULÉE';
      case 'in_delivery':
        return 'EN LIVRAISON';
      default:
        return widget.reservation.status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final products = (widget.reservation.products as List)
        .cast<Map<String, dynamic>>();

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

        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back_rounded, color: BazzarColors.ink),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/client/orders');
            }
          },
        ),
        title: const BazzarPageTitle(
          title: Text(
            'Détails Commande',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: 'Les informations de votre commande',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Status & Total Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: BazzarColors.border),
                boxShadow: [
                  BoxShadow(
                    color: BazzarColors.ink.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Statut de la commande',
                            style: TextStyle(
                              color: BazzarColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _getStatusLabel(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Montant total',
                            style: TextStyle(
                              color: BazzarColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(
                              (widget.reservation.totalAmount as num? ?? 0.0)
                                  .toDouble(),
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              color: BazzarColors.ink,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: BazzarColors.soft, height: 1),
                  const SizedBox(height: 18),

                  // Delivery Timeline
                  _buildDeliveryTimeline(),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section QR Code (if confirmed/validated/in_delivery)
            if (widget.reservation.status == 'validated' ||
                widget.reservation.status == 'in_delivery') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: BazzarColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: BazzarColors.ink.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_rounded,
                          color: BazzarColors.primary,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Code de réception client',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: BazzarColors.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Présentez ce QR Code au livreur lors de la remise',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: BazzarColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: BazzarColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: BazzarColors.border),
                      ),
                      child: RepaintBoundary(
                        key: _qrKey,
                        child: QrImageView(
                          data: widget.reservation.id,
                          version: QrVersions.auto,
                          size: 190.0,
                          backgroundColor: BazzarColors.background,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: () => _downloadQrCode(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BazzarColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text(
                        'Télécharger le QR Code',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Products List
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: BazzarColors.border),
                boxShadow: [
                  BoxShadow(
                    color: BazzarColors.ink.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_rounded,
                        size: 18,
                        color: BazzarColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Articles commandés (${products.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: BazzarColors.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...products.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: BazzarColors.soft,
                              border: Border.all(color: BazzarColors.border),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image.network(
                                p['image'] ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 22,
                                  color: BazzarColors.muted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p['nom'] ?? 'Produit',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: BazzarColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Quantité : ${p['quantity'] ?? 1}',
                                  style: const TextStyle(
                                    color: BazzarColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(
                              ((p['price'] as num?) ?? 0.0).toDouble(),
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: BazzarColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Client Info Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: BazzarColors.border),
                boxShadow: [
                  BoxShadow(
                    color: BazzarColors.ink.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.local_shipping_rounded,
                        size: 18,
                        color: BazzarColors.primary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Informations de livraison',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: BazzarColors.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.person_rounded,
                    'Destinataire',
                    widget.reservation.clientInfo['nom'] ?? 'N/A',
                  ),
                  _buildInfoRow(
                    Icons.phone_rounded,
                    'Téléphone',
                    widget.reservation.clientInfo['contact'] ?? 'N/A',
                  ),
                  _buildInfoRow(
                    Icons.location_on_rounded,
                    'Adresse',
                    widget.reservation.clientInfo['adresse'] ?? 'N/A',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryTimeline() {
    final status = widget.reservation.status.toLowerCase();
    int currentStep = 0;
    if (status == 'pending') {
      currentStep = 1;
    } else if (status == 'validated' || status == 'confirmed') {
      currentStep = 2;
    } else if (status == 'in_delivery') {
      currentStep = 3;
    } else if (status == 'delivered' || status == 'completed') {
      currentStep = 4;
    }

    final steps = [
      ('Reçue', Icons.receipt_rounded),
      ('Confirmée', Icons.thumb_up_rounded),
      ('En route', Icons.local_shipping_rounded),
      ('Livrée', Icons.check_circle_rounded),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(steps.length, (index) {
        final isDone = (index + 1) <= currentStep;
        final isCurrent = (index + 1) == currentStep;
        final color = isDone
            ? (status == 'delivered'
                  ? const Color(0xFF10B981)
                  : BazzarColors.primary)
            : const Color(0xFFCBD5E1);

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: isDone ? 0.15 : 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color,
                          width: isCurrent ? 2 : 1,
                        ),
                      ),
                      child: Icon(steps[index].$2, color: color, size: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      steps[index].$1,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isDone ? FontWeight.w800 : FontWeight.w500,
                        color: isDone ? BazzarColors.ink : BazzarColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (index < steps.length - 1)
                Container(
                  width: 12,
                  height: 2,
                  color: (index + 1) < currentStep
                      ? BazzarColors.primary
                      : BazzarColors.border,
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: BazzarColors.muted),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: BazzarColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: BazzarColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
