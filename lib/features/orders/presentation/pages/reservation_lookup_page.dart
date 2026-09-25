import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/reservation_provider.dart';
import 'reservation_details_page.dart';

class ReservationLookupPage extends ConsumerStatefulWidget {
  const ReservationLookupPage({super.key});

  @override
  ConsumerState<ReservationLookupPage> createState() => _ReservationLookupPageState();
}

class _ReservationLookupPageState extends ConsumerState<ReservationLookupPage> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _lookupReservation() async {
    final id = _controller.text.trim();
    if (id.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(reservationRepositoryProvider);
      final reservation = await repository.getReservationById(id);

      if (!mounted) return;

      if (reservation != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReservationDetailsPage(reservation: reservation),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Réservation introuvable')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rechercher une réservation')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'ID de la réservation',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _lookupReservation,
                    child: const Text('Rechercher'),
                  ),
          ],
        ),
      ),
    );
  }
}
