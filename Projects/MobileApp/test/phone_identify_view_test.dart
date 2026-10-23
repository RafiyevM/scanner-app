import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_scanner/l10n/app_localizations.dart';
import 'package:qr_scanner/src/data/phone_identifier.dart';
import 'package:qr_scanner/src/data/product_repository.dart';
import 'package:qr_scanner/src/models/product.dart';
import 'package:qr_scanner/src/ui/phone_camera.dart';
import 'package:qr_scanner/src/ui/phone_identify_view.dart';

const Product inStockPhone = Product(
  id: 'PHN-011',
  name: 'iPhone 14',
  description: 'Depot phone.',
  color: 'Blue',
  quantity: 5,
  barcode: '7000000000001',
  qrCode: '{"id":"PHN-011","type":"phone"}',
);

const Product purpleProPhone = Product(
  id: 'PHN-012',
  name: 'iPhone 14 Pro',
  description: 'Purple edition.',
  color: 'Purple',
  quantity: 5,
  barcode: '2000000000121',
  qrCode: '{"id":"PHN-012","type":"phone"}',
);

const Product soldOutPhone = Product(
  id: 'PHN-012',
  name: 'Galaxy S23',
  description: 'Depot phone.',
  color: 'Black',
  quantity: 0,
  barcode: '7000000000002',
  qrCode: '{"id":"PHN-012","type":"phone"}',
);

class FakeCamera implements PhoneCamera {
  FakeCamera({this.failToStart = false});

  final bool failToStart;
  bool disposed = false;
  int photos = 0;

  @override
  Future<void> initialize() async {
    if (failToStart) {
      throw StateError('no camera');
    }
  }

  @override
  Widget buildPreview() => const ColoredBox(color: Colors.black);

  @override
  Future<Uint8List> takePhoto() async {
    photos++;
    return Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF]);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

class FakeIdentifier implements PhoneIdentifier {
  FakeIdentifier(this.results);

  final List<IdentifyResult> results;
  int calls = 0;

  @override
  Future<IdentifyResult> identify(Uint8List jpeg) async {
    final IdentifyResult result = results[calls < results.length ? calls : 0];
    calls++;
    return result;
  }
}

