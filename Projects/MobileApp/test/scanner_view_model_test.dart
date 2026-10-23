import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:qr_scanner/src/data/product_repository.dart';
import 'package:qr_scanner/src/models/product.dart';
import 'package:qr_scanner/src/state/scan_ui_state.dart';
import 'package:qr_scanner/src/state/scanner_view_model.dart';

class QueueRepository implements ProductRepository {
  QueueRepository(List<LookupResult> results)
      : _results = Queue<LookupResult>.of(results);

  final Queue<LookupResult> _results;
  int calls = 0;

  @override
  Future<LookupResult> findByCode(String code) async {
    calls++;
    return _results.isNotEmpty
        ? _results.removeFirst()
        : const ProductNotFound();
  }
}

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

void main() {
  group('ScannerViewModel', () {
    test('shows a registered product as success', () {
      final viewModel = ScannerViewModel(QueueRepository(<LookupResult>[]));

      viewModel.showRegistered(sampleProduct);

      expect(viewModel.state, isA<SuccessState>());
    });

    test('shows a registered zero-quantity product as out of stock', () {
      final viewModel = ScannerViewModel(QueueRepository(<LookupResult>[]));

      viewModel.showRegistered(outOfStockProduct);

      expect(viewModel.state, isA<OutOfStockState>());
    });

    test('rejects invalid content without a lookup', () async {
      final repository = QueueRepository(<LookupResult>[]);
      final viewModel = ScannerViewModel(repository);

      await viewModel.onQrDetected('not a valid code');

      expect(viewModel.state, isA<InvalidState>());
      expect(repository.calls, 0);
    });

    test('loads an in-stock product', () async {
      final repository = QueueRepository(<LookupResult>[
        const ProductFound(sampleProduct),
      ]);
      final viewModel = ScannerViewModel(repository);

      await viewModel.onQrDetected('PHN-001');

      expect(viewModel.state, isA<SuccessState>());
      expect((viewModel.state as SuccessState).product.name, 'Aurora X1');
      expect(repository.calls, 1);
    });

    test('reports an out-of-stock product', () async {
      final repository = QueueRepository(<LookupResult>[
        const ProductOutOfStock(outOfStockProduct),
      ]);
      final viewModel = ScannerViewModel(repository);

      await viewModel.onQrDetected('PHN-003');

      expect(viewModel.state, isA<OutOfStockState>());
      expect(
        (viewModel.state as OutOfStockState).product.name,
        'Pulse 7',
      );
    });

    test('reports a missing product', () async {
      final repository = QueueRepository(<LookupResult>[
        const ProductNotFound(),
      ]);
      final viewModel = ScannerViewModel(repository);

      await viewModel.onQrDetected('UNKNOWN');

      expect(viewModel.state, isA<NotFoundState>());
      expect((viewModel.state as NotFoundState).code, 'UNKNOWN');
    });

    test('reports a retryable failure', () async {
      final repository = QueueRepository(<LookupResult>[
        const ProductLookupFailure(LookupFailureType.serverUnavailable),
      ]);
      final viewModel = ScannerViewModel(repository);

      await viewModel.onQrDetected('PHN-001');

      expect(viewModel.state, isA<ErrorState>());
      expect((viewModel.state as ErrorState).retryable, isTrue);
    });

    test('locks scanning after success', () async {
      final repository = QueueRepository(<LookupResult>[
        const ProductFound(sampleProduct),
      ]);
      final viewModel = ScannerViewModel(repository);

      await viewModel.onQrDetected('PHN-001');
      await viewModel.onQrDetected('PHN-002');

      expect(repository.calls, 1);
    });

    test('locks scanning after out of stock', () async {
      final repository = QueueRepository(<LookupResult>[
        const ProductOutOfStock(outOfStockProduct),
      ]);
      final viewModel = ScannerViewModel(repository);

      await viewModel.onQrDetected('PHN-003');
      await viewModel.onQrDetected('PHN-002');

      expect(repository.calls, 1);
    });

    test('reset allows the next scan', () async {
      final repository = QueueRepository(<LookupResult>[
        const ProductFound(sampleProduct),
        const ProductFound(sampleProduct),
      ]);
      final viewModel = ScannerViewModel(repository);

      await viewModel.onQrDetected('PHN-001');
      viewModel.reset();
      await viewModel.onQrDetected('PHN-002');

      expect(repository.calls, 2);
    });

    test('ignores duplicate payloads until the code changes', () async {
      final repository = QueueRepository(<LookupResult>[
        const ProductNotFound(),
        const ProductNotFound(),
      ]);
      final viewModel = ScannerViewModel(repository);

      await viewModel.onQrDetected('PHN-001');
      await viewModel.onQrDetected('PHN-001');
      await viewModel.onQrDetected('PHN-002');

      expect(repository.calls, 2);
    });

    test('reset allows the same payload again', () async {
      final repository = QueueRepository(<LookupResult>[
        const ProductNotFound(),
        const ProductNotFound(),
      ]);
      final viewModel = ScannerViewModel(repository);

      await viewModel.onQrDetected('PHN-001');
      viewModel.reset();
      await viewModel.onQrDetected('PHN-001');

      expect(repository.calls, 2);
    });

    test('retry repeats the last lookup', () async {
      final repository = QueueRepository(<LookupResult>[
        const ProductLookupFailure(LookupFailureType.timeout),
        const ProductFound(sampleProduct),
      ]);
      final viewModel = ScannerViewModel(repository);

      await viewModel.onQrDetected('PHN-001');
      expect(viewModel.state, isA<ErrorState>());

      await viewModel.retry();

      expect(viewModel.state, isA<SuccessState>());
      expect(repository.calls, 2);
    });

    test('retry without a payload resets', () async {
      final viewModel = ScannerViewModel(QueueRepository(<LookupResult>[]));

      await viewModel.retry();

      expect(viewModel.state, isA<ScanningState>());
    });

    test('raises state changes in order', () async {
      final repository = QueueRepository(<LookupResult>[
        const ProductFound(sampleProduct),
      ]);
      final viewModel = ScannerViewModel(repository);
      final states = <ScanUiState>[];
      viewModel.addListener(() {
        states.add(viewModel.state);
      });

      await viewModel.onQrDetected('PHN-001');

      expect(states, hasLength(2));
      expect(states[0], isA<LoadingState>());
      expect(states[1], isA<SuccessState>());
    });
  });
}
