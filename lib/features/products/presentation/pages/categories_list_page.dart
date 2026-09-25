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
      appBar: AppBar(title: const Text('Catégories')),
      body: categoriesAsync.when(
        data: (categories) => ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return ListTile(
              title: Text(category.name),
              trailing: const Icon(Icons.arrow_forward_ios),
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
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
        
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddCategoryPage(sellerId: sellerId)),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
