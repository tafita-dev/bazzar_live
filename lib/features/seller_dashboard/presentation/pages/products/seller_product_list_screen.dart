import 'package:live_shopping/core/widgets/bazzar_ui.dart';
import 'package:live_shopping/core/theme/bazzar_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:live_shopping/features/products/data/repositories/category_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:live_shopping/core/utils/currency_formatter.dart';
import 'package:live_shopping/features/products/presentation/pages/add_product_page.dart';
import 'package:live_shopping/features/products/presentation/providers/product_provider.dart';
import 'package:live_shopping/features/products/domain/entities/product.dart';
import 'package:live_shopping/features/products/presentation/providers/category_provider.dart';
import 'package:live_shopping/features/products/domain/entities/category.dart';
import 'package:live_shopping/features/products/data/repositories/product_repository_impl.dart';
import 'package:live_shopping/core/providers/supabase_provider.dart';
import 'package:live_shopping/features/seller_dashboard/presentation/widgets/seller_app_drawer.dart';
import 'package:live_shopping/core/widgets/app_notification.dart';

class SellerProductListScreen extends ConsumerStatefulWidget {
  final String sellerId;
  const SellerProductListScreen({super.key, required this.sellerId});

  @override
  ConsumerState<SellerProductListScreen> createState() =>
      _SellerProductListScreenState();
}

