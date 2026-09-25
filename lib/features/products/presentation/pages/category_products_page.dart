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
      appBar: AppBar(title: Text(categoryName)),
      body: productsAsync.when(
        data: (products) => ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ListTile(
              leading: product.imageUrl != null 
                ? Image.network(product.imageUrl!, width: 50, height: 50, fit: BoxFit.cover)
                : const Icon(Icons.shopping_bag),
              title: Text(product.name),
              subtitle: Text('${product.price}€ - Stock: ${product.stock}'),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
      ),
      floatingActionButton: FloatingActionButton(
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
        child: const Icon(Icons.add),
      ),
    );
  }
}
