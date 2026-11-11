import 'package:live_shopping/core/widgets/bazzar_ui.dart';
import 'package:live_shopping/core/theme/bazzar_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/category_provider.dart';
import 'add_category_page.dart';
import 'category_products_page.dart';

class CategoriesListPage extends ConsumerWidget {
  final String sellerId;
  const CategoriesListPage({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider(sellerId));

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
        title: const BazzarPageTitle(
          title: Text('Catégories'),
          subtitle: 'Une boutique bien organisée',
        ),
      ),
      body: categoriesAsync.when(
        data: (categories) => categories.isEmpty
            ? const SingleChildScrollView(
                child: BazzarEmptyState(
                  title: 'Votre catalogue commence ici',
                  description:
                      'Ajoutez une catégorie pour regrouper vos produits et faciliter leur découverte.',
                  icon: Icons.category_outlined,
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: BazzarColors.lavender,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.category_outlined,
                          color: BazzarColors.primary,
                        ),
                      ),
                      title: Text(
                        category.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text('Explorer les produits'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryProductsPage(
                            categoryId: category.id,
                            categoryName: category.name,
                            sellerId: sellerId,
                          ),
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
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddCategoryPage(sellerId: sellerId),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Créer une catégorie'),
      ),
    );
  }
}