class _SellerProductListScreenState
    extends ConsumerState<SellerProductListScreen> {
  String _selectedTab = 'Tous'; // 'Tous', 'En ligne', 'Hors ligne'
  String? _selectedCategoryId; // null means 'Tous'

  void _showAddCategoryDialog(BuildContext context) {
    final controller = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Créer une catégorie',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: BazzarColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Entrez le nom de la nouvelle catégorie pour vos produits.',
                  style: TextStyle(color: BazzarColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: const TextStyle(color: BazzarColors.ink),
                  decoration: InputDecoration(
                    labelText: 'Nom de la catégorie',
                    labelStyle: const TextStyle(color: BazzarColors.muted),
                    hintText: 'Ex: Électronique, Vêtements...',
                    hintStyle: const TextStyle(color: BazzarColors.muted),
                    filled: true,
                    fillColor: BazzarColors.soft,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: BazzarColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSaving
                            ? null
                            : () {
                                if (Navigator.canPop(sheetContext))
                                  Navigator.pop(sheetContext);
                              },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: const BorderSide(color: BazzarColors.border),
                        ),
                        child: const Text(
                          'Annuler',
                          style: TextStyle(color: BazzarColors.muted),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                final name = controller.text.trim();
                                if (name.isEmpty) return;

                                setModalState(() => isSaving = true);
                                try {
                                  await CategoryRepositoryImpl(
                                    ref.read(supabaseClientProvider),
                                  ).createCategory(name, widget.sellerId);
                                  ref.invalidate(
                                    categoriesProvider(widget.sellerId),
                                  );
                                  if (sheetContext.mounted) {
                                    Navigator.pop(sheetContext);
                                  }
                                  if (context.mounted) {
                                    AppNotification.showSuccess(
                                      context,
                                      'Catégorie "$name" créée !',
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    AppNotification.showError(
                                      context,
                                      'Erreur: $e',
                                    );
                                  }
                                } finally {
                                  if (sheetContext.mounted) {
                                    setModalState(() => isSaving = false);
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BazzarColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Créer',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
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

  void _showCategoryOptionsBottomSheet(
    BuildContext context,
    Category category,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: BazzarColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.category_rounded,
                    color: BazzarColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: BazzarColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Options de catégorie',
                        style: TextStyle(
                          color: BazzarColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: BazzarColors.body,
              ),
              title: const Text(
                'Modifier le nom',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onTap: () {
                if (Navigator.canPop(sheetContext)) Navigator.pop(sheetContext);
                _showEditCategoryDialog(context, category);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Supprimer la catégorie',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                if (Navigator.canPop(sheetContext)) Navigator.pop(sheetContext);
                _showDeleteCategoryConfirmDialog(context, category);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, Category category) {
    final controller = TextEditingController(text: category.name);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Modifier la catégorie',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: BazzarColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Entrez le nouveau nom pour cette catégorie.',
                  style: TextStyle(color: BazzarColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: const TextStyle(color: BazzarColors.ink),
                  decoration: InputDecoration(
                    labelText: 'Nom de la catégorie',
                    labelStyle: const TextStyle(color: BazzarColors.muted),
                    filled: true,
                    fillColor: BazzarColors.soft,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: BazzarColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSaving
                            ? null
                            : () {
                                if (Navigator.canPop(sheetContext))
                                  Navigator.pop(sheetContext);
                              },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: const BorderSide(color: BazzarColors.border),
                        ),
                        child: const Text(
                          'Annuler',
                          style: TextStyle(color: BazzarColors.muted),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                final newName = controller.text.trim();
                                if (newName.isEmpty) return;

                                setModalState(() => isSaving = true);
                                try {
                                  await CategoryRepositoryImpl(
                                    ref.read(supabaseClientProvider),
                                  ).updateCategory(category.id, newName);
                                  ref.invalidate(
                                    categoriesProvider(widget.sellerId),
                                  );
                                  if (sheetContext.mounted &&
                                      Navigator.canPop(sheetContext)) {
                                    Navigator.pop(sheetContext);
                                  }
                                  if (context.mounted) {
                                    AppNotification.showSuccess(
                                      context,
                                      'Catégorie modifiée en "$newName" !',
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    AppNotification.showError(
                                      context,
                                      'Erreur: $e',
                                    );
                                  }
                                } finally {
                                  setModalState(() => isSaving = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BazzarColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Enregistrer',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
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

  void _showDeleteCategoryConfirmDialog(
    BuildContext context,
    Category category,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              'Supprimer la catégorie ?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Voulez-vous vraiment supprimer la catégorie "${category.name}" ? Tous les produits associés à cette catégorie seront également supprimés.',
          style: const TextStyle(color: BazzarColors.muted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Annuler',
              style: TextStyle(color: BazzarColors.muted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              try {
                await CategoryRepositoryImpl(
                  ref.read(supabaseClientProvider),
                ).deleteCategory(category.id);
                if (_selectedCategoryId == category.id) {
                  setState(() => _selectedCategoryId = null);
                }
                ref.invalidate(categoriesProvider(widget.sellerId));
                ref.invalidate(sellerProductsProvider(widget.sellerId));
                if (dialogContext.mounted && Navigator.canPop(dialogContext)) {
                  Navigator.pop(dialogContext);
                }
                if (context.mounted) {
                  AppNotification.showInfo(
                    context,
                    'Catégorie "${category.name}" supprimée !',
                  );
                }
              } catch (e) {
                if (dialogContext.mounted && Navigator.canPop(dialogContext)) {
                  Navigator.pop(dialogContext);
                }
                if (context.mounted) {
                  AppNotification.showError(context, 'Erreur: $e');
                }
              }
            },
            child: const Text(
              'Supprimer',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(sellerProductsProvider(widget.sellerId));
    final categoriesAsync = ref.watch(categoriesProvider(widget.sellerId));
    final sellerId =
        Supabase.instance.client.auth.currentUser?.id ?? widget.sellerId;

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

        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: BazzarColors.ink),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const BazzarPageTitle(
          title: Text(
            'Mes produits',
            style: TextStyle(
              color: BazzarColors.ink,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          subtitle: 'Votre catalogue, en un regard',
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: const NetworkImage(
                'https://api.dicebear.com/7.x/adventurer/png?seed=Ahmed',
              ),
              backgroundColor: BazzarColors.ink.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
      drawer: SellerAppDrawer(sellerId: sellerId),
      body: productsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: BazzarColors.primary),
        ),
        error: (err, _) => Center(child: Text('Erreur: $err')),
        data: (products) {
          final totalCount = products.length;
          final onlineCount = products.where((p) => p.stock > 0).length;
          final offlineCount = products.where((p) => p.stock <= 0).length;

          List<Product> filteredProducts = products;
          if (_selectedCategoryId != null) {
            filteredProducts = products
                .where((p) => p.categoryId == _selectedCategoryId)
                .toList();
          }

          if (_selectedTab == 'En ligne') {
            filteredProducts = filteredProducts
                .where((p) => p.stock > 0)
                .toList();
          } else if (_selectedTab == 'Hors ligne') {
            filteredProducts = filteredProducts
                .where((p) => p.stock <= 0)
                .toList();
          }

          return BazzarCollectionLayout(
            crossAxisAlignment: CrossAxisAlignment.start,
            header: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF30205C), BazzarColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: BazzarColors.primary.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatBox(
                        'Total',
                        totalCount.toString(),
                        Colors.white,
                      ),
                      _buildVerticalDivider(),
                      _buildStatBox(
                        'En ligne',
                        onlineCount.toString(),
                        Colors.white,
                      ),
                      _buildVerticalDivider(),
                      _buildStatBox(
                        'Hors ligne',
                        offlineCount.toString(),
                        Colors.white,
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Horizontal tabs filter (Tous, En ligne, Hors ligne)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTabItem('Tous', totalCount),
                    _buildTabItem('En ligne', onlineCount),
                    _buildTabItem('Hors ligne', offlineCount),
                  ],
                ),
              ),

              // 3. Category selector strip
              const Padding(
                padding: EdgeInsets.only(left: 16.0, top: 12.0, bottom: 8.0),
                child: Text(
                  'Catégories',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: BazzarColors.ink,
                  ),
                ),
              ),
              categoriesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    height: 40,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Erreur: $err',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                data: (categories) => SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // "Tous" chip
                      _buildCategoryChip(
                        label: 'Tous',
                        isSelected: _selectedCategoryId == null,
                        onTap: () => setState(() => _selectedCategoryId = null),
                      ),
                      const SizedBox(width: 8),

                      // Real categories list with options on tap/long press
                      ...categories.map((cat) {
                        final isSelected = _selectedCategoryId == cat.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: _buildCategoryChip(
                            label: cat.name,
                            isSelected: isSelected,
                            onTap: () {
                              if (isSelected) {
                                _showCategoryOptionsBottomSheet(context, cat);
                              } else {
                                setState(() => _selectedCategoryId = cat.id);
                              }
                            },
                            onLongPress: () =>
                                _showCategoryOptionsBottomSheet(context, cat),
                          ),
                        );
                      }),

                      // "+" chip to add category
                      GestureDetector(
                        onTap: () => _showAddCategoryDialog(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: BazzarColors.primary,
                              width: 1.5,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                color: BazzarColors.primary,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Catégorie',
                                style: TextStyle(
                                  color: BazzarColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 4. Add product button full-width purple
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BazzarColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddProductPage(
                            sellerId: widget.sellerId,
                            initialCategoryId: _selectedCategoryId,
                          ),
                        ),
                      );
                      ref.invalidate(sellerProductsProvider(widget.sellerId));
                    },
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text(
                      'Ajouter un produit',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            body: filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Aucun produit disponible',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final isOnline = product.stock > 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
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
                          children: [
                            // Leading image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: 65,
                                height: 65,
                                color: BazzarColors.soft,
                                child:
                                    product.imageUrl != null &&
                                        product.imageUrl!.isNotEmpty
                                    ? Image.network(
                                        product.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                  Icons.shopping_bag_outlined,
                                                  color: Colors.grey,
                                                ),
                                      )
                                    : const Icon(
                                        Icons.shopping_bag_outlined,
                                        color: Colors.grey,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Middle details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: BazzarColors.ink,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    CurrencyFormatter.format(
                                      product.price.toDouble(),
                                    ),
                                    style: const TextStyle(
                                      color: BazzarColors.ink,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Stock: ${product.stock}',
                                    style: const TextStyle(
                                      color: BazzarColors.muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Trailing status and options
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isOnline
                                        ? const Color(0xFFD1FAE5)
                                        : const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isOnline ? 'En ligne' : 'Hors ligne',
                                    style: TextStyle(
                                      color: isOnline
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                IconButton(
                                  icon: const Icon(
                                    Icons.more_vert_rounded,
                                    color: BazzarColors.muted,
                                  ),
                                  onPressed: () {
                                    _showProductOptionsBottomSheet(
                                      context,
                                      product,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  Widget _buildStatBox(String title, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: color.withValues(alpha: 0.8),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 40, width: 1, color: BazzarColors.border);
  }

  Widget _buildTabItem(String label, int count) {
    final isSelected = _selectedTab == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? BazzarColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? BazzarColors.primary : BazzarColors.muted,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    const activeColor = BazzarColors.primary;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
          border: isSelected ? null : Border.all(color: BazzarColors.border),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : BazzarColors.muted,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              if (onLongPress != null && isSelected) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.more_vert_rounded,
                  size: 14,
                  color: isSelected ? Colors.white70 : BazzarColors.muted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showProductOptionsBottomSheet(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: BazzarColors.primary,
              ),
              title: const Text(
                'Modifier le produit',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                if (Navigator.canPop(sheetContext)) Navigator.pop(sheetContext);
                // Naviguer vers la page d'ajout/modification (AddProductPage)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddProductPage(
                      sellerId: widget.sellerId,
                      productToEdit:
                          product, // Assurez-vous qu'AddProductPage gère cela
                    ),
                  ),
                ).then(
                  (_) =>
                      ref.invalidate(sellerProductsProvider(widget.sellerId)),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Supprimer le produit',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                if (Navigator.canPop(sheetContext)) Navigator.pop(sheetContext);
                _showDeleteProductConfirmDialog(context, product);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteProductConfirmDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer le produit ?'),
        content: Text(
          'Voulez-vous vraiment supprimer "${product.name}" ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                await ProductRepositoryImpl(
                  ref.read(supabaseClientProvider),
                ).deleteProduct(product.id);
                ref.invalidate(sellerProductsProvider(widget.sellerId));
                if (context.mounted) Navigator.pop(dialogContext);
                if (context.mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Produit supprimé !'),
                      backgroundColor: Colors.green,
                    ),
                  );
              } catch (e) {
                if (context.mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
