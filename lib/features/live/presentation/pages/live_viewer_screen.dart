import '../widgets/facebook_live_player.dart';
import 'package:live_shopping/core/theme/bazzar_colors.dart';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:live_shopping/core/utils/currency_formatter.dart';
import 'package:live_shopping/core/utils/gallery_service.dart';
import 'package:live_shopping/core/utils/currency_helper.dart';
import 'package:live_shopping/core/widgets/app_notification.dart';

import '../../../auth/presentation/providers/profile_provider.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../providers/live_provider.dart';

class LiveViewerScreen extends ConsumerStatefulWidget {
  final String liveId;

  const LiveViewerScreen({super.key, required this.liveId});

  @override
  ConsumerState<LiveViewerScreen> createState() => _LiveViewerScreenState();
}

class _LiveViewerScreenState extends ConsumerState<LiveViewerScreen> {
  final TextEditingController _searchController = TextEditingController();

  final Map<String, _CartLine> _cart = {};

  final ValueNotifier<String> _queryNotifier = ValueNotifier<String>('');

  bool _isCheckoutOpen = false;

  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final user = Supabase.instance.client.auth.currentUser;

      if (user != null) {
        Supabase.instance.client
            .rpc(
              'record_live_view',
              params: {'p_live_id': widget.liveId, 'p_user_id': user.id},
            )
            .then((_) {
              debugPrint('[DEBUG] record_live_view success: ${widget.liveId}');
            })
            .catchError((error) {
              debugPrint('[DEBUG] record_live_view error: $error');
            });
      }
    });
  }

  // ============================================================
  // PANIER
  // ============================================================

  void _increaseQuantity(Product product, [VoidCallback? onUpdate]) {
    final currentQuantity = _cart[product.id]?.quantity ?? 0;

    if (currentQuantity >= product.stock) {
      if (mounted) {
        AppNotification.showError(context, 'Stock insuffisant.');
      }
      return;
    }

    setState(() {
      _cart[product.id] = _CartLine(
        product: product,
        quantity: currentQuantity + 1,
      );
    });

    onUpdate?.call();
  }

  void _decreaseQuantity(Product product, [VoidCallback? onUpdate]) {
    final currentQuantity = _cart[product.id]?.quantity ?? 0;

    if (currentQuantity <= 1) {
      _removeItem(product.id, onUpdate);
      return;
    }

    setState(() {
      _cart[product.id] = _CartLine(
        product: product,
        quantity: currentQuantity - 1,
      );
    });

    onUpdate?.call();
  }

  void _removeItem(String productId, [VoidCallback? onUpdate]) {
    if (!_cart.containsKey(productId)) return;

    setState(() {
      _cart.remove(productId);
    });

    onUpdate?.call();
  }

  void _addToCart(Product product) {
    final currentQuantity = _cart[product.id]?.quantity ?? 0;

    if (currentQuantity >= product.stock) {
      if (mounted) {
        AppNotification.showError(context, 'Stock insuffisant.');
      }
      return;
    }

    setState(() {
      _cart[product.id] = _CartLine(
        product: product,
        quantity: currentQuantity + 1,
      );
    });

    if (mounted) {
      AppNotification.showSuccess(context, '${product.name} ajouté au panier.');
    }
  }

  // ============================================================
  // REALTIME
  // ============================================================

  void _setupRealtimeSubscription(String sellerId) {
    if (_realtimeChannel != null) return;

    final client = Supabase.instance.client;

    _realtimeChannel = client
        .channel('public:products:seller_$sellerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'products',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'seller_id',
            value: sellerId,
          ),
          callback: (payload) {
            if (!mounted) return;

            debugPrint(
              '[REALTIME_NOTIFICATION] '
              'Change received: event=${payload.eventType}',
            );

            ref.invalidate(sellerProductsProvider(sellerId));
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (_realtimeChannel != null) {
      Supabase.instance.client.removeChannel(_realtimeChannel!);
    }

    _searchController.dispose();
    _queryNotifier.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final liveAsync = ref.watch(liveByIdProvider(widget.liveId));

    return Scaffold(
      backgroundColor: BazzarColors.background,

      appBar: AppBar(
        backgroundColor: BazzarColors.ink,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/client');
            }
          },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [BazzarColors.primary, Color(0xFFEF4444)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fiber_manual_record, color: Colors.white, size: 7),
                  SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Diffusion en direct',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Colors.white,
                  letterSpacing: 0,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: _cart.isEmpty ? null : _showCheckoutSheet,
                icon: const Icon(
                  Icons.shopping_cart_rounded,
                  color: Colors.white,
                ),
              ),

              if (_cart.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: BazzarColors.primary,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: BazzarColors.primary.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      '${_cart.values.fold<int>(0, (sum, line) => sum + line.quantity)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),

      body: liveAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),

        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Erreur: $error', textAlign: TextAlign.center),
          ),
        ),

        data: (live) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;

            _setupRealtimeSubscription(live.sellerId);
          });

          final screenSize = MediaQuery.sizeOf(context);

          final liveHeight = (screenSize.height * 0.55).clamp(360.0, 620.0);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),

            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),

                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: liveHeight,
                          maxHeight: liveHeight,
                          minWidth: double.infinity,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: FacebookLivePlayer(
                            facebookUrl: live.facebookUrl,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        live.title,
                        style: const TextStyle(
                          color: BazzarColors.ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        live.shopName ?? live.sellerName,
                        style: const TextStyle(
                          color: BazzarColors.muted,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          _queryNotifier.value = value.trim().toLowerCase();
                        },
                        decoration: InputDecoration(
                          hintText: 'Rechercher un produit',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              _SliverProductsSection(
                sellerId: live.sellerId,
                queryNotifier: _queryNotifier,
                onAddToCart: _addToCart,
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 18)),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // CHECKOUT
  // ============================================================

  Future<void> _showCheckoutSheet() async {
    if (_isCheckoutOpen) return;

    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      if (mounted) {
        context.go('/login');
      }
      return;
    }

    if (_cart.isEmpty) return;

    _isCheckoutOpen = true;

    final profile = ref.read(profileProvider(user.id)).valueOrNull;

    _CheckoutResult? result;

    try {
      result = await showModalBottomSheet<_CheckoutResult>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: false,

        builder: (sheetContext) {
          return _CheckoutSheet(
            initialName: profile?.fullName ?? '',
            initialPhone: profile?.phone ?? '',
            initialAddress: profile?.address ?? '',
            cart: Map<String, _CartLine>.from(_cart),
            onIncrease: _increaseQuantity,
            onDecrease: _decreaseQuantity,
            onRemove: _removeItem,
            onSubmit:
                ({
                  required String clientName,
                  required String clientPhone,
                  required String deliveryAddress,
                  required String deliveryRemark,
                }) async {
                  return _createOrder(
                    clientName: clientName,
                    clientPhone: clientPhone,
                    deliveryAddress: deliveryAddress,
                    deliveryRemark: deliveryRemark,
                  );
                },
          );
        },
      );
    } finally {
      // IMPORTANT :
      // Ne PAS disposer ici les TextEditingController.
      //
      // Les controllers appartiennent maintenant
      // à _CheckoutSheet et sont détruits dans
      // son propre dispose().
      _isCheckoutOpen = false;
    }

    if (!mounted || result == null) {
      return;
    }

    if (result.isSuccess && result.qrToken != null) {
      await _showOrderCreatedDialog(result.qrToken!);

      if (mounted) {
        setState(() {
          _cart.clear();
        });
      }
    }
  }

  // ============================================================
  // CREATE ORDER
  // ============================================================

  Future<String> _createOrder({
    required String clientName,
    required String clientPhone,
    required String deliveryAddress,
    required String deliveryRemark,
  }) async {
    final client = Supabase.instance.client;

    final live = ref.read(liveByIdProvider(widget.liveId)).valueOrNull;

    final groupInfo = {
      'name': live?.shopName ?? live?.sellerName ?? 'Vendeur inconnu',
    };

    String? paymentMethodId;

    try {
      final paymentMethod = await client
          .from('payment_methods')
          .select('id')
          .eq('code', 'cod')
          .maybeSingle();

      if (paymentMethod != null) {
        paymentMethodId = paymentMethod['id'] as String?;
      }
    } catch (error) {
      debugPrint(
        '[ORDER_CREATE_WARNING] '
        'Impossible de récupérer COD: $error',
      );
    }

    final items = _cart.values
        .map(
          (line) => {
            'product_id': line.product.id,
            'quantity': line.quantity,
            'image': line.product.imageUrl,
            'price': line.product.price,
          },
        )
        .toList();

    if (items.isEmpty) {
      throw Exception('Le panier est vide.');
    }

    try {
      final response = await client.rpc(
        'create_cod_reservation',
        params: {
          'p_items': items,
          'p_client_name': clientName,
          'p_client_phone': clientPhone,
          'p_delivery_address': deliveryAddress,
          'p_payment_method_id': paymentMethodId,
          'p_delivery_remark': deliveryRemark.isEmpty ? null : deliveryRemark,
          'p_group_info': groupInfo,
          'p_seller_id': live?.sellerId,
        },
      );

      debugPrint('[ORDER_CREATE_SUCCESS] response=$response');

      if (response is Map) {
        final resId = response['id'] ?? response['reservation_id'];
        if (resId != null) {
          return resId.toString();
        }
      }

      throw Exception('Commande non créée: réponse Supabase invalide.');
    } on PostgrestException catch (error) {
      debugPrint(
        '[ORDER_CREATE_SUPABASE_ERROR] '
        'code=${error.code} '
        'message=${error.message} '
        'details=${error.details}',
      );

      rethrow;
    } catch (error, stackTrace) {
      debugPrint('[ORDER_CREATE_UNEXPECTED_ERROR] $error');

      debugPrint('[ORDER_CREATE_STACK] $stackTrace');

      rethrow;
    }
  }

  // ============================================================
  // QR DOWNLOAD
  // ============================================================

  Future<void> _downloadQrCode(GlobalKey key) async {
    try {
      final qrContext = key.currentContext;

      if (qrContext == null) {
        throw Exception('QR Code non disponible.');
      }

      final renderObject = qrContext.findRenderObject();

      if (renderObject is! RenderRepaintBoundary) {
        throw Exception('Impossible de capturer le QR Code.');
      }

      final image = await renderObject.toImage(pixelRatio: 3.0);

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Impossible de générer le PNG.');
      }

      final pngBytes = byteData.buffer.asUint8List();

      final directory = await getTemporaryDirectory();

      final imageFile = File(
        '${directory.path}/qr_code_'
        '${DateTime.now().millisecondsSinceEpoch}.png',
      );

      await imageFile.writeAsBytes(pngBytes, flush: true);

      final success = await GalleryService.saveImageToGallery(imageFile.path);

      if (!mounted) return;

      if (success) {
        AppNotification.showSuccess(context, 'QR Code enregistré');
      } else {
        AppNotification.showError(context, 'Erreur lors de l’enregistrement');
      }
    } catch (error) {
      if (!mounted) return;

      AppNotification.showError(context, 'Erreur: $error');
    }
  }

  // ============================================================
  // QR DIALOG
  // ============================================================

  Future<void> _showOrderCreatedDialog(String qrToken) {
    if (!mounted) {
      return Future.value();
    }

    final GlobalKey dialogQrKey = GlobalKey();

    final live = ref.read(liveByIdProvider(widget.liveId)).valueOrNull;

    final sellerName = live?.sellerName ?? 'Vendeur';

    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),

            padding: const EdgeInsets.all(20),

            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 44,
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Commande confirmée !',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Boutique : $sellerName',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: BazzarColors.primary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Présentez ce QR code au livreur.',
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  RepaintBoundary(
                    key: dialogQrKey,
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(16),

                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),

                          QrImageView(data: qrToken, size: 150),

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  OutlinedButton.icon(
                    onPressed: () => _downloadQrCode(dialogQrKey),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Télécharger'),
                  ),

                  const SizedBox(height: 8),

                  ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Fermer'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
}

