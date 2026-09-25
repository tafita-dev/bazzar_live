import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:live_shopping/core/utils/image_capture_service.dart';
import 'package:live_shopping/core/utils/error_helper.dart';
import 'package:live_shopping/features/products/presentation/providers/product_provider.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/product.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../providers/category_provider.dart';
import 'package:live_shopping/core/providers/supabase_provider.dart';
import 'package:live_shopping/core/widgets/app_notification.dart';
import 'package:live_shopping/core/theme/app_theme.dart';

class AddProductPage extends ConsumerStatefulWidget {
  final String sellerId;
  final String? initialCategoryId;
  final Product? productToEdit; // Ajout pour édition
  const AddProductPage({super.key, required this.sellerId, this.initialCategoryId, this.productToEdit});

  @override
  ConsumerState<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends ConsumerState<AddProductPage> {
  final _nameController = TextEditingController();
  final _codeJpController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  
  String? _imageUrl;
  File? _localImageFile; // For preview
  bool _isUploading = false;
  
  String? _selectedCategoryId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialiser avec les données du produit si on est en mode édition
    if (widget.productToEdit != null) {
      final p = widget.productToEdit!;
      _nameController.text = p.name;
      _codeJpController.text = p.codeJp;
      _descriptionController.text = p.description ?? '';
      _priceController.text = p.price.toString();
      _stockController.text = p.stock.toString();
      _imageUrl = p.imageUrl;
      _selectedCategoryId = p.categoryId;
    } else {
      _selectedCategoryId = widget.initialCategoryId;
    }
  }

  // ... (méthodes existantes _pickAndUpload, _showImageSourceDialog, _buildSourceButton restent inchangées)

  Future<void> _saveProduct() async {
    if (widget.productToEdit != null) {
      await _updateProduct();
    } else {
      await _addProduct();
    }
  }

