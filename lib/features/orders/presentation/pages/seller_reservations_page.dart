import 'package:flutter/material.dart';

class SellerReservationsPage extends StatelessWidget {
  final String sellerId;
  const SellerReservationsPage({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context) {
    print('--------------------------------------------------');
    print('SELLER_RESERVATIONS_PAGE: REACHED WITH SELLER_ID: $sellerId');
    print('--------------------------------------------------');
    
    return Scaffold(
      appBar: AppBar(title: const Text('Gestion des Réservations')),
      body: const Center(
        child: Text(
          'Hello World',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
