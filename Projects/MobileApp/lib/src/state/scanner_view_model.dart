import 'package:flutter/foundation.dart';

import '../data/product_repository.dart';
import '../models/product.dart';
import '../qr/qr_payload.dart';
import '../qr/qr_payload_parser.dart';
import 'scan_ui_state.dart';

class ScannerViewModel extends ChangeNotifier {
  ScannerViewModel(this._repository);

  final ProductRepository _repository;

  ScanUiState _state = const ScanningState();
  ScanUiState get state => _state;

  QrPayload? _lastPayload;
  String? _lastRaw;
  int _generation = 0;
  bool _busy = false;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> onQrDetected(String raw) async {
    if (_busy) {
      return;
    }
    if (_state is LoadingState ||
        _state is SuccessState ||
        _state is OutOfStockState ||
        _state is ErrorState) {
      return;
    }
    if (raw == _lastRaw) {
      return;
    }
    _lastRaw = raw;

    final result = QrPayloadParser.parse(raw);
    switch (result) {
      case final QrParseInvalid invalid:
        _lastPayload = null;
        _setState(InvalidState(raw: invalid.raw, reason: invalid.reason));
      case final QrParseSuccess success:
        await _lookup(success.payload);
    }
  }

  Future<void> retry() async {
    final payload = _lastPayload;
    if (payload == null) {
      reset();
      return;
    }
    await _lookup(payload);
  }

  void showRegistered(Product product) {
    _generation++;
    _busy = false;
    _setState(
      product.inStock ? SuccessState(product) : OutOfStockState(product),
    );
  }

  void reset() {
    _generation++;
    _busy = false;
    _lastPayload = null;
    _lastRaw = null;
    _setState(const ScanningState());
  }

  Future<void> _lookup(QrPayload payload) async {
    _lastPayload = payload;
    final generation = ++_generation;
    _busy = true;
    _setState(LoadingState(payload.code));

    LookupResult result;
    try {
      result = await _repository.findByCode(payload.code);
    } catch (error) {
      result = ProductLookupFailure(
        LookupFailureType.unexpectedResponse,
        cause: error,
      );
    }

    if (generation != _generation) {
      return;
    }
    _busy = false;

    switch (result) {
      case final ProductFound found:
        _setState(SuccessState(found.product));
      case final ProductOutOfStock outOfStock:
        _setState(OutOfStockState(outOfStock.product));
      case ProductNotFound():
        _setState(NotFoundState(payload.code));
      case final ProductLookupFailure failure:
        _setState(
          ErrorState(
            failureType: failure.type,
            retryable: true,
            statusCode: failure.statusCode,
            code: payload.code,
          ),
        );
    }
  }

  void _setState(ScanUiState state) {
    if (_disposed) {
      return;
    }
    _state = state;
    notifyListeners();
  }
}