// ============================================================================
// CART LINE
// ============================================================================

class _CartLine {
  final Product product;
  final int quantity;

  const _CartLine({required this.product, required this.quantity});
}

// ============================================================================
// CHECKOUT RESULT
// ============================================================================

class _CheckoutResult {
  final String? qrToken;

  const _CheckoutResult.success(this.qrToken);

  bool get isSuccess => qrToken != null;
}

// ============================================================================
// CHECKOUT SHEET
// ============================================================================

class _CheckoutSheet extends StatefulWidget {
  final String initialName;
  final String initialPhone;
  final String initialAddress;

  final Map<String, _CartLine> cart;

  final void Function(Product product, [VoidCallback? onUpdate]) onIncrease;

  final void Function(Product product, [VoidCallback? onUpdate]) onDecrease;

  final void Function(String productId, [VoidCallback? onUpdate]) onRemove;

  final Future<String> Function({
    required String clientName,
    required String clientPhone,
    required String deliveryAddress,
    required String deliveryRemark,
  })
  onSubmit;

  const _CheckoutSheet({
    required this.initialName,
    required this.initialPhone,
    required this.initialAddress,
    required this.cart,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
    required this.onSubmit,
  });

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  late final TextEditingController _nameController;

  late final TextEditingController _phoneController;

