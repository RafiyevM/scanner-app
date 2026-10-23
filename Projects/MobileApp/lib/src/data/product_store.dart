import 'package:flutter/services.dart';

abstract class ProductStore {
  Future<String> read();
}

class AssetProductStore implements ProductStore {
  const AssetProductStore();

  @override
  Future<String> read() => rootBundle.loadString('assets/products.json');
}
