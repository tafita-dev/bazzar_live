import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:live_shopping/core/utils/currency_formatter.dart';
import 'package:live_shopping/core/widgets/app_notification.dart';
import '../../domain/entities/reservation.dart';
import '../providers/reservation_provider.dart';

class ClientReservationsPage extends ConsumerStatefulWidget {
  final String clientId;
  const ClientReservationsPage({super.key, required this.clientId});

  @override
  ConsumerState<ClientReservationsPage> createState() =>
      _ClientReservationsPageState();
}

class _ClientReservationsPageState
    extends ConsumerState<ClientReservationsPage> {
  String _filter = 'Toutes';
  final List<String> _filters = [
    'Toutes',
    'En attente',
    'Confirmées',
    'En livraison',
    'Livrées',
    'Annulées',
  ];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showQrCodeModal(BuildContext context, Reservation r) {
    final String shortId = r.id.length > 8 ? r.id.substring(0, 8).toUpperCase() : r.id.toUpperCase();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x29000000),
                blurRadius: 30,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title & Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.qr_code_rounded,
                      color: Color(0xFF7C3AED),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Code de réception',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Text(
                'Présentez ce QR Code au livreur lors de la livraison',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),

              // Order ID pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Commande #$shortId',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4B5563),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: r.id));
                        AppNotification.showSuccess(
                          modalContext,
                          'Identifiant commande copié',
                        );
                      },
                      child: const Icon(
                        Icons.copy_rounded,
                        size: 14,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // QR Box
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.10),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: r.id,
                  version: QrVersions.auto,
                  size: 210,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF111827),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF111827),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(modalContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111827),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Fermer',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final reservationsAsync =
        ref.watch(clientReservationsProvider(widget.clientId));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Mes commandes',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: Colors.white,
            letterSpacing: 0,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: reservationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'Impossible de charger les réservations\n$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(
                    clientReservationsProvider(widget.clientId).future,
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (reservations) {
          // KPI metrics
          final int totalCount = reservations.length;
          final int pendingCount = reservations.where((r) {
            final s = r.status.toLowerCase();
            return s == 'pending';
          }).length;
          final int validatedCount = reservations.where((r) {
            final s = r.status.toLowerCase();
            return s == 'validated' || s == 'confirmed';
          }).length;
          final int inDeliveryCount = reservations.where((r) {
            final s = r.status.toLowerCase();
            return s == 'in_delivery';
          }).length;
          final int deliveredCount = reservations.where((r) {
            final s = r.status.toLowerCase();
            return s == 'delivered' || s == 'completed';
          }).length;

          // Filter by status
          List<Reservation> filtered = reservations;
          if (_filter != 'Toutes') {
            filtered = reservations.where((r) {
              return _getStatusLabel(r.status) == _filter.toUpperCase();
            }).toList();
          }

          // Filter by search query
          if (_searchQuery.trim().isNotEmpty) {
            final q = _searchQuery.trim().toLowerCase();
            filtered = filtered.where((r) {
              final idMatch = r.id.toLowerCase().contains(q);
              final groupMatch = (r.groupName?['name'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(q);
              final productMatch = r.products.any((p) {
                final name = (p['name'] ?? p['title'] ?? '').toString().toLowerCase();
                return name.contains(q);
              });
              return idMatch || groupMatch || productMatch;
            }).toList();
          }

          return Column(
            children: [
              // Top KPI Summary Cards
              _buildKpiSummary(
                total: totalCount,
                inProgress: pendingCount + validatedCount + inDeliveryCount,
                delivered: deliveredCount,
              ),

              // Search bar
              _buildSearchBar(),

              // Filter chips bar
              _buildFilterBar(
                totalCount: totalCount,
                pendingCount: pendingCount,
                validatedCount: validatedCount,
                inDeliveryCount: inDeliveryCount,
                deliveredCount: deliveredCount,
              ),

              const SizedBox(height: 8),

              // Order List
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFF7C3AED),
                  onRefresh: () => ref.refresh(
                    clientReservationsProvider(widget.clientId).future,
                  ),
                  child: filtered.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) => _OrderCard(
                            reservation: filtered[index],
                            onShowQr: () => _showQrCodeModal(
                              context,
                              filtered[index],
                            ),
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildKpiSummary({
    required int total,
    required int inProgress,
    required int delivered,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              title: 'Total',
              count: total,
              color: const Color(0xFF7C3AED),
              bgLight: const Color(0xFFFFF1F2),
              icon: Icons.receipt_long_rounded,
              isActive: _filter == 'Toutes',
              onTap: () => setState(() => _filter = 'Toutes'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildMetricCard(
              title: 'En cours',
              count: inProgress,
              color: const Color(0xFFF59E0B),
              bgLight: const Color(0xFFFFFBEB),
              icon: Icons.hourglass_top_rounded,
              isActive: _filter == 'En attente' ||
                  _filter == 'Confirmées' ||
                  _filter == 'En livraison',
              onTap: () {
                setState(() {
                  _filter = 'Confirmées';
                });
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildMetricCard(
              title: 'Livrées',
              count: delivered,
              color: const Color(0xFF10B981),
              bgLight: const Color(0xFFECFDF5),
              icon: Icons.check_circle_outline_rounded,
              isActive: _filter == 'Livrées',
              onTap: () => setState(() => _filter = 'Livrées'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required int count,
    required Color color,
    required Color bgLight,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? bgLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? color.withValues(alpha: 0.6) : const Color(0xFFE5E7EB),
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF111827).withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isActive ? color : const Color(0xFF6B7280),
                  ),
                ),
                Icon(icon, size: 16, color: color),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isActive ? color : const Color(0xFF111827),
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _searchQuery.isNotEmpty
                ? const Color(0xFF7C3AED)
                : const Color(0xFFE5E7EB),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF111827).withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
          decoration: InputDecoration(
            hintText: 'Rechercher par N° commande, article, boutique...',
            hintStyle: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFF7C3AED),
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear_rounded,
                      color: Color(0xFF6B7280),
                      size: 18,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar({
    required int totalCount,
    required int pendingCount,
    required int validatedCount,
    required int inDeliveryCount,
    required int deliveredCount,
  }) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filterName = _filters[index];
          final isSelected = _filter == filterName;

          String countText = '';
          switch (filterName) {
            case 'Toutes':
              countText = '$totalCount';
              break;
            case 'En attente':
              countText = '$pendingCount';
              break;
            case 'Confirmées':
              countText = '$validatedCount';
              break;
            case 'En livraison':
              countText = '$inDeliveryCount';
              break;
            case 'Livrées':
              countText = '$deliveredCount';
              break;
            default:
              break;
          }

          return InkWell(
            onTap: () => setState(() => _filter = filterName),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF7C3AED) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFFE5E7EB),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.30),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    filterName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF4B5563),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  if (countText.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.25)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        countText,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF6B7280),
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool isSearching = _searchQuery.isNotEmpty;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.25), width: 2),
              ),
              child: Icon(
                isSearching
                    ? Icons.search_off_rounded
                    : Icons.receipt_long_rounded,
                color: const Color(0xFF7C3AED),
                size: 46,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching
                  ? 'Aucune commande trouvée'
                  : 'Aucune commande enregistrée',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? 'Aucun résultat ne correspond à "$_searchQuery".'
                  : 'Vos commandes de sessions live s\'afficheront ici.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isSearching) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                icon: const Icon(Icons.clear_rounded, size: 16),
                label: const Text('Réinitialiser la recherche'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF7C3AED),
                  side: const BorderSide(color: Color(0xFF7C3AED)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'EN ATTENTE';
      case 'validated':
      case 'confirmed':
        return 'CONFIRMÉES';
      case 'in_delivery':
        return 'EN LIVRAISON';
      case 'delivered':
      case 'completed':
        return 'LIVRÉES';
      case 'cancelled':
        return 'ANNULÉES';
      default:
        return status.toUpperCase();
    }
  }
}