  late final TextEditingController _addressController;

  late final TextEditingController _remarkController;

  bool _isSubmitting = false;

  String? _sheetError;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.initialName);

    _phoneController = TextEditingController(text: widget.initialPhone);

    _addressController = TextEditingController(text: widget.initialAddress);

    _remarkController = TextEditingController();
  }

  @override
  void dispose() {
    // IMPORTANT :
    // Les controllers sont détruits uniquement
    // lorsque le widget du BottomSheet est réellement
    // détruit.
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _remarkController.dispose();

    super.dispose();
  }

  double get _total {
    return widget.cart.values.fold<double>(
      0,
      (sum, line) => sum + (line.product.price * line.quantity),
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final clientName = _nameController.text.trim();

    final clientPhone = _phoneController.text.trim();

    final deliveryAddress = _addressController.text.trim();

    final deliveryRemark = _remarkController.text.trim();

    if (clientName.isEmpty || clientPhone.isEmpty || deliveryAddress.isEmpty) {
      setState(() {
        _sheetError = 'Nom, contact et adresse sont obligatoires.';
      });
      return;
    }

    if (widget.cart.isEmpty) {
      setState(() {
        _sheetError = 'Votre panier est vide.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _sheetError = null;
    });

    try {
      final qrToken = await widget.onSubmit(
        clientName: clientName,
        clientPhone: clientPhone,
        deliveryAddress: deliveryAddress,
        deliveryRemark: deliveryRemark,
      );

      if (!mounted) return;

      Navigator.of(context).pop(_CheckoutResult.success(qrToken));
    } catch (error, stackTrace) {
      debugPrint('[ORDER_CREATE_ERROR] $error');

      debugPrint('[ORDER_CREATE_STACK] $stackTrace');

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _sheetError = 'Commande non validée.\n\n$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),

      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.99,
        ),

        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),

        child: SafeArea(
          top: false,

          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 18, 32, 32),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Validation de la commande',
                  style: TextStyle(
                    color: BazzarColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 12),

                // --------------------------------------------------
                // PRODUCTS
                // --------------------------------------------------
                ...widget.cart.values.map((line) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,

                    title: Text(
                      line.product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    subtitle: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            size: 20,
                          ),
                          onPressed: _isSubmitting
                              ? null
                              : () {
                                  widget.onDecrease(line.product);

                                  setState(() {});
                                },
                        ),

                        Text('${line.quantity}'),

                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          onPressed: _isSubmitting
                              ? null
                              : () {
                                  widget.onIncrease(line.product);

                                  setState(() {});
                                },
                        ),

                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Colors.redAccent,
                          ),
                          onPressed: _isSubmitting
                              ? null
                              : () {
                                  widget.onRemove(line.product.id);

                                  setState(() {});
                                },
                        ),
                      ],
                    ),

                    trailing: Text(
                      formatPrice(line.product.price * line.quantity),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }),

                const Divider(height: 26),

                // --------------------------------------------------
                // CLIENT
                // --------------------------------------------------
                _CheckoutTextField(
                  controller: _nameController,
                  label: 'Nom complet',
                  icon: Icons.person_outline_rounded,
                ),

                const SizedBox(height: 12),

                _CheckoutTextField(
                  controller: _phoneController,
                  label: 'Contact',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 12),

                _CheckoutTextField(
                  controller: _addressController,
                  label: 'Adresse',
                  icon: Icons.location_on_outlined,
                ),

                const SizedBox(height: 12),

                _CheckoutTextField(
                  controller: _remarkController,
                  label: 'Remarque / lieu exact de livraison',
                  icon: Icons.notes_rounded,
                  maxLines: 3,
                ),

                // --------------------------------------------------
                // ERROR
                // --------------------------------------------------
                if (_sheetError != null) ...[
                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),

                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFDA4AF)),
                    ),

                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.redAccent,
                          size: 18,
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: Text(
                            _sheetError!,
                            style: const TextStyle(
                              color: Color(0xFFBE123C),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // --------------------------------------------------
                // PAYMENT
                // --------------------------------------------------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),

                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),

                  child: const Row(
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        color: BazzarColors.primary,
                      ),

                      SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          'Paiement à la livraison',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // --------------------------------------------------
                // TOTAL
                // --------------------------------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    Text(
                      CurrencyFormatter.format(_total),
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // --------------------------------------------------
                // SUBMIT
                // --------------------------------------------------
                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,

                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_rounded),

                    label: Text(
                      _isSubmitting ? 'Validation...' : 'Valider la commande',
                    ),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
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

