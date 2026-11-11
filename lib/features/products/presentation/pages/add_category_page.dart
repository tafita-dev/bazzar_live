import 'package:live_shopping/core/widgets/bazzar_ui.dart';
import 'package:live_shopping/core/theme/bazzar_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:live_shopping/core/providers/supabase_provider.dart';
import 'package:live_shopping/features/products/presentation/providers/category_provider.dart';
import '../../data/repositories/category_repository_impl.dart';

class AddCategoryPage extends ConsumerStatefulWidget {
  final String sellerId;
  const AddCategoryPage({super.key, required this.sellerId});

  @override
  ConsumerState<AddCategoryPage> createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends ConsumerState<AddCategoryPage> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _addCategory() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un nom de catégorie.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await CategoryRepositoryImpl(
        ref.read(supabaseClientProvider),
      ).createCategory(_nameController.text.trim(), widget.sellerId);
      // Invalidate provider to force a refresh of the list
      ref.invalidate(categoriesProvider(widget.sellerId));

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Catégorie "${_nameController.text.trim()}" ajoutée !',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: BazzarColors.ink,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: const BazzarPageTitle(
          title: Text(
            'Nouvelle catégorie',
            style: TextStyle(
              color: BazzarColors.ink,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          subtitle: 'Organisez votre catalogue',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const BazzarIntro(
                title: 'Chaque envie, sa collection.',
                description:
                    'Donnez un nom simple à votre catégorie pour faciliter la découverte de vos produits.',
                icon: Icons.category_outlined,
              ),

              // Input card light
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: BazzarColors.border, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nom de la catégorie',
                      style: TextStyle(
                        color: BazzarColors.body,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(
                        color: BazzarColors.ink,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ex: Électronique, Vêtements...',
                        hintStyle: const TextStyle(
                          color: BazzarColors.muted,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.category_outlined,
                          color: BazzarColors.primary,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: BazzarColors.soft,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
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
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BazzarColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: BazzarColors.primary.withValues(
                            alpha: 0.3,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isLoading ? null : _addCategory,
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Créer la catégorie',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
