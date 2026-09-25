import 'package:flutter/material.dart';
import 'package:live_shopping/core/router/router.dart';

class AppNotification {
  static OverlayEntry? _currentEntry;

  /// Affiche une notification de succès (verte) en haut de l'écran.
  static void showSuccess(BuildContext context, String message) {
    _show(context, message, isError: false, isInfo: false);
  }

  /// Affiche une notification d'erreur (rouge) en haut de l'écran.
  static void showError(BuildContext context, String message) {
    _show(context, message, isError: true, isInfo: false);
  }

  /// Affiche une notification d'information (indigo) en haut de l'écran.
  static void showInfo(BuildContext context, String message) {
    _show(context, message, isError: false, isInfo: true);
  }

  /// Affiche une notification globale sans avoir besoin d'un BuildContext local (utilise rootNavigatorKey).
  static void showGlobal(String message, {bool isError = false, bool isInfo = false}) {
    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      _show(context, message, isError: isError, isInfo: isInfo);
    }
  }

  static void _show(BuildContext context, String message, {required bool isError, required bool isInfo}) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: TopNotificationOverlay(
          message: message,
          isError: isError,
          isInfo: isInfo,
          onDismiss: () {
            _currentEntry?.remove();
            _currentEntry = null;
          },
        ),
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }
}

class TopNotificationOverlay extends StatefulWidget {
  final String message;
  final bool isError;
  final bool isInfo;
  final VoidCallback onDismiss;

  const TopNotificationOverlay({
    super.key,
    required this.message,
    required this.isError,
    required this.isInfo,
    required this.onDismiss,
  });

  @override
  State<TopNotificationOverlay> createState() => _TopNotificationOverlayState();
}

class _TopNotificationOverlayState extends State<TopNotificationOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    // Auto-fermeture après 3 secondes
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    if (_controller.isAnimating) return;
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = const Color(0xFF10B981); // Succès vert émeraude
    IconData icon = Icons.check_circle_rounded;
    Color glowColor = const Color(0xFF10B981);

    if (widget.isError) {
      bgColor = const Color(0xFFEF4444); // Erreur rouge corail
      glowColor = const Color(0xFFEF4444);
      icon = Icons.error_rounded;
    } else if (widget.isInfo) {
      bgColor = const Color(0xFF7C3AED); // Info violet royal
      glowColor = const Color(0xFF7C3AED);
      icon = Icons.info_rounded;
    }

    return SlideTransition(
      position: _offsetAnimation,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Material(
            color: Colors.transparent,
            child: Dismissible(
              key: const Key('notification_overlay'),
              direction: DismissDirection.up,
              onDismissed: (_) => widget.onDismiss(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _dismiss,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
