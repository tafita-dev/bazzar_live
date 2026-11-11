@TestOn('browser')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_shopping/features/live/presentation/widgets/facebook_live_player.dart';

void main() {
  testWidgets(
    'Le lecteur web se monte et ses commandes fonctionnent sans WebView native',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, _) => Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (_) => const Scaffold(
                  body: SizedBox(
                    width: 360,
                    height: 500,
                    child: FacebookLivePlayer(
                      facebookUrl: 'https://www.facebook.com/watch/?v=123',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(HtmlElementView), findsOneWidget);

      await tester.tap(find.byTooltip('Couper le son'));
      await tester.pump();
      expect(find.byTooltip('Activer le son'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final previousKey = tester
          .widget<HtmlElementView>(find.byType(HtmlElementView))
          .key;
      await tester.tap(find.byTooltip('Recharger la vidéo'));
      await tester.pump();
      expect(
        tester.widget<HtmlElementView>(find.byType(HtmlElementView)).key,
        isNot(previousKey),
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );
}
