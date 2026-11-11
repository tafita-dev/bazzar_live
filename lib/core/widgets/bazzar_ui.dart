import 'package:flutter/material.dart';
import '../theme/bazzar_colors.dart';

/// Lets metrics and filters scroll away on compact screens while keeping
/// the existing lazy list and its refresh handling as the inner scroll view.
class BazzarCollectionLayout extends StatelessWidget {
  const BazzarCollectionLayout({
    super.key,
    required this.header,
    required this.body,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });
  final List<Widget> header;
  final Widget body;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) => NestedScrollView(
    headerSliverBuilder: (context, innerBoxIsScrolled) => [
      SliverToBoxAdapter(
        child: Column(crossAxisAlignment: crossAxisAlignment, children: header),
      ),
    ],
    body: body,
  );
}

/// A compact page heading, kept in the scrollable content of forms.
class BazzarIntro extends StatelessWidget {
  const BazzarIntro({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: BazzarColors.hero,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFF6CC78), size: 28),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFFE9DDFB),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class BazzarEmptyState extends StatelessWidget {
  const BazzarEmptyState({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });
  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: BazzarColors.lavender,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: BazzarColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: BazzarColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: BazzarColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class BazzarPageTitle extends StatelessWidget {
  const BazzarPageTitle({
    super.key,
    required this.title,
    required this.subtitle,
  });
  final Widget title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    // At large font sizes, reserve the toolbar for its primary title.
    final showSubtitle = MediaQuery.textScalerOf(context).scale(14) <= 18;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DefaultTextStyle.merge(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          child: title,
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: BazzarColors.muted,
            ),
          ),
        ],
      ],
    );
  }
}
