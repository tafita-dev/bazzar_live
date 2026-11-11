import 'package:live_shopping/core/theme/bazzar_colors.dart';
import 'package:flutter/material.dart';
import 'package:live_shopping/core/widgets/bazzar_ui.dart';

class SellerReservationsPage extends StatelessWidget {
  final String sellerId;
  const SellerReservationsPage({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context) {
    print('--------------------------------------------------');
    print('SELLER_RESERVATIONS_PAGE: REACHED WITH SELLER_ID: $sellerId');
    print('--------------------------------------------------');

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
        title: const Text('Gestion des Réservations'),
      ),
      body: const Center(
        child: SingleChildScrollView(
          child: BazzarEmptyState(
            title: 'Vos réservations',
            description:
                'Retrouvez la gestion de vos commandes dans votre espace vendeur.',
            icon: Icons.receipt_long_outlined,
          ),
        ),
      ),
    );
  }
}
