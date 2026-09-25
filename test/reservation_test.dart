import 'package:flutter_test/flutter_test.dart';
import 'package:live_shopping/features/orders/domain/entities/reservation.dart';

void main() {
  group('Reservation Model Tests', () {
    test('fromJson should correctly parse snake_case keys from database', () {
      final json = {
        'id': 'res-123',
        'user_id': 'user-789',
        'status': 'validated',
        'client_info': {'nom': 'Client'},
        'payment_method_id': 'cod',
        'total_amount': 100.0,
        'products': [
          {'product_id': 'prod-456', 'name': 'Product 1', 'quantité': 1, 'prix_unitaire': 50.0}
        ],
      };

      final reservation = Reservation.fromJson(json);

      expect(reservation.id, 'res-123');
      expect(reservation.userId, 'user-789');
      expect(reservation.status, 'validated');
      expect(reservation.products.first['product_id'], 'prod-456');
    });

    test('fromJson should default status to pending when status is missing', () {
      final json = {
        'id': 'res-123',
        'user_id': 'user-789',
        'client_info': {'nom': 'Client'},
        'payment_method_id': 'cod',
        'total_amount': 100.0,
        'products': [],
      };

      final reservation = Reservation.fromJson(json);

      expect(reservation.id, 'res-123');
      expect(reservation.userId, 'user-789');
      expect(reservation.status, 'pending');
    });

    test('toJson should serialize camelCase fields into snake_case properties', () {
      const reservation = Reservation(
        id: 'res-123',
        userId: 'user-789',
        clientInfo: {'nom': 'Client'},
        paymentMethodId: 'cod',
        totalAmount: 100.0,
        products: [
          {'product_id': 'prod-456', 'name': 'Product 1', 'quantité': 1, 'prix_unitaire': 50.0}
        ],
        status: 'validated',
      );

      final json = reservation.toJson();

      expect(json['id'], 'res-123');
      expect(json['user_id'], 'user-789');
      expect(json['status'], 'validated');
      expect((json['products'] as List).first['product_id'], 'prod-456');
    });
  });
}
