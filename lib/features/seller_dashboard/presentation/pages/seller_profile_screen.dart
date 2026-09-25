import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:live_shopping/core/utils/image_capture_service.dart';
import 'package:live_shopping/core/utils/error_helper.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/profile_provider.dart';
import '../../../auth/presentation/widgets/logout_confirmation_dialog.dart';
import 'package:live_shopping/features/live/presentation/providers/live_provider.dart';
import 'package:live_shopping/core/widgets/app_notification.dart';

class SellerProfileScreen extends ConsumerStatefulWidget {
  final String sellerId;

  const SellerProfileScreen({super.key, required this.sellerId});

  @override
  ConsumerState<SellerProfileScreen> createState() =>
      _SellerProfileScreenState();
}

class _SellerProfileScreenState extends ConsumerState<SellerProfileScreen> {
  final _fullNameController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _shopDescriptionController = TextEditingController();

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploading = false;
  String? _avatarUrl;
  File? _localAvatarFile;

  @override
  void dispose() {
    _fullNameController.dispose();
    _shopNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _shopDescriptionController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SellerProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh form if profile data changes in the stream
    final profile = ref.read(profileProvider(widget.sellerId)).value;
    if (profile != null) {
      _fillForm(profile);
    }
  }

  void _fillForm(UserProfile? profile) {
    if (profile == null) return;
    
    // Only update fields if not currently editing to prevent overriding user input
    if (!_isEditing) {
      _resetForm(profile);
    }
  }

