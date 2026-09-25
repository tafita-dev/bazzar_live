import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_shopping/features/delivery/presentation/pages/reservation_details_page.dart';

void main() {
  testWidgets('ReservationDetailsPage should display reservation details correctly', (WidgetTester tester) async {
    final Map<String, dynamic> mockReservation = {
      'client_info': {
        'nom': 'John Doe',
        'contact': '123456789',
        'adresse': '123 Main St'
      },
      'total_amount': 50.0,
      'qr_token': 'mock-token'
    };

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ReservationDetailsPage(reservation: mockReservation),
        ),
      ),
    );

    expect(find.text('Client: John Doe'), findsOneWidget);
    expect(find.text('Téléphone: 123456789'), findsOneWidget);
    expect(find.text('Adresse: 123 Main St'), findsOneWidget);
    expect(find.text('Total: 50.0'), findsOneWidget);
    expect(find.text('Confirmer la livraison'), findsOneWidget);
  });
}
