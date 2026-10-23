import 'dart:typed_data';

import '../models/product.dart';
import 'product_repository.dart';

sealed class IdentifyResult {
  const IdentifyResult();
}

final class IdentifySuccess extends IdentifyResult {
  const IdentifySuccess({
    required this.brand,
    required this.model,
    required this.confidence,
    required this.matches,
    this.color = '',
    this.modelMatches = const <Product>[],
  });

  final String brand;
  final String model;
  final String color;
  final double confidence;
  final List<Product> matches;
  final List<Product> modelMatches;

  String get titleName => color.isEmpty ? displayName : '$displayName, $color';

  List<String> get depotColors => <String>{
        for (final Product product in modelMatches)
          if (product.color.isNotEmpty) product.color,
      }.toList();

  String get displayName {
    final String name = model.isEmpty ? brand : model;
    if (brand.isEmpty || name.toLowerCase().contains(brand.toLowerCase())) {
      return name;
    }
    return '$brand $name';
  }
}

final class IdentifyNotPhone extends IdentifyResult {
  const IdentifyNotPhone();
}

final class IdentifyNotConfigured extends IdentifyResult {
  const IdentifyNotConfigured();
}

final class IdentifyFailure extends IdentifyResult {
  const IdentifyFailure(this.type);

  final LookupFailureType type;
}

abstract interface class PhoneIdentifier {
  Future<IdentifyResult> identify(Uint8List jpeg);
}
