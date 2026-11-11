import 'package:live_shopping/core/theme/bazzar_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:live_shopping/core/utils/error_helper.dart';
import 'package:live_shopping/core/widgets/app_notification.dart';
import '../providers/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String _selectedRole = 'client';

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_isLoading) return;

    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    FocusScope.of(context).unfocus();

    if (fullName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      if (!mounted) return;
      AppNotification.showError(
        context,
        'Veuillez remplir tous les champs avant de continuer.',
      );
      return;
    }

    if (!_isValidEmail(email)) {
      if (!mounted) return;
      AppNotification.showError(
        context,
        'Veuillez saisir une adresse email valide.',
      );
      return;
    }

    if (password.length < 6) {
      if (!mounted) return;
      AppNotification.showError(
        context,
        'Votre mot de passe doit contenir au moins 6 caractères.',
      );
      return;
    }

    if (password != confirmPassword) {
      if (!mounted) return;
      AppNotification.showError(
        context,
        'Les deux mots de passe ne correspondent pas.',
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await ref
          .read(authRepositoryProvider)
          .signUp(
            email: email,
            password: password,
            fullName: fullName,
            role: _selectedRole,
          );

      if (!mounted) return;
      await _showSuccessDialog();
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      debugPrint('Register error: $e');
      if (!mounted) return;
      AppNotification.showError(context, getFriendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  Future<void> _showSuccessDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Compte créé'),
          content: const Text('Votre compte a été créé avec succès.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Continuer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: BazzarColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: height * 0.18,
                  width: double.infinity,
                  child: CustomPaint(painter: _RegisterWavePainter()),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          tooltip: 'Retour',
                          onPressed: () => context.pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: BazzarColors.primaryDark,
                            size: 27,
                          ),
                        ),
                      ),
                      _buildBrand(),
                      const SizedBox(height: 28),
                      _buildRoleSelector(),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: BazzarColors.border),
                        ),
                        child: _buildForm(),
                      ),
                      const SizedBox(height: 24),
                      _buildLoginLink(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrand() {
    return Column(
      children: [
        Image.asset(
          'sary/logo.png',
          width: 160,
          height: 125,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.shopping_bag_rounded,
            color: BazzarColors.primaryDark,
            size: 86,
          ),
        ),
        const Text(
          'Créez votre compte pour commencer\nà profiter de Bazzar Live',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF7471A6),
            fontSize: 17,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        border: Border.all(color: const Color(0xFFD3CFFF), width: 1.5),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildRoleOption(
              role: 'client',
              icon: Icons.person_outline_rounded,
              title: 'Client',
              subtitle: 'Acheteur',
            ),
          ),
          Expanded(
            child: _buildRoleOption(
              role: 'vendeur',
              icon: Icons.storefront_outlined,
              title: 'Vendeur',
              subtitle: 'Vendez vos produits',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleOption({
    required String role,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [BazzarColors.primary, Color(0xFF8B3FF2)],
                )
              : null,
          borderRadius: BorderRadius.circular(23),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : const Color(0xFF5F5B91),
              size: 28,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF4B477E),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.9)
                          : BazzarColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        _buildField(
          controller: _fullNameController,
          label: 'Nom complet',
          hint: 'Ex : Rakotomalala Jean',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 14),
        _buildField(
          controller: _emailController,
          label: 'Adresse email',
          hint: 'Ex : votre@email.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _buildField(
          controller: _passwordController,
          label: 'Mot de passe',
          hint: 'Minimum 6 caractères',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscurePassword,
          suffixIcon: _visibilityButton(
            hidden: _obscurePassword,
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 14),
        _buildField(
          controller: _confirmPasswordController,
          label: 'Confirmer le mot de passe',
          hint: 'Répétez votre mot de passe',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscureConfirmPassword,
          suffixIcon: _visibilityButton(
            hidden: _obscureConfirmPassword,
            onPressed: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [BazzarColors.primary, Color(0xFF8B3FF2)],
              ),
              borderRadius: BorderRadius.circular(19),
              boxShadow: [
                BoxShadow(
                  color: BazzarColors.primary.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white,
                shadowColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(19),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            'Créer mon compte',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        SizedBox(width: 14),
                        Icon(Icons.arrow_forward_rounded, size: 27),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: obscureText
          ? TextInputAction.done
          : TextInputAction.next,
      style: const TextStyle(
        color: Color(0xFF4B477E),
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
          color: Color(0xFF4B477E),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFFA4A1D0),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF5F5B91), size: 30),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.86),
        contentPadding: const EdgeInsets.fromLTRB(18, 17, 14, 17),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFD3CFFF), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFD3CFFF), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: BazzarColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _visibilityButton({
    required bool hidden,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: hidden ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
      onPressed: onPressed,
      icon: Icon(
        hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: const Color(0xFF5F5B91),
        size: 27,
      ),
    );
  }

  Widget _buildLoginLink() {
    return Column(
      children: [
        const Row(
          children: [
            Expanded(child: Divider(color: Color(0xFFB9B5D9))),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'ou',
                style: TextStyle(
                  color: Color(0xFF7471A6),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(child: Divider(color: Color(0xFFB9B5D9))),
          ],
        ),
        const SizedBox(height: 22),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            const Text(
              'Déjà un compte ?  ',
              style: TextStyle(
                color: Color(0xFF7471A6),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/login'),
              child: const Text(
                'Se connecter',
                style: TextStyle(
                  color: BazzarColors.primaryDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RegisterWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(0, size.height * 0.45);
    path.cubicTo(
      size.width * 0.23,
      size.height * 0.02,
      size.width * 0.43,
      size.height * 0.95,
      size.width * 0.65,
      size.height * 0.62,
    );
    path.cubicTo(
      size.width * 0.82,
      size.height * 0.34,
      size.width * 0.9,
      size.height * 0.08,
      size.width,
      size.height * 0.12,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFE9E4FF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
