import 'dart:convert';

import '../models/product.dart';
import 'product_repository.dart';
import 'product_store.dart';

class LocalProductRepository implements ProductRepository {
  LocalProductRepository(this._store);

  final ProductStore _store;
  Map<String, Product>? _cache;

  @override
  Future<LookupResult> findByCode(String code) async {
    final key = code.trim().toLowerCase();
    if (key.isEmpty) {
      return const ProductNotFound();
    }

    try {
      var products = _cache;
      if (products == null) {
        products = await _load();
        _cache = products;
      }
      final product = products[key];
      if (product == null) {
        return const ProductNotFound();
      }
      return product.inStock
          ? ProductFound(product)
          : ProductOutOfStock(product);
    } catch (error) {
      return ProductLookupFailure(
        LookupFailureType.localData,
        cause: error,
      );
    }
  }

  Future<Map<String, Product>> _load() async {
    final text = await _store.read();
    final decoded = jsonDecode(text);
    final products = <String, Product>{};

    if (decoded is! Map<String, dynamic>) {
      return products;
    }
    final list = decoded['products'];
    if (list is! List) {
      return products;
    }

    for (final item in list) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final product = Product.fromJson(item);
      if (product.id.isEmpty) {
        continue;
      }
      products[product.id.toLowerCase()] = product;
      if (product.barcode.isNotEmpty) {
        products[product.barcode.toLowerCase()] = product;
      }
      if (product.qrCode.isNotEmpty) {
        products[product.qrCode.toLowerCase()] = product;
      }
    }

    return products;
  }
}
