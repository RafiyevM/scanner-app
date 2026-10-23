import '../models/product.dart';

enum LookupFailureType {
  unauthorized,
  serverUnavailable,
  requestFailed,
  unreachable,
  unexpectedResponse,
  timeout,
  localData,
}

sealed class LookupResult {
  const LookupResult();
}

final class ProductFound extends LookupResult {
  const ProductFound(this.product);

  final Product product;
}

final class ProductOutOfStock extends LookupResult {
  const ProductOutOfStock(this.product);

  final Product product;
}

final class ProductNotFound extends LookupResult {
  const ProductNotFound();
}

final class ProductLookupFailure extends LookupResult {
  const ProductLookupFailure(
    this.type, {
    this.statusCode,
    this.cause,
  });

  final LookupFailureType type;
  final int? statusCode;
  final Object? cause;
}

abstract class ProductRepository {
  Future<LookupResult> findByCode(String code);
}
