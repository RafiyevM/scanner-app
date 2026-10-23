import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_scanner/l10n/app_localizations.dart';
import 'package:qr_scanner/src/data/product_registrar.dart';
import 'package:qr_scanner/src/data/product_repository.dart';
import 'package:qr_scanner/src/models/product.dart';
import 'package:qr_scanner/src/ui/add_product_sheet.dart';

const Product savedProduct = Product(
  id: 'PHN-011',
  name: 'New Phone',
  description: '',
  color: 'Red',
  quantity: 4,
  barcode: '2999999999999',
  qrCode: '{"id":"PHN-011","type":"phone"}',
);

class FakeRegistrar implements ProductRegistrar {
  FakeRegistrar(this.result);

  final RegisterResult result;
  NewProduct? received;

  @override
  Future<RegisterResult> register(NewProduct product) async {
    received = product;
    return result;
  }
}

Future<Product?> openSheet(
  WidgetTester tester,
  FakeRegistrar registrar,
) async {
  Product? returned;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Builder(
        builder: (BuildContext context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () async {
                returned = await showAddProductSheet(
                  context,
                  code: '2999999999999',
                  registrar: registrar,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return returned;
}

void main() {
  group('AddProductSheet', () {
    testWidgets('shows the scanned code and requires a name', (tester) async {
      final registrar = FakeRegistrar(const RegisterSuccess(savedProduct));
      await openSheet(tester, registrar);

      expect(find.text('2999999999999'), findsOneWidget);

      await tester.tap(find.byKey(const Key('add-product-save')));
      await tester.pump();

      expect(find.text('Enter the product name.'), findsOneWidget);
      expect(registrar.received, isNull);
    });

    testWidgets('saves with the entered details and quantity', (tester) async {
      final registrar = FakeRegistrar(const RegisterSuccess(savedProduct));
      await openSheet(tester, registrar);

      await tester.enterText(
          find.byKey(const Key('add-product-name')), 'New Phone');
      await tester.enterText(find.byKey(const Key('add-product-color')), 'Red');
      await tester.tap(find.byKey(const Key('add-product-plus')));
      await tester.tap(find.byKey(const Key('add-product-plus')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('add-product-save')));
      await tester.pumpAndSettle();

      expect(registrar.received?.code, '2999999999999');
      expect(registrar.received?.name, 'New Phone');
      expect(registrar.received?.color, 'Red');
      expect(registrar.received?.quantity, 3);
      expect(find.byKey(const Key('add-product-save')), findsNothing);
    });

    testWidgets('shows a message when the code already exists', (tester) async {
      final registrar = FakeRegistrar(const RegisterDuplicate());
      await openSheet(tester, registrar);

      await tester.enterText(
          find.byKey(const Key('add-product-name')), 'New Phone');
      await tester.tap(find.byKey(const Key('add-product-save')));
      await tester.pumpAndSettle();

      expect(find.text('This code is already in the depot.'), findsOneWidget);
      expect(find.byKey(const Key('add-product-save')), findsOneWidget);
    });

    testWidgets('shows a message when saving fails', (tester) async {
      final registrar = FakeRegistrar(
        const RegisterFailure(LookupFailureType.unreachable),
      );
      await openSheet(tester, registrar);

      await tester.enterText(
          find.byKey(const Key('add-product-name')), 'New Phone');
      await tester.tap(find.byKey(const Key('add-product-save')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('add-product-error')), findsOneWidget);
    });

    testWidgets('quantity cannot go below zero', (tester) async {
      final registrar = FakeRegistrar(const RegisterSuccess(savedProduct));
      await openSheet(tester, registrar);

      await tester.tap(find.byKey(const Key('add-product-minus')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('add-product-minus')));
      await tester.pump();

      expect(find.text('0'), findsOneWidget);
      final button = tester.widget<IconButton>(
        find.byKey(const Key('add-product-minus')),
      );
      expect(button.onPressed, isNull);
    });
  });
}
