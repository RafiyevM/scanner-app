import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/product.dart';
import 'phone_identifier.dart';
import 'product_registrar.dart';
import 'product_repository.dart';

/// Provisional remote contract: GET {baseUrl}products/{code}.
/// Replace this implementation once the real API contract is known.
class RemoteProductRepository
    implements ProductRepository, ProductRegistrar, PhoneIdentifier {
  RemoteProductRepository({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  @override
  Future<LookupResult> findByCode(String code) async {
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final uri = Uri.parse(
      '${normalizedBase}products/${Uri.encodeComponent(code)}',
    );

    try {
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 20));

      if (response.statusCode == 404) {
        return const ProductNotFound();
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        return const ProductLookupFailure(LookupFailureType.unauthorized);
      }
      if (response.statusCode >= 500 && response.statusCode <= 599) {
        return const ProductLookupFailure(
          LookupFailureType.serverUnavailable,
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return ProductLookupFailure(
          LookupFailureType.requestFailed,
          statusCode: response.statusCode,
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const ProductLookupFailure(
          LookupFailureType.unexpectedResponse,
        );
      }

      final product = Product.fromJson(decoded);
      if (product.id.isEmpty) {
        return const ProductLookupFailure(
          LookupFailureType.unexpectedResponse,
        );
      }
      return product.inStock
          ? ProductFound(product)
          : ProductOutOfStock(product);
    } on TimeoutException {
      return const ProductLookupFailure(LookupFailureType.timeout);
    } on http.ClientException catch (error) {
      return ProductLookupFailure(
        LookupFailureType.unreachable,
        cause: error,
      );
    } on FormatException catch (error) {
      return ProductLookupFailure(
        LookupFailureType.unexpectedResponse,
        cause: error,
      );
    } catch (error) {
      return ProductLookupFailure(
        LookupFailureType.unexpectedResponse,
        cause: error,
      );
    }
  }

  @override
  Future<RegisterResult> register(NewProduct product) async {
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final uri = Uri.parse('${normalizedBase}products/register');

    try {
      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'code': product.code,
              'name': product.name,
              'description': product.description,
              'color': product.color,
              'quantity': product.quantity,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 409) {
        return const RegisterDuplicate();
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        return const RegisterFailure(LookupFailureType.unauthorized);
      }
      if (response.statusCode >= 500 && response.statusCode <= 599) {
        return const RegisterFailure(LookupFailureType.serverUnavailable);
      }
      if (response.statusCode != 201 && response.statusCode != 200) {
        return RegisterFailure(
          LookupFailureType.requestFailed,
          statusCode: response.statusCode,
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const RegisterFailure(LookupFailureType.unexpectedResponse);
      }
      final saved = Product.fromJson(decoded);
      if (saved.id.isEmpty) {
        return const RegisterFailure(LookupFailureType.unexpectedResponse);
      }
      return RegisterSuccess(saved);
    } on TimeoutException {
      return const RegisterFailure(LookupFailureType.timeout);
    } on http.ClientException {
      return const RegisterFailure(LookupFailureType.unreachable);
    } catch (_) {
      return const RegisterFailure(LookupFailureType.unexpectedResponse);
    }
  }

  @override
  Future<IdentifyResult> identify(Uint8List jpeg) async {
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final uri = Uri.parse('${normalizedBase}identify');

    try {
      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'image': base64Encode(jpeg)}),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 503) {
        return const IdentifyNotConfigured();
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        return const IdentifyFailure(LookupFailureType.unauthorized);
      }
      if (response.statusCode == 504) {
        return const IdentifyFailure(LookupFailureType.timeout);
      }
      if (response.statusCode >= 500 && response.statusCode <= 599) {
        return const IdentifyFailure(LookupFailureType.serverUnavailable);
      }
      if (response.statusCode != 200) {
        return const IdentifyFailure(LookupFailureType.requestFailed);
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const IdentifyFailure(LookupFailureType.unexpectedResponse);
      }
      if (decoded['isPhone'] != true) {
        return const IdentifyNotPhone();
      }

      List<Product> products(Object? raw) => <Product>[
            if (raw is List)
              for (final item in raw)
                if (item is Map<String, dynamic>) Product.fromJson(item),
          ];
      final matches = products(decoded['matches']);
      final modelMatches = products(decoded['modelMatches']);
      final confidence = decoded['confidence'];

      return IdentifySuccess(
        brand: decoded['brand']?.toString() ?? '',
        model: decoded['model']?.toString() ?? '',
        color: decoded['color']?.toString() ?? '',
        confidence: confidence is num ? confidence.toDouble() : 0,
        matches: matches,
        modelMatches: modelMatches.isEmpty ? matches : modelMatches,
      );
    } on TimeoutException {
      return const IdentifyFailure(LookupFailureType.timeout);
    } on http.ClientException {
      return const IdentifyFailure(LookupFailureType.unreachable);
    } catch (_) {
      return const IdentifyFailure(LookupFailureType.unexpectedResponse);
    }
  }

  void dispose() => _client.close();
}