class _OrderCard extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback onShowQr;

  const _OrderCard({
    required this.reservation,
    required this.onShowQr,
  });

  (Color, IconData) _getStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return (const Color(0xFFF59E0B), Icons.hourglass_top_rounded);
      case 'validated':
      case 'confirmed':
        return (const Color(0xFF10B981), Icons.verified_rounded);
      case 'in_delivery':
        return (const Color(0xFF3B82F6), Icons.local_shipping_rounded);
      case 'delivered':
      case 'completed':
        return (const Color(0xFF7C3AED), Icons.check_circle_rounded);
      case 'cancelled':
        return (const Color(0xFFEF4444), Icons.cancel_rounded);
      default:
        return (const Color(0xFF6B7280), Icons.info_outline_rounded);
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'EN ATTENTE';
      case 'validated':
      case 'confirmed':
        return 'CONFIRMÉE';
      case 'in_delivery':
        return 'EN LIVRAISON';
      case 'delivered':
      case 'completed':
        return 'LIVRÉE';
      case 'cancelled':
        return 'ANNULÉE';
      default:
        return status.toUpperCase();
    }
  }

  Widget _buildProductPreview(List<dynamic> products) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 52,
      margin: const EdgeInsets.only(top: 14),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final p = products[index] as Map<String, dynamic>;
          final imageUrl = p['image'] ?? p['image_url'] ?? '';
          final qty = p['quantity'] ?? p['quantité'] ?? 1;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1.5,
                  ),
                  color: const Color(0xFFF9FAFB),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: imageUrl.toString().isNotEmpty
                      ? Image.network(
                          imageUrl.toString(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              size: 22,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.shopping_bag_outlined,
                            size: 22,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                ),
              ),
              if (qty > 1)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Text(
                      'x$qty',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final (statusColor, statusIcon) = _getStatusStyle(r.status);
    final int productCount = (r.products as List).length;
    final String orderId = r.id.isNotEmpty
        ? r.id.substring(0, r.id.length > 8 ? 8 : r.id.length).toUpperCase()
        : '';

    final bool canShowQr =
        r.status == 'validated' || r.status == 'confirmed' || r.status == 'in_delivery';

    const Color primaryBrand = Color(0xFF7C3AED);
    const Color darkSlate = Color(0xFF111827);
    const Color lightSlate = Color(0xFFF3F4F6);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF111827).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => context.go('/client/orders/details', extra: r),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Shop Name & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (orderId.isNotEmpty)
                            Text(
                              '#$orderId',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF9CA3AF),
                                letterSpacing: 0.5,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            r.groupName != null && r.groupName!['name'] != null
                                ? r.groupName!['name'].toString()
                                : 'Boutique Bazzar',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: darkSlate,
                              letterSpacing: 0,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 12),
                          const SizedBox(width: 5),
                          Text(
                            _getStatusLabel(r.status),
                            style: TextStyle(
                              fontSize: 10,
                              color: statusColor,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Meta info: Date and items count
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      r.createdAt?.toString().split(' ')[0] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 14,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$productCount article(s)',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                // Product preview images
                _buildProductPreview(r.products),

                const Divider(height: 26, thickness: 1, color: lightSlate),

                // Total and Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total commande',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.format(
                            (r.totalAmount ?? 0.0).toDouble(),
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            color: darkSlate,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Fast QR Code button for delivery validation
                        if (canShowQr) ...[
                          InkWell(
                            onTap: onShowQr,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.qr_code_2_rounded,
                                    size: 16,
                                    color: Color(0xFF7C3AED),
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'QR Code',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: Color(0xFF7C3AED),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],

                        // Details button
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: primaryBrand.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Détails',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: primaryBrand,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 10,
                                color: primaryBrand,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
