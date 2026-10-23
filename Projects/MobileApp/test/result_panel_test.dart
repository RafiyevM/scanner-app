import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_scanner/l10n/app_localizations.dart';
import 'package:qr_scanner/src/data/product_repository.dart';
import 'package:qr_scanner/src/models/product.dart';
import 'package:qr_scanner/src/state/scan_ui_state.dart';
import 'package:qr_scanner/src/ui/result_panel.dart';

const Product sampleProduct = Product(
  id: 'PHN-001',
  name: 'Aurora X1',
  description: 'A phone.',
  color: 'Midnight Black',
  quantity: 12,
  barcode: '2000000000015',
  qrCode: '{"id":"PHN-001","type":"phone"}',
);

const Product outOfStockProduct = Product(
  id: 'PHN-003',
  name: 'Pulse 7',
  description: 'An unavailable phone.',
  color: 'Arctic White',
  quantity: 0,
  barcode: '2000000000039',
  qrCode: '{"id":"PHN-003","type":"phone"}',
);

Widget wrap(Widget child) => MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: child),
    );

Future<void> pumpPanel(WidgetTester tester, ScanUiState state) async {
  await tester.pumpWidget(
    wrap(
      ResultPanel(
        state: state,
        onScanAgain: () {},
        onRetry: () async {},
      ),
    ),
  );
}

void main() {
  group('ResultPanel', () {
    testWidgets('scanning shows the ready message', (tester) async {
      await pumpPanel(tester, const ScanningState());

      expect(find.text('Ready to scan'), findsOneWidget);
    });

    testWidgets('loading shows the lookup code', (tester) async {
      await pumpPanel(tester, const LoadingState('PHN-001'));

      expect(find.text('Looking up PHN-001…'), findsOneWidget);
    });

    testWidgets('not found hides add-to-depot without a handler', (
      tester,
    ) async {
      await pumpPanel(tester, const NotFoundState('2999999999999'));

      expect(find.byKey(const Key('add-to-depot')), findsNothing);
      expect(find.text('Scan another code'), findsOneWidget);
    });

    testWidgets('not found offers add-to-depot with the scanned code', (
      tester,
    ) async {
      String? tapped;
      await tester.pumpWidget(
        wrap(
          ResultPanel(
            state: const NotFoundState('2999999999999'),
            onScanAgain: () {},
            onRetry: () async {},
            onAddToDepot: (String code) => tapped = code,
          ),
        ),
      );

      expect(find.text('Add to depot'), findsOneWidget);
      await tester.tap(find.byKey(const Key('add-to-depot')));

      expect(tapped, '2999999999999');
    });

    testWidgets('a long barcode shrinks to fit without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpPanel(
        tester,
        const SuccessState(
          Product(
            id: 'PHN-001',
            name: 'Aurora X1',
            description: 'A phone.',
            color: 'Midnight Black',
            quantity: 12,
            barcode: '20000000000150000000',
            qrCode: '{"id":"PHN-001"}',
          ),
        ),
      );

      expect(find.text('20000000000150000000'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('success renders all product details', (tester) async {
      await pumpPanel(tester, const SuccessState(sampleProduct));

      expect(find.text('Product found'), findsOneWidget);
      expect(find.text('In stock'), findsOneWidget);
      expect(find.text('Aurora X1'), findsOneWidget);
      expect(find.text('A phone.'), findsOneWidget);
      expect(find.text('PHN-001'), findsOneWidget);
      expect(find.text('Midnight Black'), findsOneWidget);
      expect(find.text('12 in stock'), findsOneWidget);
      expect(find.text('2000000000015'), findsOneWidget);
      expect(find.text('Scan another code'), findsOneWidget);
    });

    testWidgets('out of stock renders the product and unavailable message', (
      tester,
    ) async {
      await pumpPanel(tester, const OutOfStockState(outOfStockProduct));

      expect(find.text('Not in stock'), findsOneWidget);
      expect(find.text('Unavailable'), findsOneWidget);
      expect(find.text('Pulse 7'), findsOneWidget);
      expect(find.text('Out of stock'), findsOneWidget);
      expect(
        find.textContaining('not available in the depot'),
        findsOneWidget,
      );
      expect(find.text('Scan another code'), findsOneWidget);
    });

    testWidgets('not found renders the scanned code', (tester) async {
      await pumpPanel(tester, const NotFoundState('UNKNOWN'));

      expect(find.text('No such product'), findsOneWidget);
      expect(find.textContaining('UNKNOWN'), findsOneWidget);
    });

    testWidgets('invalid renders the parse reason', (tester) async {
      await pumpPanel(
        tester,
        const InvalidState(raw: 'x', reason: 'Malformed JSON.'),
      );

      expect(find.text('Unsupported code'), findsOneWidget);
      expect(find.text('Malformed JSON.'), findsOneWidget);
    });

    testWidgets('retryable error offers retry and scan again', (tester) async {
      await pumpPanel(
        tester,
        const ErrorState(
          failureType: LookupFailureType.serverUnavailable,
          retryable: true,
        ),
      );

      expect(find.text('Could not load the product'), findsOneWidget);
      expect(
        find.text('The server is unavailable. Try again later.'),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Scan another code'), findsOneWidget);
    });

    testWidgets('non-retryable error hides retry', (tester) async {
      await pumpPanel(
        tester,
        const ErrorState(
          failureType: LookupFailureType.unexpectedResponse,
          retryable: false,
        ),
      );

      expect(find.text('Try again'), findsNothing);
      expect(find.text('Scan another code'), findsOneWidget);
    });
  });
}