Future<List<FakeCamera>> pumpView(
  WidgetTester tester,
  FakeIdentifier identifier, {
  bool failToStart = false,
}) async {
  tester.view.physicalSize = const Size(420, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final cameras = <FakeCamera>[];
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: PhoneIdentifyView(
            identifier: identifier,
            cameraFactory: () {
              final camera = FakeCamera(failToStart: failToStart);
              cameras.add(camera);
              return camera;
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return cameras;
}

Future<void> identify(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('identify-button')));
  await tester.pumpAndSettle();
}

void main() {
  group('PhoneIdentifyView', () {
    testWidgets('shows the hint and Identify button when the camera is ready', (
      tester,
    ) async {
      await pumpView(tester, FakeIdentifier(const <IdentifyResult>[]));

      expect(find.text('Identify'), findsOneWidget);
      expect(
        find.text('Show the back of a phone, then tap Identify'),
        findsOneWidget,
      );
    });

    testWidgets(
        'an in-stock match shows the depot product and closes the camera', (
      tester,
    ) async {
      final identifier = FakeIdentifier(const <IdentifyResult>[
        IdentifySuccess(
          brand: 'Apple',
          model: 'iPhone 14',
          confidence: 0.93,
          matches: <Product>[inStockPhone],
        ),
      ]);
      final cameras = await pumpView(tester, identifier);

      await identify(tester);

      expect(cameras.single.photos, 1);
      expect(cameras.single.disposed, isTrue);
      expect(identifier.calls, 1);
      expect(find.text('Identified as Apple iPhone 14 (93%)'), findsOneWidget);
      expect(find.text('Product found'), findsOneWidget);
      expect(find.text('5 in stock'), findsOneWidget);
      expect(find.text('Identify another phone'), findsOneWidget);
    });

    testWidgets('a sold-out match shows Not in stock', (tester) async {
      await pumpView(
        tester,
        FakeIdentifier(const <IdentifyResult>[
          IdentifySuccess(
            brand: 'Samsung',
            model: 'Galaxy S23',
            confidence: 0.7,
            matches: <Product>[soldOutPhone],
          ),
        ]),
      );

      await identify(tester);

      expect(find.text('Not in stock'), findsWidgets);
    });

    testWidgets('an unlisted model says it is not in the depot',
        (tester) async {
      await pumpView(
        tester,
        FakeIdentifier(const <IdentifyResult>[
          IdentifySuccess(
            brand: 'Apple',
            model: 'iPhone 15',
            confidence: 0.8,
            matches: <Product>[],
          ),
        ]),
      );

      await identify(tester);

      expect(find.text('Apple iPhone 15 is not in the depot.'), findsOneWidget);
    });

    testWidgets('a black phone is not matched to the purple one in the depot', (
      tester,
    ) async {
      await pumpView(
        tester,
        FakeIdentifier(const <IdentifyResult>[
          IdentifySuccess(
            brand: 'Apple',
            model: 'iPhone 14 Pro',
            color: 'Black',
            confidence: 0.9,
            matches: <Product>[],
            modelMatches: <Product>[purpleProPhone],
          ),
        ]),
      );

      await identify(tester);

      expect(
        find.text('Identified as Apple iPhone 14 Pro, Black (90%)'),
        findsWidgets,
      );
      expect(
        find.text(
          'Apple iPhone 14 Pro in Black is not in the depot. '
          'The depot has this model in: Purple.',
        ),
        findsOneWidget,
      );
      expect(find.text('Product found'), findsNothing);
    });

    testWidgets('the same color shows the depot product', (tester) async {
      await pumpView(
        tester,
        FakeIdentifier(const <IdentifyResult>[
          IdentifySuccess(
            brand: 'Apple',
            model: 'iPhone 14 Pro',
            color: 'Purple',
            confidence: 0.9,
            matches: <Product>[purpleProPhone],
            modelMatches: <Product>[purpleProPhone],
          ),
        ]),
      );

      await identify(tester);

      expect(find.text('Product found'), findsOneWidget);
      expect(find.text('Purple'), findsOneWidget);
      expect(find.textContaining('Could not tell the color'), findsNothing);
    });

    testWidgets('an unknown color is flagged on a match', (tester) async {
      await pumpView(
        tester,
        FakeIdentifier(const <IdentifyResult>[
          IdentifySuccess(
            brand: 'Apple',
            model: 'iPhone 14 Pro',
            confidence: 0.9,
            matches: <Product>[purpleProPhone],
          ),
        ]),
      );

      await identify(tester);

      expect(find.text('Product found'), findsOneWidget);
      expect(
        find.textContaining('Could not tell the color'),
        findsOneWidget,
      );
    });

    testWidgets('a low-confidence answer warns the user', (tester) async {
      await pumpView(
        tester,
        FakeIdentifier(const <IdentifyResult>[
          IdentifySuccess(
            brand: 'Apple',
            model: 'iPhone 13',
            confidence: 0.3,
            matches: <Product>[],
          ),
        ]),
      );

      await identify(tester);

      expect(find.textContaining('Not sure.'), findsOneWidget);
    });

    testWidgets('a picture without a phone is reported', (tester) async {
      await pumpView(
        tester,
        FakeIdentifier(const <IdentifyResult>[IdentifyNotPhone()]),
      );

      await identify(tester);

      expect(
        find.text('No phone found. Point the camera at a phone.'),
        findsWidgets,
      );
    });

    testWidgets('an unconfigured server is reported', (tester) async {
      await pumpView(
        tester,
        FakeIdentifier(const <IdentifyResult>[IdentifyNotConfigured()]),
      );

      await identify(tester);

      expect(
        find.text('Phone recognition is not set up on the server.'),
        findsOneWidget,
      );
    });

    testWidgets('a failure can be retried without a new photo', (tester) async {
      final identifier = FakeIdentifier(const <IdentifyResult>[
        IdentifyFailure(LookupFailureType.unreachable),
        IdentifySuccess(
          brand: 'Apple',
          model: 'iPhone 14',
          confidence: 0.9,
          matches: <Product>[inStockPhone],
        ),
      ]);
      final cameras = await pumpView(tester, identifier);

      await identify(tester);
      expect(
        find.text(
            'Could not reach the server. Check your connection and try again.'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('identify-retry')));
      await tester.pumpAndSettle();

      expect(identifier.calls, 2);
      expect(cameras.single.photos, 1);
      expect(find.text('Product found'), findsOneWidget);
    });

    testWidgets('Identify another reopens a fresh camera', (tester) async {
      final cameras = await pumpView(
        tester,
        FakeIdentifier(const <IdentifyResult>[IdentifyNotPhone()]),
      );

      await identify(tester);
      await tester.tap(find.byKey(const Key('identify-another')));
      await tester.pumpAndSettle();

      expect(cameras.length, 2);
      expect(find.byKey(const Key('identify-button')), findsOneWidget);
    });

    testWidgets('a camera that cannot start shows an error and retry', (
      tester,
    ) async {
      await pumpView(
        tester,
        FakeIdentifier(const <IdentifyResult>[]),
        failToStart: true,
      );

      expect(find.text('Could not open the camera.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
