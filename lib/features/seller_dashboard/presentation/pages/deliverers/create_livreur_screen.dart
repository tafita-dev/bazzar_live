import 'package:live_shopping/core/widgets/bazzar_ui.dart';
import 'package:live_shopping/core/theme/bazzar_colors.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:live_shopping/core/utils/image_capture_service.dart';
import 'package:live_shopping/core/utils/error_helper.dart';
import 'package:live_shopping/features/delivery/presentation/providers/deliverer_provider.dart';
import 'package:live_shopping/core/widgets/app_notification.dart';

class CreateLivreurScreen extends ConsumerStatefulWidget {
  const CreateLivreurScreen({super.key});

  @override
  ConsumerState<CreateLivreurScreen> createState() =>
      _CreateLivreurScreenState();
}

class _CreateLivreurScreenState extends ConsumerState<CreateLivreurScreen> {
  static const Color primary = BazzarColors.primary;
  static const Color background = BazzarColors.background;
  static const Color dark = BazzarColors.ink;
  static const Color muted = BazzarColors.muted;
  static const Color border = BazzarColors.border;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _avatarUrl;
  File? _localAvatarFile;

  bool _isUploading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // IMAGE
  // ---------------------------------------------------------------------------

  Future<void> _pickAndUpload(ImageSource source) async {
    if (_isUploading) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final service = ImageCaptureService();

      final result = await service.pickAndUpload(
        context: context,
        source: source,
      );

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      setState(() {
        _localAvatarFile = File(result.localPath);
        _avatarUrl = result.url;
        _isUploading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploading = false;
      });

      AppNotification.showError(context, getFriendlyErrorMessage(e));
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Photo du livreur',
                style: TextStyle(
                  color: dark,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Choisissez une photo pour le profil',
                style: TextStyle(color: muted, fontSize: 13),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _buildSourceButton(
                      icon: Icons.camera_alt_rounded,
                      title: 'Appareil photo',
                      subtitle: 'Prendre une photo',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _pickAndUpload(ImageSource.camera);
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _buildSourceButton(
                      icon: Icons.photo_library_rounded,
                      title: 'Galerie',
                      subtitle: 'Choisir une photo',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _pickAndUpload(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourceButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: BoxDecoration(
          color: BazzarColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: BazzarColors.lavender,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: primary, size: 24),
            ),

            const SizedBox(height: 10),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: dark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: muted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // VALIDATION
  // ---------------------------------------------------------------------------

  bool _validateForm() {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phone = _phoneController.text.trim();

    if (fullName.isEmpty) {
      _showError('Veuillez saisir le nom complet.');
      return false;
    }

    if (email.isEmpty) {
      _showError('Veuillez saisir l’adresse email.');
      return false;
    }

    if (!email.contains('@')) {
      _showError('Veuillez saisir une adresse email valide.');
      return false;
    }

    if (password.isEmpty) {
      _showError('Veuillez saisir un mot de passe.');
      return false;
    }

    if (password.length < 6) {
      _showError('Le mot de passe doit contenir au moins 6 caractères.');
      return false;
    }

    if (phone.isEmpty) {
      _showError('Veuillez saisir le numéro de téléphone.');
      return false;
    }

    return true;
  }

  void _showError(String message) {
    if (!mounted) return;

    AppNotification.showError(context, message);
  }

  // ---------------------------------------------------------------------------
  // CREATE
  // ---------------------------------------------------------------------------

  Future<void> _createLivreur() async {
    if (_isUploading) return;

    if (!_validateForm()) return;

    final notifier = ref.read(delivererNotifierProvider.notifier);

    try {
      await notifier.createLivreur(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        avatarUrl: _avatarUrl,
      );

      if (!mounted) return;

      /*
       * IMPORTANT :
       * On retourne true à la liste.
       * La liste pourra alors invalider son provider
       * et afficher immédiatement le nouveau livreur.
       */
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      AppNotification.showError(context, getFriendlyErrorMessage(e));
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(delivererNotifierProvider);

    final isLoading = state.isLoading || _isUploading;

    return Scaffold(
      backgroundColor: background,

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
          onPressed: isLoading ? null : () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 19,
            color: dark,
          ),
        ),
        title: const BazzarPageTitle(
          title: Text(
            'Nouveau livreur',
            style: TextStyle(
              color: dark,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: 'Un nouveau membre dans votre équipe',
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIntro(),

              const SizedBox(height: 22),

              _buildAvatarSection(),

              const SizedBox(height: 24),

              _buildFormCard(),

              const SizedBox(height: 20),

              _buildSecurityInfo(),

              const SizedBox(height: 26),

              _buildCreateButton(isLoading),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INTRO
  // ---------------------------------------------------------------------------

  Widget _buildIntro() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ajouter un membre',
          style: TextStyle(
            color: dark,
            fontSize: 25,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),

        SizedBox(height: 6),

        Text(
          'Créez un compte livreur pour gérer vos livraisons.',
          style: TextStyle(color: muted, fontSize: 13, height: 1.45),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // AVATAR
  // ---------------------------------------------------------------------------

  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _isUploading ? null : _showImageSourceDialog,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFFE0E7FF),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _localAvatarFile != null
                        ? Image.file(_localAvatarFile!, fit: BoxFit.cover)
                        : Container(
                            color: BazzarColors.lavender,
                            child: const Icon(
                              Icons.person_rounded,
                              color: primary,
                              size: 48,
                            ),
                          ),
                  ),
                ),

                Positioned(
                  right: 0,
                  bottom: 2,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: background, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: _isUploading
                        ? const Padding(
                            padding: EdgeInsets.all(9),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 17,
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Ajouter une photo',
            style: TextStyle(
              color: primary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 3),

          const Text('Optionnel', style: TextStyle(color: muted, fontSize: 11)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FORM
  // ---------------------------------------------------------------------------

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 24,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTextField(
            controller: _fullNameController,
            label: 'Nom complet',
            hint: 'Ex. Jean Dupont',
            icon: Icons.person_outline_rounded,
            textCapitalization: TextCapitalization.words,
          ),

          const SizedBox(height: 17),

          _buildTextField(
            controller: _emailController,
            label: 'Adresse email',
            hint: 'livreur@email.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 17),

          _buildTextField(
            controller: _phoneController,
            label: 'Téléphone',
            hint: '+261 XX XX XXX XX',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 17),

          _buildTextField(
            controller: _passwordController,
            label: 'Mot de passe',
            hint: 'Minimum 6 caractères',
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePassword,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: muted,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: dark,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          style: const TextStyle(
            color: dark,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: BazzarColors.muted, fontSize: 13),

            prefixIcon: Icon(icon, color: primary, size: 20),

            suffixIcon: suffixIcon,

            filled: true,
            fillColor: BazzarColors.background,

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: border),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: border),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SECURITY INFO
  // ---------------------------------------------------------------------------

  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: BazzarColors.lavender,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: Color(0xFF2563EB),
            size: 20,
          ),

          SizedBox(width: 11),

          Expanded(
            child: Text(
              'Les informations du livreur sont sécurisées. '
              'Son compte sera créé avec les identifiants fournis.',
              style: TextStyle(
                color: Color(0xFF1E40AF),
                fontSize: 11,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUTTON
  // ---------------------------------------------------------------------------

  Widget _buildCreateButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : _createLivreur,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          disabledBackgroundColor: primary.withValues(alpha: 0.55),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: primary.withValues(alpha: 0.30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Row(
                  key: ValueKey('button'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add_alt_1_rounded, size: 20),
                    SizedBox(width: 9),
                    Text(
                      'Créer le livreur',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
