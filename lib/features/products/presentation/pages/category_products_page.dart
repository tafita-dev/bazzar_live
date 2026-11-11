import 'package:live_shopping/core/widgets/bazzar_ui.dart';
import 'package:live_shopping/core/theme/bazzar_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/product_provider.dart';
import 'add_product_page.dart';

class CategoryProductsPage extends ConsumerWidget {
  final String categoryId;
  final String categoryName;
  final String sellerId;

  const CategoryProductsPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.sellerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsByCategoryProvider(categoryId));

    return Scaffold(
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
        title: BazzarPageTitle(
          title: Text(categoryName),
          subtitle: 'Les articles de cette collection',
        ),
      ),
      body: productsAsync.when(
        data: (products) => products.isEmpty
            ? const SingleChildScrollView(
                child: BazzarEmptyState(
                  title: 'Une collection à remplir',
                  description:
                      'Ajoutez votre premier produit à cette catégorie.',
                  icon: Icons.shopping_bag_outlined,
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(8),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            width: 64,
                            height: 64,
                            child: product.imageUrl != null
                                ? Image.network(
                                    product.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const ColoredBox(
                                          color: BazzarColors.lavender,
                                          child: Icon(
                                            Icons.image_outlined,
                                            color: BazzarColors.primary,
                                          ),
                                        ),
                                  )
                                : const ColoredBox(
                                    color: BazzarColors.lavender,
                                    child: Icon(
                                      Icons.shopping_bag_outlined,
                                      color: BazzarColors.primary,
                                    ),
                                  ),
                          ),
                        ),
                        title: Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${product.price}€ - Stock: ${product.stock}',
                        ),
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddProductPage(
                sellerId: sellerId,
                initialCategoryId: categoryId,
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un produit'),
      ),
    );
  }
}
