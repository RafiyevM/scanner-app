import '../data/product_repository.dart';
import '../models/product.dart';

sealed class ScanUiState {
  const ScanUiState();
}

final class ScanningState extends ScanUiState {
  const ScanningState();
}

final class LoadingState extends ScanUiState {
  const LoadingState(this.code);

  final String code;
}

final class SuccessState extends ScanUiState {
  const SuccessState(this.product);

  final Product product;
}

final class OutOfStockState extends ScanUiState {
  const OutOfStockState(this.product);

  final Product product;
}

final class NotFoundState extends ScanUiState {
  const NotFoundState(this.code);

  final String code;
}

final class InvalidState extends ScanUiState {
  const InvalidState({required this.raw, required this.reason});

  final String raw;
  final String reason;
}

final class ErrorState extends ScanUiState {
  const ErrorState({
    required this.failureType,
    required this.retryable,
    this.statusCode,
    this.code,
  });

  final LookupFailureType failureType;
  final bool retryable;
  final int? statusCode;
  final String? code;
}
