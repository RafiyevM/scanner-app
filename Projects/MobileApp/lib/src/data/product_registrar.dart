import '../models/product.dart';
import 'product_repository.dart';

class NewProduct {
  const NewProduct({
    required this.code,
    required this.name,
    this.description = '',
    this.color = '',
    this.quantity = 1,
  });

  final String code;
  final String name;
  final String description;
  final String color;
  final int quantity;
}

sealed class RegisterResult {
  const RegisterResult();
}

final class RegisterSuccess extends RegisterResult {
  const RegisterSuccess(this.product);

  final Product product;
}

final class RegisterDuplicate extends RegisterResult {
  const RegisterDuplicate();
}

final class RegisterFailure extends RegisterResult {
  const RegisterFailure(this.type, {this.statusCode});

  final LookupFailureType type;
  final int? statusCode;
}

abstract interface class ProductRegistrar {
  Future<RegisterResult> register(NewProduct product);
}
