import 'package:live_shopping/core/widgets/bazzar_ui.dart';
import 'package:live_shopping/core/theme/bazzar_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:live_shopping/core/providers/supabase_provider.dart';
import 'package:live_shopping/features/delivery/presentation/providers/deliverer_provider.dart';
import 'package:live_shopping/features/seller_dashboard/presentation/widgets/seller_app_drawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:live_shopping/core/utils/error_helper.dart';
import 'package:live_shopping/core/utils/currency_helper.dart';
import 'package:live_shopping/core/widgets/app_notification.dart';

/// ===============================================================
/// PROVIDER - COMMANDES VENDEUR
/// ===============================================================

final sellerOrdersProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      sellerId,
    ) async {
      if (sellerId.isEmpty) return [];
      debugPrint('DEBUG: Querying reservations for sellerId: "$sellerId"');

      final client = ref.watch(supabaseClientProvider);

      final response = await client
          .from('reservations')
          .select('*')
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;

      final List<Map<String, dynamic>> orders = data
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      /// Récupérer les product IDs uniques.
      final Set<String> productIds = {};

      for (final order in orders) {
        final productsList = order['products'] as List<dynamic>? ?? [];

        for (final product in productsList) {
          if (product is Map && product['product_id'] != null) {
            productIds.add(product['product_id'].toString());
          }
        }
      }

      /// Récupérer les détails produits.
      final Map<String, Map<String, dynamic>> productDetailsMap = {};

      if (productIds.isNotEmpty) {
        try {
          final productsResponse = await client
              .from('products')
              .select('id, name, price, image_url, seller_id')
              .inFilter('id', productIds.toList());

          for (final product in productsResponse) {
            final id = product['id']?.toString();

            if (id != null) {
              productDetailsMap[id] = Map<String, dynamic>.from(product);
            }
          }
        } catch (e) {
          debugPrint('DEBUG: Error fetching product details: $e');
        }
      }

      /// Fusion des détails.
      for (final order in orders) {
        final productsList = order['products'] as List<dynamic>? ?? [];

        final List<Map<String, dynamic>> updatedProductsList = [];

        for (final product in productsList) {
          if (product is Map) {
            final mergedProduct = Map<String, dynamic>.from(product);

            final productId = product['product_id']?.toString();

            if (productId != null && productDetailsMap.containsKey(productId)) {
              final details = productDetailsMap[productId]!;

              mergedProduct['name'] ??= details['name'];
              mergedProduct['nom'] ??= details['name'];

              mergedProduct['prix_unitaire'] ??= details['price'];

              mergedProduct['price'] ??= details['price'];

              mergedProduct['image'] ??= details['image_url'];

              mergedProduct['image_url'] ??= details['image_url'];

              mergedProduct['seller_id'] ??= details['seller_id'];

              mergedProduct['vendeur_id'] ??= details['seller_id'];
            }

            updatedProductsList.add(mergedProduct);
          }
        }

        order['products'] = updatedProductsList;
      }

      return orders;
    });

/// ===============================================================
/// SCREEN
/// ===============================================================

class SellerOrderListScreen extends ConsumerStatefulWidget {
  final String sellerId;

  const SellerOrderListScreen({super.key, required this.sellerId});

  @override
  ConsumerState<SellerOrderListScreen> createState() =>
      _SellerOrderListScreenState();
}

class _SellerOrderListScreenState extends ConsumerState<SellerOrderListScreen> {
  RealtimeChannel? _realtimeChannel;

  String _filter = 'Toutes';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = [
    'Toutes',
    'En attente',
    'Confirmées',
    'En livraison',
    'Livrées',
  ];

  @override
  void initState() {
    super.initState();
    _setupRealtimeSubscription();
  }

  /// =============================================================
  /// REALTIME
  /// =============================================================

  void _setupRealtimeSubscription() {
    final client = Supabase.instance.client;
    final sellerId = widget.sellerId;

    debugPrint(
      '[REALTIME_SELLER] Setting up realtime subscription '
      'for seller=$sellerId',
    );

    _realtimeChannel = client
        .channel('public:reservations:seller_notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'reservations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'seller_id',
            value: sellerId,
          ),
          callback: (payload) {
            debugPrint(
              '[REALTIME_SELLER] Change received: '
              'event=${payload.eventType}',
            );

            ref.invalidate(sellerOrdersProvider(sellerId));
          },
        );