  void _resetForm(UserProfile? profile) {
    if (profile == null) return;
    _fullNameController.text = profile.fullName ?? '';
    _shopNameController.text = profile.shopName ?? '';
    _phoneController.text = profile.phone ?? '';
    _addressController.text = profile.address ?? '';
    _shopDescriptionController.text = profile.shopDescription ?? '';
    _avatarUrl = profile.avatarUrl;
    _localAvatarFile = null;
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    setState(() => _isUploading = true);

    final service = ImageCaptureService();
    final result = await service.pickAndUpload(context: context, source: source);

    if (result == null) {
      setState(() => _isUploading = false);
      return;
    }

    setState(() {
      _avatarUrl = result.url;
      _isUploading = false;
      _localAvatarFile = null; // Reset local file as we now have the URL
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .updateAvatar(userId: widget.sellerId, avatarUrl: result.url);
      _refreshProfileData();

      if (mounted) {
        AppNotification.showSuccess(context, 'Photo de profil mise à jour.');
      }
    } catch (e) {
      debugPrint('ERREUR lors de la mise à jour profil: $e');
      if (mounted) {
        AppNotification.showError(context, 'Erreur mise à jour profil: ${getFriendlyErrorMessage(e)}');
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSourceButton(
                icon: Icons.camera_alt_rounded,
                label: 'Appareil photo',
                onTap: () async {
                  Navigator.pop(context); // Fermer le BottomSheet
                  // Attendre un court instant pour que l'activité se stabilise
                  await Future.delayed(const Duration(milliseconds: 300));
                  _pickAndUploadAvatar(ImageSource.camera);
                },
              ),
              _buildSourceButton(
                icon: Icons.photo_library_rounded,
                label: 'Galerie',
                onTap: () async {
                  Navigator.pop(context); // Fermer le BottomSheet
                  // Attendre un court instant pour que l'activité se stabilise
                  await Future.delayed(const Duration(milliseconds: 300));
                  _pickAndUploadAvatar(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_isUploading) {
      AppNotification.showError(context, 'Veuillez attendre la fin de l\'envoi de la photo.');
      return;
    }

    await _saveProfileChanges(closeEditor: true);
  }

  Future<void> _saveProfileChanges({required bool closeEditor}) async {
    final isSeller = _isSellerRole(ref.read(profileProvider(widget.sellerId)).value?.role);

    setState(() => _isSaving = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .updateProfile(
            userId: widget.sellerId,
            fullName: _nullableText(_fullNameController),
            avatarUrl: _avatarUrl,
            phone: _nullableText(_phoneController),
            address: _nullableText(_addressController),
            shopName: isSeller ? _nullableText(_shopNameController) : null,
            shopDescription: isSeller
                ? _nullableText(_shopDescriptionController)
                : null,
          );
      _refreshProfileData();

      if (!mounted) return;
      if (closeEditor) {
        setState(() => _isEditing = false);
      }
      AppNotification.showSuccess(context, 'Profil mis a jour avec succes.');
    } catch (e) {
      if (!mounted) return;
      AppNotification.showError(context, 'Erreur: ${getFriendlyErrorMessage(e)}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _refreshProfileData() {
    ref.invalidate(profileProvider(widget.sellerId));
    ref.invalidate(activeLivesProvider);
  }

  String? _nullableText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider(widget.sellerId));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Mon Profil',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
        ),
        error: (err, _) => Center(child: Text('Erreur: $err')),
        data: (profile) {
          _fillForm(profile);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildSocialHeader(profile),
                const SizedBox(height: 18),
                _isEditing ? _buildFormCard() : _buildInfoCard(profile),
                const SizedBox(height: 24),
                if (_isEditing)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving || _isUploading
                          ? null
                          : _saveProfile,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        _isSaving
                            ? 'Enregistrement...'
                            : 'Enregistrer les informations',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await confirmSignOut(context, ref);
                    },
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Colors.redAccent,
                    ),
                    label: const Text(
                      'Se deconnecter',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFECEB),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSocialHeader(UserProfile? profile) {
    final displayName = _fullNameController.text.trim().isEmpty
        ? _defaultName(profile)
        : _fullNameController.text.trim();
    final roleLabel = _roleLabel(profile?.role);
    final shopName = _shopNameController.text.trim();
    final isSeller = _isSellerRole(profile?.role);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: 150,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF181630), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Positioned(bottom: -56, child: _buildAvatar(profile)),
            ],
          ),
          const SizedBox(height: 64),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: [
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile?.email ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildProfileChip(Icons.badge_outlined, roleLabel),
                    if (isSeller && shopName.isNotEmpty)
                      _buildProfileChip(Icons.storefront_rounded, shopName),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving || _isUploading
                        ? null
                        : () {
                            if (_isEditing) {
                              setState(() {
                                _resetForm(profile);
                                _isEditing = false;
                              });
                            } else {
                              setState(() => _isEditing = true);
                            }
                          },
                    icon: Icon(
                      _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                    ),
                    label: Text(_isEditing ? 'Annuler' : 'Modifier le profil'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isEditing
                          ? const Color(0xFFF3F4F6)
                          : const Color(0xFF7C3AED),
                      foregroundColor: _isEditing
                          ? const Color(0xFF111827)
                          : Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF7C3AED)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(UserProfile? profile) {
    final description = _shopDescriptionController.text.trim();
    final isSeller = _isSellerRole(profile?.role);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'A propos',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _buildInfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Nom',
            value: _valueOrEmpty(
              _fullNameController.text,
              _defaultName(profile),
            ),
          ),
          _buildInfoRow(
            icon: Icons.phone_outlined,
            label: 'Contact',
            value: _valueOrEmpty(_phoneController.text, 'Non renseigne'),
          ),
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            label: 'Adresse',
            value: _valueOrEmpty(_addressController.text, 'Non renseignee'),
          ),
          if (isSeller)
            _buildInfoRow(
              icon: Icons.storefront_rounded,
              label: 'Boutique',
              value: _valueOrEmpty(_shopNameController.text, 'Non renseignee'),
            ),
          if (isSeller && description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              description,
              style: const TextStyle(
                color: Color(0xFF374151),
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 21, color: const Color(0xFF6B7280)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 14,
                  height: 1.35,
                ),
                children: [
                  TextSpan(
                    text: '$label : ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _defaultName(UserProfile? profile) {
    switch (profile?.role) {
      case 'vendeur':
        return 'Vendeur Bazzar Live';
      case 'livreur':
        return 'Livreur Bazzar Live';
      case 'admin':
        return 'Administrateur';
      default:
        return 'Acheteur';
    }
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'vendeur':
        return 'Vendeur';
      case 'livreur':
        return 'Livreur';
      case 'admin':
        return 'Administrateur';
      default:
        return 'Client';
    }
  }

  bool _isSellerRole(String? role) => role == 'vendeur';

  String _valueOrEmpty(String value, String fallback) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  Widget _buildAvatar(UserProfile? profile) {
    final fallbackName =
        profile?.fullName ?? profile?.email ?? _defaultName(profile);

    return Semantics(
      button: true,
      label: 'Changer la photo de profil',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _isUploading ? null : _showImageSourceDialog,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFF7C3AED),
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: _localAvatarFile != null
                        ? Image.file(
                            _localAvatarFile!,
                            width: 112,
                            height: 112,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          )
                        : _avatarUrl != null
                        ? Image.network(
                            _avatarUrl!,
                            width: 112,
                            height: 112,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            errorBuilder: (_, __, ___) =>
                                _buildFallbackAvatar(fallbackName),
                          )
                        : _buildFallbackAvatar(fallbackName),
                  ),
                ),
                if (_isUploading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF7C3AED),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar(String seed) {
    return Image.network(
      'https://api.dicebear.com/7.x/adventurer/png?seed=$seed',
      width: 112,
      height: 112,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.person, size: 52, color: Colors.grey),
    );
  }

  Widget _buildFormCard() {
    final role = ref.read(profileProvider(widget.sellerId)).value?.role;
    final isSeller = _isSellerRole(role);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTextField(
            controller: _fullNameController,
            labelText: 'Nom complet',
            prefixIcon: Icons.person_outline_rounded,
          ),
          if (isSeller) ...[
            const SizedBox(height: 16),
            _buildTextField(
              controller: _shopNameController,
              labelText: 'Nom de la boutique',
              prefixIcon: Icons.storefront_rounded,
            ),
          ],
          const SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            labelText: 'Contact / telephone',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _addressController,
            labelText: 'Adresse',
            prefixIcon: Icons.location_on_outlined,
          ),
          if (isSeller) ...[
            const SizedBox(height: 16),
            _buildTextField(
              controller: _shopDescriptionController,
              labelText: 'Informations importantes',
              prefixIcon: Icons.info_outline_rounded,
              maxLines: 4,
            ),
          ],
        ],
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
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Color(0xFF111827), fontSize: 14),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF7C3AED), size: 20),
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF7C3AED), size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