// ============================================================================
// CHECKOUT TEXT FIELD
// ============================================================================

class _CheckoutTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;

  const _CheckoutTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,

      decoration: InputDecoration(
        labelText: label,

        prefixIcon: Icon(icon, color: BazzarColors.primary),

        filled: true,

        fillColor: BazzarColors.background,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ============================================================================
// FACEBOOK LIVE
// ============================================================================

// ============================================================================
// PRODUCTS
// ============================================================================

class _SliverProductsSection extends ConsumerWidget {
  final String sellerId;
  final ValueNotifier<String> queryNotifier;
  final Function(Product) onAddToCart;

  const _SliverProductsSection({
    required this.sellerId,
    required this.queryNotifier,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(sellerProductsProvider(sellerId));

    return productsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      ),

      error: (error, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Erreur: $error'),
        ),
      ),

      data: (products) {
        return ValueListenableBuilder<String>(
          valueListenable: queryNotifier,

          builder: (context, query, child) {
            final filteredProducts = products.where((product) {
              if (query.isEmpty) {
                return true;
              }

              return product.name.toLowerCase().contains(query);
            }).toList();

            if (filteredProducts.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Aucun produit trouvé.',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 10),

              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final product = filteredProducts[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),

                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF7C3AED,
                            ).withValues(alpha: 0.10),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),

                      child: Padding(
                        padding: const EdgeInsets.all(14),

                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),

                              child: Container(
                                width: 85,
                                height: 85,
                                color: const Color(0xFFF3F4F6),

                                child:
                                    product.imageUrl != null &&
                                        product.imageUrl!.isNotEmpty
                                    ? Image.network(
                                        product.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) {
                                          return const Icon(
                                            Icons.shopping_bag_outlined,
                                            color: Color(0xFF9CA3AF),
                                          );
                                        },
                                      )
                                    : const Icon(
                                        Icons.shopping_bag_outlined,
                                        color: Color(0xFF9CA3AF),
                                      ),
                              ),
                            ),

                            const SizedBox(width: 16),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),

                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEDE9FE),
                                      borderRadius: BorderRadius.circular(8),
                                    ),

                                    child: Text(
                                      product.codeJp.toUpperCase(),
                                      style: const TextStyle(
                                        color: Color(0xFF7C3AED),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: Color(0xFF111827),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  const SizedBox(height: 6),

                                  Text(
                                    formatPrice(product.price),
                                    style: const TextStyle(
                                      color: Color(0xFF7C3AED),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),

                                  if (product.stock <= 0)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Rupture de stock',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            IconButton(
                              onPressed: product.stock <= 0
                                  ? null
                                  : () => onAddToCart(product),

                              style: IconButton.styleFrom(
                                backgroundColor: product.stock <= 0
                                    ? const Color(0xFFF3F4F6)
                                    : const Color(0xFF7C3AED),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),

                              icon: const Icon(Icons.add_shopping_cart_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }, childCount: filteredProducts.length),
              ),
            );
          },
        );
      },
    );
  }
}
