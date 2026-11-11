import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_shopping/core/theme/app_theme.dart';
import 'package:live_shopping/core/widgets/bazzar_ui.dart';
import 'package:live_shopping/features/auth/presentation/pages/login_page.dart';
import 'package:live_shopping/features/auth/presentation/pages/register_page.dart';

void main() {
  Future<void> mount(
    WidgetTester tester,
    Widget page, {
    double keyboard = 0,
  }) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, _) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.6),
              viewInsets: EdgeInsets.only(bottom: keyboard),
            ),
            child: Overlay(
              initialEntries: [OverlayEntry(builder: (_) => page)],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Connexion compacte avec clavier et texte agrandi', (
    tester,
  ) async {
    await mount(tester, const LoginPage(), keyboard: 260);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Inscription compacte avec texte agrandi', (tester) async {
    await mount(tester, const RegisterPage());
    expect(tester.takeException(), isNull);
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Les filtres et la liste restent accessibles sur petit écran', (
    tester,
  ) async {
    await mount(
      tester,
      Scaffold(
        body: BazzarCollectionLayout(
          header: const [
            BazzarIntro(
              title: 'Votre catalogue',
              description:
                  'Retrouvez vos produits et les informations de votre boutique.',
              icon: Icons.shopping_bag_outlined,
            ),
          ],
          body: ListView.builder(
            itemCount: 30,
            itemBuilder: (_, index) => ListTile(title: Text('Produit $index')),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(NestedScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Produit 5'), findsOneWidget);
  });
}
