import 'package:live_shopping/core/theme/bazzar_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:live_shopping/core/utils/currency_formatter.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/sales_performance_chart.dart';
import '../widgets/seller_app_drawer.dart';
import '../../../auth/presentation/providers/profile_provider.dart';
import 'orders/seller_order_list_screen.dart';

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellerId = Supabase.instance.client.auth.currentUser?.id ?? '';

    // Souscription pour le temps réel
    ref.watch(dashboardRealtimeProvider(sellerId));

    final statsAsync = ref.watch(dashboardStatsProvider(sellerId));
    final profileAsync = ref.watch(profileProvider(sellerId));
    final ordersAsync = ref.watch(sellerOrdersProvider(sellerId));

    final sellerName = profileAsync.value?.fullName ?? 'Ahmed';
    final avatarUrl = profileAsync.value?.avatarUrl;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
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

        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: BazzarColors.ink),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),

        title: const Text(
          'Tableau de bord',
          style: TextStyle(
            color: BazzarColors.ink,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: BazzarColors.soft,
              backgroundImage: NetworkImage(
                avatarUrl ??
                    'https://api.dicebear.com/7.x/adventurer/png?seed=$sellerName',
              ),
            ),
          ),
        ],
      ),
      drawer: SellerAppDrawer(sellerId: sellerId),
      body: statsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: BazzarColors.primary),
        ),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Welcome Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bonjour, $sellerName 👋',
                                style: const TextStyle(
                                  color: BazzarColors.ink,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Pilotez votre boutique et vos diffusions en direct.',
                                style: TextStyle(
                                  color: BazzarColors.muted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: BazzarColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.insights_rounded,
                            color: BazzarColors.primary,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => context.go('/seller/live_shopping'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: BazzarColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.videocam_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Démarrer un Live',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 2. Grid of KPIs (Premium)
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                childAspectRatio: 1.3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildKpiCard(
                    title: 'Revenue (Livré)',
                    value: CurrencyFormatter.format(
                      double.tryParse(
                            (stats['total_revenue'] ?? 0).toString(),
                          ) ??
                          0.0,
                    ),
                    icon: Icons.account_balance_wallet_rounded,
                    color: const Color(0xFF10B981),
                  ),
                  _buildKpiCard(
                    title: 'Total Commandes',
                    value: '${stats['total_orders'] ?? 0}',
                    icon: Icons.shopping_cart_rounded,
                    color: const Color(0xFF3B82F6),
                  ),
                  _buildKpiCard(
                    title: 'Vues Totales',
                    value: '${stats['total_views'] ?? 0}',
                    icon: Icons.play_circle_rounded,
                    color: const Color(0xFFEF4444),
                  ),
                  _buildKpiCard(
                    title: 'Catégories',
                    value: '${stats['category_count'] ?? 0}',
                    icon: Icons.category_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Status breakdown
              const Text(
                'Détails des commandes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: BazzarColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 4,
                childAspectRatio: 0.8,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStatusBadge(
                    'En attente',
                    '${stats['pending_orders'] ?? 0}',
                    const Color(0xFFF59E0B),
                  ),
                  _buildStatusBadge(
                    'Validée',
                    '${stats['validated_orders'] ?? 0}',
                    const Color(0xFF10B981),
                  ),
                  _buildStatusBadge(
                    'En cours',
                    '${stats['in_delivery_orders'] ?? 0}',
                    const Color(0xFF3B82F6),
                  ),
                  _buildStatusBadge(
                    'Livrée',
                    '${stats['delivered_orders'] ?? 0}',
                    BazzarColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 4. Chart Title and Widget
              const Text(
                'Ventes (7 derniers jours)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: BazzarColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              // Card container for chart
              Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SalesPerformanceChart(
                      dailySales:
                          (stats['daily_sales'] as List<dynamic>?) ?? [],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (index) {
                        return Text(
                          'J-${6 - index}',
                          style: const TextStyle(
                            color: BazzarColors.muted,
                            fontSize: 10,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. Recent Orders Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Commandes récentes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: BazzarColors.ink,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.push('/seller/orders');
                    },
                    child: const Text(
                      'Voir tout',
                      style: TextStyle(
                        color: BazzarColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 6. Recent Orders List
              ordersAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: BazzarColors.primary),
                ),
                error: (err, _) => Center(child: Text('Erreur: $err')),
                data: (orders) {
                  if (orders.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'Aucune commande récente.',
                          style: TextStyle(color: BazzarColors.muted),
                        ),
                      ),
                    );
                  }
                  final order = orders.first;
                  final productsList =
                      order['products'] as List<dynamic>? ?? [];
                  if (productsList.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final product = productsList.first as Map<dynamic, dynamic>;

                  final orderId = order['id']
                      .toString()
                      .substring(0, min(8, order['id'].toString().length))
                      .toUpperCase();
                  final productName =
                      (product['name'] ?? product['nom'] ?? 'Produit')
                          .toString();
                  final status = order['status'] as String? ?? 'pending';

                  final (
                    statusText,
                    statusColor,
                    statusBgColor,
                  ) = switch (status) {
                    'in_delivery' => (
                      'En livraison',
                      const Color(0xFF3B82F6),
                      const Color(0xFFDBEAFE),
                    ),
                    'validated' => (
                      'Validée',
                      const Color(0xFF10B981),
                      const Color(0xFFD1FAE5),
                    ),
                    'delivered' => (
                      'Livrée',
                      const Color(0xFF3B82F6),
                      const Color(0xFFDBEAFE),
                    ),
                    _ => (
                      'En attente',
                      const Color(0xFFF59E0B),
                      const Color(0xFFFEF3C7),
                    ),
                  };

                  final price =
                      num.tryParse(
                        (product['prix_unitaire'] ?? product['price'] ?? 0)
                            .toString(),
                      ) ??
                      0;
                  final quantity =
                      product['quantité'] as int? ??
                      product['quantity'] as int? ??
                      1;
                  final totalCardAmount = price * quantity;

                  final createdAtStr = order['created_at'] != null
                      ? DateTime.tryParse(
                              order['created_at'].toString(),
                            )?.toLocal().toString().split(' ')[0] ??
                            'Date inconnue'
                      : 'Date inconnue';

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#$orderId',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: BazzarColors.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              productName,
                              style: const TextStyle(
                                color: BazzarColors.muted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              createdAtStr,
                              style: const TextStyle(
                                color: BazzarColors.muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusBgColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              CurrencyFormatter.format(
                                totalCardAmount.toDouble(),
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: BazzarColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: BazzarColors.soft),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: BazzarColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: BazzarColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: BazzarColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  int min(int a, int b) => a < b ? a : b;
}