  Future<void> _updateProduct() async {
    final name = _nameController.text.trim();
    final priceStr = _priceController.text.trim();
    final stockStr = _stockController.text.trim();

    if (name.isEmpty || priceStr.isEmpty || stockStr.isEmpty || _selectedCategoryId == null) {
      AppNotification.showError(context, 'Veuillez remplir les champs obligatoires');
      return;
    }

    setState(() => _isLoading = true);

    final updatedProduct = widget.productToEdit!.copyWith(
      name: name,
      codeJp: _codeJpController.text.trim().isEmpty ? widget.productToEdit!.codeJp : _codeJpController.text.trim(),
      description: _descriptionController.text.trim(),
      price: double.parse(priceStr),
      stock: int.parse(stockStr),
      categoryId: _selectedCategoryId,
      imageUrl: _imageUrl,
    );

    try {
      await ProductRepositoryImpl(ref.read(supabaseClientProvider)).updateProduct(updatedProduct);
      
      ref.invalidate(sellerProductsProvider(widget.sellerId));
      
      if (mounted) {
        context.pop();
        AppNotification.showSuccess(context, 'Produit mis à jour !');
      }
    } catch (e) {
      if (mounted) AppNotification.showError(context, 'Erreur: ${getFriendlyErrorMessage(e)}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

 

  // ... (méthode build à mettre à jour pour utiliser _saveProduct au lieu de _addProduct)
  Future<void> _pickAndUpload(ImageSource source) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final service = ImageCaptureService();
      final result = await service.pickAndUpload(context: context, source: source);

      if (result == null) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      setState(() {
        _localImageFile = File(result.localPath);
        _imageUrl = result.url;
        _isUploading = false;
      });
    } catch (e) {
      debugPrint('ERREUR lors de l\'upload: $e');
      setState(() => _isUploading = false);
      if (mounted) {
        AppNotification.showError(context, 'Erreur d\'upload: ${getFriendlyErrorMessage(e)}');
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ajouter une photo',
              style: TextStyle(color: Color(0xFF111827), fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Appareil photo',
                  onTap: () {
                    context.pop();
                    _pickAndUpload(ImageSource.camera);
                  },
                ),
                _buildSourceButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Galerie',
                  onTap: () {
                    context.pop();
                    _pickAndUpload(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF7C3AED), size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Color(0xFF4B5563), fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _addProduct() async {
    final name = _nameController.text.trim();
    final priceStr = _priceController.text.trim();
    final stockStr = _stockController.text.trim();

    if (name.isEmpty) {
      if (mounted) {
        AppNotification.showError(context, 'Veuillez entrer le nom du produit.');
      }
      return;
    }
    if (priceStr.isEmpty || double.tryParse(priceStr) == null) {
      if (mounted) {
        AppNotification.showError(context, 'Veuillez entrer un prix valide.');
      }
      return;
    }
    if (stockStr.isEmpty || int.tryParse(stockStr) == null) {
      if (mounted) {
        AppNotification.showError(context, 'Veuillez entrer un stock valide.');
      }
      return;
    }
    if (_selectedCategoryId == null) {
      if (mounted) {
        AppNotification.showError(context, 'Veuillez sélectionner une catégorie.');
      }
      return;
    }

    setState(() => _isLoading = true);
    
    final product = Product(
      id: const Uuid().v4(),
      codeJp: _codeJpController.text.trim().isEmpty ? 'JP-${const Uuid().v4().substring(0, 4).toUpperCase()}' : _codeJpController.text.trim(),
      name: name,
      description: _descriptionController.text.trim(),
      price: double.parse(priceStr),
      stock: int.parse(stockStr),
      sellerId: widget.sellerId,
      categoryId: _selectedCategoryId,
      imageUrl: _imageUrl,
    );
    debugPrint('Produit à ajouter: $product');

    try {
      await ProductRepositoryImpl(ref.read(supabaseClientProvider)).createProduct(product);
      
      ref.invalidate(productsByCategoryProvider(_selectedCategoryId!));
      ref.invalidate(sellerProductsProvider(widget.sellerId));
      
      if (mounted) {
        context.pop();
        AppNotification.showSuccess(context, 'Produit ajouté avec succès !');
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout du produit: $e');
      if (mounted) {
        AppNotification.showError(context, 'Erreur: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider(widget.sellerId));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.sunsetAuroraGradient,
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Ajouter un produit',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              // Image picker area - Refined with rounded corners and gradient
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: _localImageFile != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(_localImageFile!, fit: BoxFit.cover),
                              if (_isUploading)
                                Container(
                                  color: Colors.black38,
                                  child: const Center(
                                    child: CircularProgressIndicator(color: Colors.white),
                                  ),
                                )
                              else
                                Positioned(
                                  right: 16,
                                  bottom: 16,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF7C3AED),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.edit, color: Colors.white, size: 20),
                                  ),
                                )
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEDE9FE),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add_a_photo_rounded, size: 32, color: Color(0xFF7C3AED)),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Ajouter une photo',
                                style: TextStyle(color: Color(0xFF111827), fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Input card - Refined spacing and shadow
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      labelText: 'Nom du produit *',
                      prefixIcon: Icons.shopping_bag_outlined,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _codeJpController,
                      labelText: 'Code Produit (ex: JP-1001)',
                      prefixIcon: Icons.qr_code_rounded,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _descriptionController,
                      labelText: 'Description',
                      prefixIcon: Icons.description_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _priceController,
                            labelText: 'Prix (Ariary) *',
                            prefixIcon: Icons.payments_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _stockController,
                            labelText: 'Stock initial *',
                            prefixIcon: Icons.inventory_2_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Categories dropdown loader
                    categoriesAsync.when(
                      loading: () => const SizedBox(
                        height: 56,
                        child: Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED))),
                      ),
                      error: (err, _) => Text(
                        'Erreur: $err',
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                      data: (categories) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButtonFormField<String>(
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: Color(0xFF111827), fontSize: 14),
                            decoration: const InputDecoration(
                              labelText: 'Catégorie *',
                              labelStyle: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                              prefixIcon: Icon(Icons.category_outlined, color: Color(0xFF7C3AED), size: 20),
                              border: InputBorder.none,
                              filled: false,
                            ),
                            initialValue: _selectedCategoryId,
                            items: categories.map((cat) {
                              return DropdownMenuItem<String>(
                                value: cat.id,
                                child: Text(cat.name),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedCategoryId = val),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _isLoading || _isUploading ? null : _saveProduct,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          widget.productToEdit != null ? 'Modifier le produit' : 'Enregistrer le produit',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(
            color: Color(0xFF374151),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Color(0xFF111827), fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(prefixIcon, color: const Color(0xFF7C3AED), size: 20),
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
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
              borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
