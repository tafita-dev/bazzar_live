import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../features/seller_dashboard/presentation/widgets/seller_app_drawer.dart';
import '../../../products/presentation/providers/product_provider.dart';
import 'package:live_shopping/features/live/presentation/providers/live_provider.dart';
import 'package:live_shopping/core/utils/currency_helper.dart';
import 'package:live_shopping/core/theme/app_theme.dart';

class LiveShoppingScreen extends ConsumerStatefulWidget {
  const LiveShoppingScreen({super.key});

  @override
  ConsumerState<LiveShoppingScreen> createState() => _LiveShoppingScreenState();
}

class _LiveShoppingScreenState extends ConsumerState<LiveShoppingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _facebookUrlController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _facebookUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sellerId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final activeLivesAsync = ref.watch(activeLivesProvider);
    final productsAsync = ref.watch(sellerProductsProvider(sellerId));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.sunsetAuroraGradient,
          ),
        ),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Live Shopping',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      drawer: SellerAppDrawer(sellerId: sellerId),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  activeLivesAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (error, _) => _InfoBox(
                      icon: Icons.error_outline,
                      text: 'Impossible de charger les lives: $error',
                    ),
                    data: (lives) {
                      LiveFeed? sellerLive;
                      for (final live in lives) {
                        if (live.sellerId == sellerId) {
                          sellerLive = live;
                          break;
                        }
                      }

                      if (sellerLive == null) {
                        return const _InfoBox(
                          icon: Icons.live_tv_rounded,
                          text: 'Aucun live actif. Collez le lien Facebook public puis demarrez.',
                        );
                      }

                      final LiveFeed activeLive = sellerLive;
                      return _ActiveLiveCard(
                        title: activeLive.title,
                        description: activeLive.description,
                        onStop: _isSaving ? null : () => _stopLive(activeLive.id),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildStartLiveForm(sellerId),
                  const SizedBox(height: 24),
                  const Text(
                    'Produits visibles pendant le live',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          productsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
            error: (error, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Erreur produits: $error'),
              ),
            ),
            data: (products) {
              if (products.isEmpty) {
                return const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: _InfoBox(
                      icon: Icons.inventory_2_outlined,
                      text: 'Ajoutez des produits pour les afficher aux clients pendant le live.',
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = products[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: product.imageUrl == null
                                  ? Container(
                                      width: 58,
                                      height: 58,
                                      color: const Color(0xFFECEBFF),
                                      child: const Icon(Icons.shopping_bag_outlined),
                                    )
                                  : Image.network(
                                      product.imageUrl!,
                                      width: 58,
                                      height: 58,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF111827),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Stock: ${product.stock}',
                                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              formatPrice(product.price),
                              style: const TextStyle(
                                color: Color(0xFF7C3AED),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: products.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildStartLiveForm(String sellerId) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Demarrer un live Facebook',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre du live',
                prefixIcon: Icon(Icons.title_rounded),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Entrez un titre.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _facebookUrlController,
              decoration: const InputDecoration(
                labelText: 'Lien Facebook public',
                hintText: 'https://www.facebook.com/.../videos/...',
                prefixIcon: Icon(Icons.link_rounded),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final url = Uri.tryParse(value?.trim() ?? '');
                if (url == null || !url.hasScheme || !url.host.contains('facebook.com')) {
                  return 'Collez un lien Facebook public valide.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.notes_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : () => _startLive(sellerId),
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_circle_fill_rounded),
                label: const Text('Demarrer le live'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startLive(String sellerId) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final client = Supabase.instance.client;
      
      final profile = await client
          .from('profiles')
          .select('shop_name')
          .eq('id', sellerId)
          .single();
      final shopName = profile['shop_name'] as String?;

      await client.from('lives').update({'is_active': false}).eq('seller_id', sellerId);
      await client.from('lives').insert({
        'title': _titleController.text.trim(),
        'facebook_url': _facebookUrlController.text.trim(),
        'description': _descriptionController.text.trim(),
        'seller_id': sellerId,
        'shop_name': shopName,
        'is_active': true,
        'started_at': DateTime.now().toUtc().toIso8601String(),
      });

      _titleController.clear();
      _descriptionController.clear();
      _facebookUrlController.clear();
      ref.invalidate(activeLivesProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Live demarre. Les clients peuvent le voir.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de demarrer le live: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _stopLive(String liveId) async {
    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client
          .from('lives')
          .update({'is_active': false}).eq('id', liveId);
      ref.invalidate(activeLivesProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Live arrete.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d arreter le live: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _ActiveLiveCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onStop;

  const _ActiveLiveCard({
    required this.title,
    required this.description,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFDF5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: [
          const Icon(Icons.radio_button_checked_rounded, color: Color(0xFF16A34A)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF14532D),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (description.isNotEmpty)
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF166534), fontSize: 12),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: onStop,
            child: const Text('Arreter'),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoBox({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF7C3AED)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }
}