    _realtimeChannel!.subscribe();
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_realtimeChannel != null) {
      debugPrint('[REALTIME_SELLER] Disposing realtime subscription');

      Supabase.instance.client.removeChannel(_realtimeChannel!);
    }

    super.dispose();
  }

  /// =============================================================
  /// VALIDATION COMMANDE
  /// =============================================================

  Future<void> _validateOrder(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> order,
  ) async {
    final client = ref.read(supabaseClientProvider);

    final orderId = order['id'];
    final orderGroupId = order['order_group_id'];

    final now = DateTime.now().toUtc().toIso8601String();

    final updatePayload = {
      'status': 'validated',
      'validated_at': now,
      'updated_at': now,
    };

    try {
      final List<dynamic> updatedRows;

      if (orderGroupId == null) {
        updatedRows = await client
            .from('reservations')
            .update(updatePayload)
            .eq('id', order['id'])
            .eq('status', 'pending')
            .select('id');
      } else {
        updatedRows = await client
            .from('reservations')
            .update(updatePayload)
            .eq('order_group_id', orderGroupId)
            .eq('status', 'pending')
            .select('id');
      }

      if (updatedRows.isEmpty) {
        throw Exception('Aucune commande en attente mise à jour.');
      }

      debugPrint(
        '[ORDER_VALIDATE_SUCCESS] '
        'orderId=$orderId '
        'orderGroupId=$orderGroupId '
        'updatedRows=${updatedRows.length}',
      );

      ref.invalidate(sellerOrdersProvider(widget.sellerId));

      if (context.mounted) {
        await _showOrderMessageDialog(
          context,
          title: 'Commande confirmée',
          message: 'La commande a été confirmée avec succès.',
          isSuccess: true,
        );
      }
    } on PostgrestException catch (error) {
      debugPrint(
        '[ORDER_VALIDATE_SUPABASE_ERROR] '
        'message=${error.message} '
        'code=${error.code}',
      );

      if (context.mounted) {
        await _showOrderMessageDialog(
          context,
          title: 'Validation impossible',
          message: getFriendlyErrorMessage(error),
          isSuccess: false,
        );
      }
    } catch (error) {
      debugPrint('[ORDER_VALIDATE_ERROR] $error');

      if (context.mounted) {
        await _showOrderMessageDialog(
          context,
          title: 'Validation impossible',
          message: getFriendlyErrorMessage(error),
          isSuccess: false,
        );
      }
    }
  }

  /// =============================================================
  /// SELECTION LIVREUR
  /// =============================================================

  void _showDelivererSelectionSheet(
    BuildContext context,
    Map<String, dynamic> order,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final deliverersAsync = ref.watch(
              sellerDeliverersProvider(widget.sellerId),
            );

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * .75,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  /// Handle
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: BazzarColors.border,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  const SizedBox(height: 22),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: BazzarColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.local_shipping_rounded,
                            color: BazzarColors.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Choisir un livreur',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: BazzarColors.ink,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Sélectionnez le livreur pour cette commande',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: BazzarColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  Expanded(
                    child: deliverersAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: BazzarColors.primary,
                        ),
                      ),
                      error: (error, _) =>
                          _SheetError(message: getFriendlyErrorMessage(error)),
                      data: (deliverers) {
                        if (deliverers.isEmpty) {
                          return const _EmptyDeliverers();
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                          itemCount: deliverers.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final deliverer = deliverers[index];

                            return _DelivererTile(
                              name: deliverer.fullName ?? 'Livreur sans nom',
                              email: deliverer.email,
                              avatarUrl: deliverer.avatarUrl,
                              onTap: () {
                                Navigator.pop(sheetContext);

                                _assignToDeliverer(
                                  context,
                                  ref,
                                  order,
                                  deliverer.id,
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// =============================================================
  /// ASSIGNATION LIVREUR
  /// =============================================================

  Future<void> _assignToDeliverer(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> order,
    String delivererId,
  ) async {
    final client = ref.read(supabaseClientProvider);

    try {
      await client
          .from('reservations')
          .update({'status': 'in_delivery', 'deliverer_id': delivererId})
          .eq('id', order['id']);

      ref.invalidate(sellerOrdersProvider(widget.sellerId));

      if (context.mounted) {
        AppNotification.showSuccess(context, 'Commande envoyée au livreur.');
      }
    } catch (e) {
      if (context.mounted) {
        AppNotification.showError(
          context,
          'Erreur : ${getFriendlyErrorMessage(e)}',
        );
      }
    }
  }

  /// =============================================================
  /// DIALOG RESULTAT
  /// =============================================================

  Future<void> _showOrderMessageDialog(
    BuildContext context, {
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    if (!context.mounted) {
      return Future.value();
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFEF2F2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_rounded : Icons.close_rounded,
                    size: 34,
                    color: isSuccess
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: BazzarColors.ink,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: BazzarColors.muted,
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BazzarColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'Continuer',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// =============================================================
  /// KPI METRICS & RECHERCHE
  /// =============================================================

  Widget _buildKpiRow(List<Map<String, dynamic>> orders) {
    final pendingCount = _getFilterCount(orders, 'En attente');
    final validatedCount = _getFilterCount(orders, 'Confirmées');
    final deliveryCount = _getFilterCount(orders, 'En livraison');
    final deliveredCount = _getFilterCount(orders, 'Livrées');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildKpiCard(
            label: 'En attente',
            count: pendingCount,
            color: const Color(0xFFF59E0B),
            icon: Icons.hourglass_top_rounded,
            isSelected: _filter == 'En attente',
            onTap: () => setState(() => _filter = 'En attente'),
          ),
          const SizedBox(width: 8),
          _buildKpiCard(
            label: 'Confirmées',
            count: validatedCount,
            color: const Color(0xFF10B981),
            icon: Icons.check_circle_rounded,
            isSelected: _filter == 'Confirmées',
            onTap: () => setState(() => _filter = 'Confirmées'),
          ),
          const SizedBox(width: 8),
          _buildKpiCard(
            label: 'En route',
            count: deliveryCount,
            color: const Color(0xFF3B82F6),
            icon: Icons.local_shipping_rounded,
            isSelected: _filter == 'En livraison',
            onTap: () => setState(() => _filter = 'En livraison'),
          ),
          const SizedBox(width: 8),
          _buildKpiCard(
            label: 'Livrées',
            count: deliveredCount,
            color: BazzarColors.primary,
            icon: Icons.task_alt_rounded,
            isSelected: _filter == 'Livrées',
            onTap: () => setState(() => _filter = 'Livrées'),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.14) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? color : BazzarColors.border,
                width: isSelected ? 1.8 : 1.0,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(height: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? color : BazzarColors.muted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
          decoration: InputDecoration(
            hintText: 'Rechercher par client, tél ou #ID...',
            hintStyle: const TextStyle(fontSize: 13, color: BazzarColors.muted),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: BazzarColors.primary,
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.cancel_rounded,
                      size: 18,
                      color: BazzarColors.muted,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: BazzarColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: BazzarColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: BazzarColors.primary,
                width: 1.8,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// =============================================================
  /// FILTRES
  /// =============================================================

  Widget _buildFilterBar(List<Map<String, dynamic>> orders) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final filter = _filters[index];

          final count = _getFilterCount(orders, filter);

          final selected = _filter == filter;

          return GestureDetector(
            onTap: () {
              setState(() {
                _filter = filter;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: selected ? BazzarColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: selected ? Colors.transparent : BazzarColors.border,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withValues(alpha: .30),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Text(
                    filter,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF4B5563),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: .18)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : const Color(0xFF6B7280),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  int _getFilterCount(List<Map<String, dynamic>> orders, String filter) {
    if (filter == 'Toutes') {
      return orders.length;
    }

    final statusMap = {
      'En attente': 'pending',
      'Confirmées': 'validated',
      'En livraison': 'in_delivery',
      'Livrées': 'delivered',
    };

    final target = statusMap[filter];

    if (target == null) {
      return 0;
    }

    return orders
        .where((order) => (order['status']?.toString() ?? 'pending') == target)
        .length;
  }

  /// =============================================================
  /// BUILD
  /// =============================================================

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(sellerOrdersProvider(widget.sellerId));

    final currentSellerId =
        Supabase.instance.client.auth.currentUser?.id ?? widget.sellerId;

    return Scaffold(
      backgroundColor: BazzarColors.background,

      drawer: SellerAppDrawer(sellerId: currentSellerId),

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
          builder: (context) {
            return IconButton(
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              icon: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: BazzarColors.soft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.menu_rounded,
                  color: BazzarColors.ink,
                  size: 21,
                ),
              ),
            );
          },
        ),

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Commandes',
              style: TextStyle(
                color: BazzarColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Gérez vos ventes simplement',
              style: TextStyle(
                color: BazzarColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(sellerOrdersProvider(widget.sellerId));
            },
            icon: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: BazzarColors.soft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: BazzarColors.body,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),

      body: ordersAsync.when(
        loading: () => const _PremiumLoading(),

        error: (error, stack) {
          return _PremiumError(
            message: getFriendlyErrorMessage(error),
            onRetry: () {
              ref.invalidate(sellerOrdersProvider(widget.sellerId));
            },
          );
        },

        data: (orders) {
          final filtered = _getFilteredOrders(orders);

          return BazzarCollectionLayout(
            header: [
              const SizedBox(height: 12),

              // 1. KPI Metrics Ribbon
              _buildKpiRow(orders),

              const SizedBox(height: 12),

              // 2. Search Bar
              _buildSearchBar(),

              const SizedBox(height: 12),

              // 3. Status Filters Bar
              _buildFilterBar(orders),

              const SizedBox(height: 12),
            ],
            body: filtered.isEmpty
                ? const _EmptyOrders()
                : RefreshIndicator(
                    color: BazzarColors.primary,
                    backgroundColor: Colors.white,
                    onRefresh: () async {
                      ref.invalidate(sellerOrdersProvider(widget.sellerId));

                      await ref.read(
                        sellerOrdersProvider(widget.sellerId).future,
                      );
                    },
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final order = filtered[index];

                        return _OrderCard(
                          order: order,
                          onValidate: () => _validateOrder(context, ref, order),
                          onAssignDeliverer: () =>
                              _showDelivererSelectionSheet(context, order),
                        );
                      },
                    ),
                  ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredOrders(
    List<Map<String, dynamic>> orders,
  ) {
    final statusMap = {
      'En attente': 'pending',
      'Confirmées': 'validated',
      'En livraison': 'in_delivery',
      'Livrées': 'delivered',
    };

    final targetStatus = statusMap[_filter];
    final query = _searchQuery.trim().toLowerCase();

    return orders.where((order) {
      if (_filter != 'Toutes' && targetStatus != null) {
        final status = order['status']?.toString() ?? 'pending';
        if (status != targetStatus) return false;
      }

      if (query.isNotEmpty) {
        final id = order['id']?.toString().toLowerCase() ?? '';
        final clientInfo = order['client_info'] as Map? ?? {};
        final name = (clientInfo['nom'] ?? '').toString().toLowerCase();
        final phone = (clientInfo['contact'] ?? '').toString().toLowerCase();
        final address = (clientInfo['adresse'] ?? '').toString().toLowerCase();

        final matchId = id.contains(query);
        final matchName = name.contains(query);
        final matchPhone = phone.contains(query);
        final matchAddress = address.contains(query);

        if (!matchId && !matchName && !matchPhone && !matchAddress) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}

/// ===============================================================
/// ORDER CARD
/// ===============================================================

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final Future<void> Function() onValidate;
  final VoidCallback onAssignDeliverer;

  const _OrderCard({
    required this.order,
    required this.onValidate,
    required this.onAssignDeliverer,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> productsList =
        (order['products'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

    final rawId = order['id']?.toString() ?? '';

    final orderId = rawId.isEmpty
        ? 'N/A'
        : rawId.substring(0, rawId.length > 8 ? 8 : rawId.length).toUpperCase();

    final status = order['status']?.toString() ?? 'pending';

    final clientInfo = order['client_info'] as Map<dynamic, dynamic>? ?? {};

    final clientName = clientInfo['nom']?.toString() ?? 'Client';

    final clientPhone = clientInfo['contact']?.toString() ?? '';

    final deliveryAddress = clientInfo['adresse']?.toString() ?? '';

    final deliveryRemark = clientInfo['remarque']?.toString() ?? '';

    final totalAmount =
        num.tryParse(order['total_amount']?.toString() ?? '') ?? 0;

    final totalProductsQty = productsList.fold<num>(0, (sum, item) {
      final quantity =
          num.tryParse(
            (item['quantité'] ?? item['quantity'] ?? 1).toString(),
          ) ??
          1;

      return sum + quantity;
    });

    final createdAtStr = order['created_at']?.toString() ?? '';

    final formattedDate = _formatDate(createdAtStr);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EDF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: BazzarColors.soft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: BazzarColors.primary,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '#$orderId',
                              style: const TextStyle(
                                color: BazzarColors.ink,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Color(0xFFCBD5E1),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              color: BazzarColors.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        clientName,
                        style: const TextStyle(
                          color: BazzarColors.body,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                _StatusBadge(status: status),
              ],
            ),

            const SizedBox(height: 16),

            /// TOTAL
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [BazzarColors.background, BazzarColors.soft],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    size: 18,
                    color: BazzarColors.muted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${totalProductsQty.toStringAsFixed(0)} article(s)',
                    style: const TextStyle(
                      color: BazzarColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatPrice(totalAmount),
                    style: const TextStyle(
                      color: BazzarColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            /// PRODUITS
            const Text(
              'ARTICLES',
              style: TextStyle(
                color: BazzarColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 8),

            ...productsList
                .take(4)
                .map((product) => _ProductRow(product: product)),

            if (productsList.length > 4)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+ ${productsList.length - 4} autre(s)',
                  style: const TextStyle(
                    color: BazzarColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

            /// CLIENT / LIVRAISON
            if (clientPhone.isNotEmpty ||
                deliveryAddress.isNotEmpty ||
                deliveryRemark.isNotEmpty) ...[
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFBFC),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: const Color(0xFFE8EDF3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LIVRAISON',
                      style: TextStyle(
                        color: BazzarColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 10),

                    if (clientPhone.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 16,
                            color: BazzarColors.muted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              clientPhone,
                              style: const TextStyle(
                                color: BazzarColors.ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(text: clientPhone),
                              );
                              AppNotification.showSuccess(
                                context,
                                'Numéro copié : $clientPhone',
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.copy_rounded,
                                    size: 12,
                                    color: BazzarColors.primary,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Copier',
                                    style: TextStyle(
                                      color: BazzarColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                    if (deliveryAddress.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _InfoRow(
                          icon: Icons.location_on_outlined,
                          text: deliveryAddress,
                        ),
                      ),

                    if (deliveryRemark.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _InfoRow(
                          icon: Icons.chat_bubble_outline_rounded,
                          text: deliveryRemark,
                          italic: true,
                        ),
                      ),
                  ],
                ),
              ),
            ],

            /// ACTION
            if (status == 'pending') ...[
              const SizedBox(height: 16),
              _PrimaryActionButton(
                icon: Icons.check_circle_rounded,
                label: 'Confirmer la commande',
                color: const Color(0xFF10B981),
                onPressed: onValidate,
              ),
            ] else if (status == 'validated') ...[
              const SizedBox(height: 16),
              _PrimaryActionButton(
                icon: Icons.local_shipping_rounded,
                label: 'Envoyer au livreur',
                color: BazzarColors.primary,
                onPressed: onAssignDeliverer,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String value) {
    if (value.isEmpty) {
      return 'Date inconnue';
    }

    try {
      final date = DateTime.parse(value).toLocal();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return value.split('T').first;
    }
  }
}

/// ===============================================================
/// PRODUCT ROW
/// ===============================================================

class _ProductRow extends StatelessWidget {
  final Map<String, dynamic> product;

  const _ProductRow({required this.product});

  @override
  Widget build(BuildContext context) {
    final name = (product['name'] ?? product['nom'] ?? 'Produit').toString();

    final quantity =
        num.tryParse(
          (product['quantité'] ?? product['quantity'] ?? 1).toString(),
        ) ??
        1;

    final price =
        num.tryParse(
          (product['prix_unitaire'] ?? product['price'] ?? 0).toString(),
        ) ??
        0;

    final image = (product['image'] ?? product['image_url'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: BazzarColors.soft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: image.isNotEmpty
                  ? Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.shopping_bag_outlined,
                        color: BazzarColors.muted,
                        size: 20,
                      ),
                    )
                  : const Icon(
                      Icons.shopping_bag_outlined,
                      color: BazzarColors.muted,
                      size: 20,
                    ),
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: BazzarColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${quantity.toStringAsFixed(0)} × ${formatPrice(price)}',
                  style: const TextStyle(
                    color: BazzarColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Text(
            formatPrice(price * quantity),
            style: const TextStyle(
              color: BazzarColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================================================
/// STATUS BADGE
/// ===============================================================

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final config = switch (status) {
      'in_delivery' => (
        'En livraison',
        BazzarColors.primaryDark,
        const Color(0xFFFFF7ED),
      ),
      'validated' => (
        'Confirmée',
        const Color(0xFF059669),
        const Color(0xFFECFDF5),
      ),
      'delivered' => (
        'Livrée',
        const Color(0xFF047857),
        const Color(0xFFD1FAE5),
      ),
      'cancelled' => (
        'Annulée',
        const Color(0xFFDC2626),
        const Color(0xFFFEF2F2),
      ),
      _ => ('En attente', const Color(0xFFD97706), const Color(0xFFFFFBEB)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: config.$3,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: config.$2, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            config.$1,
            style: TextStyle(
              color: config.$2,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================================================
/// INFO ROW
/// ===============================================================

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool italic;

  const _InfoRow({required this.icon, required this.text, this.italic = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: BazzarColors.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: BazzarColors.body,
              fontSize: 11,
              height: 1.35,
              fontWeight: FontWeight.w600,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }
}

/// ===============================================================
/// PRIMARY ACTION
/// ===============================================================

class _PrimaryActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _PrimaryActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 19),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}

/// ===============================================================
/// DELIVERER TILE
/// ===============================================================

class _DelivererTile extends StatelessWidget {
  final String name;
  final String email;
  final String? avatarUrl;
  final VoidCallback onTap;

  const _DelivererTile({
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE8EDF3)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFFEEF2FF),
                backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                    ? NetworkImage(avatarUrl!)
                    : null,
                child: avatarUrl == null || avatarUrl!.isEmpty
                    ? const Icon(
                        Icons.person_rounded,
                        color: BazzarColors.primary,
                      )
                    : null,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: BazzarColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: BazzarColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: BazzarColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: BazzarColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===============================================================
/// EMPTY DELIVERERS
/// ===============================================================

class _EmptyDeliverers extends StatelessWidget {
  const _EmptyDeliverers();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: BazzarColors.soft,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                size: 34,
                color: BazzarColors.muted,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun livreur disponible',
              style: TextStyle(
                color: BazzarColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Créez d’abord un livreur depuis votre espace vendeur.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: BazzarColors.muted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===============================================================
/// SHEET ERROR
/// ===============================================================

class _SheetError extends StatelessWidget {
  final String message;

  const _SheetError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: BazzarColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===============================================================
/// EMPTY ORDERS
/// ===============================================================

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [BazzarColors.soft, BazzarColors.lavender],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: BazzarColors.muted,
                size: 42,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Aucune commande',
              style: TextStyle(
                color: BazzarColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              'Les nouvelles commandes apparaîtront ici.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: BazzarColors.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===============================================================
/// LOADING
/// ===============================================================

class _PremiumLoading extends StatelessWidget {
  const _PremiumLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              color: BazzarColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chargement des commandes...',
            style: TextStyle(
              color: BazzarColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================================================
/// ERROR
/// ===============================================================

class _PremiumError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PremiumError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: Color(0xFFEF4444),
                size: 35,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Impossible de charger',
              style: TextStyle(
                color: BazzarColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: BazzarColors.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  'Réessayer',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
