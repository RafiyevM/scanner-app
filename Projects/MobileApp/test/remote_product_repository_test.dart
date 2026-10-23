import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qr_scanner/src/data/phone_identifier.dart';
import 'package:qr_scanner/src/data/product_registrar.dart';
import 'package:qr_scanner/src/data/product_repository.dart';
import 'package:qr_scanner/src/data/remote_product_repository.dart';

RemoteProductRepository repositoryFor(MockClient client) {
  return RemoteProductRepository(
    baseUrl: 'http://localhost/',
    client: client,
  );
}

const String inStockProduct = '''
{
  "id": "PHN-001",
  "name": "Aurora X1",
  "description": "A phone.",
  "color": "Midnight Black",
  "quantity": 12,
  "barcode": "2000000000015",
  "qrCode": "{\\"id\\":\\"PHN-001\\"}"
}
''';

const String outOfStockProduct = '''
{
  "id": "PHN-003",
  "name": "Pulse 7",
  "description": "An unavailable phone.",
  "color": "Arctic White",
  "quantity": 0,
  "barcode": "2000000000039",
  "qrCode": "{\\"id\\":\\"PHN-003\\"}"
}
''';

void main() {
  group('RemoteProductRepository', () {
    test('maps an in-stock response', () async {
      String? path;
      final client = MockClient((http.Request request) async {
        path = request.url.path;
        return http.Response(
          inStockProduct,
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      });

      final result = await repositoryFor(client).findByCode('PHN-001');

      expect(path, '/products/PHN-001');
      expect(result, isA<ProductFound>());
      expect((result as ProductFound).product.name, 'Aurora X1');
      expect(result.product.color, 'Midnight Black');
    });

    test('maps a zero-quantity response to out of stock', () async {
      final client = MockClient((http.Request request) async {
        return http.Response(
          outOfStockProduct,
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      });

      final result = await repositoryFor(client).findByCode('PHN-003');

      expect(result, isA<ProductOutOfStock>());
      expect((result as ProductOutOfStock).product.id, 'PHN-003');
    });

    test('maps 404 to not found', () async {
      final client = MockClient((http.Request request) async {
        return http.Response('', 404);
      });

      expect(
        await repositoryFor(client).findByCode('UNKNOWN'),
        isA<ProductNotFound>(),
      );
    });

    test('maps 401 to an authorization failure', () async {
      final client = MockClient((http.Request request) async {
        return http.Response('', 401);
      });

      final result = await repositoryFor(client).findByCode('PHN-001');

      expect(result, isA<ProductLookupFailure>());
      expect(
        (result as ProductLookupFailure).type,
        LookupFailureType.unauthorized,
      );
    });

    test('maps 500 to a server failure', () async {
      final client = MockClient((http.Request request) async {
        return http.Response('', 500);
      });

      final result = await repositoryFor(client).findByCode('PHN-001');

      expect(result, isA<ProductLookupFailure>());
      expect(
        (result as ProductLookupFailure).type,
        LookupFailureType.serverUnavailable,
      );
    });

    test('maps malformed json to a failure', () async {
      final client = MockClient((http.Request request) async {
        return http.Response('{"id":', 200);
      });

      expect(
        await repositoryFor(client).findByCode('PHN-001'),
        isA<ProductLookupFailure>(),
      );
    });
  });

  group('RemoteProductRepository.register', () {
    const draft = NewProduct(
      code: '2999999999999',
      name: 'New Phone',
      color: 'Red',
      quantity: 3,
    );

    test('posts the draft and returns the saved product', () async {
      late http.Request seen;
      final client = MockClient((http.Request request) async {
        seen = request;
        return http.Response(inStockProduct, 201);
      });

      final result = await repositoryFor(client).register(draft);

      expect(result, isA<RegisterSuccess>());
      expect((result as RegisterSuccess).product.id, 'PHN-001');
      expect(seen.method, 'POST');
      expect(seen.url.path, '/products/register');
      expect(seen.body, contains('"code":"2999999999999"'));
      expect(seen.body, contains('"quantity":3'));
    });

    test('maps 409 to a duplicate', () async {
      final client = MockClient((_) async => http.Response('{}', 409));

      expect(
        await repositoryFor(client).register(draft),
        isA<RegisterDuplicate>(),
      );
    });

    test('maps 500 to a server failure', () async {
      final client = MockClient((_) async => http.Response('', 500));

      final result = await repositoryFor(client).register(draft);

      expect(result, isA<RegisterFailure>());
      expect(
        (result as RegisterFailure).type,
        LookupFailureType.serverUnavailable,
      );
    });

    test('maps malformed json to a failure', () async {
      final client = MockClient((_) async => http.Response('{"id":', 201));

      expect(
        await repositoryFor(client).register(draft),
        isA<RegisterFailure>(),
      );
    });
  });

  group('RemoteProductRepository.identify', () {
    final photo = Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3]);

    test('posts the photo as base64 and maps a match', () async {
      late http.Request seen;
      final client = MockClient((http.Request request) async {
        seen = request;
        return http.Response(
          '{"isPhone":true,"brand":"Apple","model":"iPhone 14",'
          '"confidence":0.93,"matches":[$inStockProduct]}',
          200,
        );
      });

      final result = await repositoryFor(client).identify(photo);

      expect(result, isA<IdentifySuccess>());
      final success = result as IdentifySuccess;
      expect(success.displayName, 'Apple iPhone 14');
      expect(success.confidence, closeTo(0.93, 0.001));
      expect(success.matches.single.id, 'PHN-001');
      expect(seen.method, 'POST');
      expect(seen.url.path, '/identify');
      expect(seen.body, contains('"image":"/9j/4AECAw=="'));
    });

    test('reads the detected color and the same-model products', () async {
      final client = MockClient((_) async => http.Response(
            '{"isPhone":true,"brand":"Apple","model":"iPhone 14 Pro",'
            '"color":"Black","confidence":0.9,"matches":[],'
            '"modelMatches":[$inStockProduct]}',
            200,
          ));

      final result =
          await repositoryFor(client).identify(photo) as IdentifySuccess;

      expect(result.color, 'Black');
      expect(result.matches, isEmpty);
      expect(result.modelMatches.single.id, 'PHN-001');
      expect(result.titleName, 'Apple iPhone 14 Pro, Black');
      expect(result.depotColors, <String>['Midnight Black']);
    });

    test('maps an identified phone that is not in the depot', () async {
      final client = MockClient((_) async => http.Response(
            '{"isPhone":true,"brand":"Apple","model":"iPhone 15",'
            '"confidence":0.8,"matches":[]}',
            200,
          ));

      final result = await repositoryFor(client).identify(photo);

      expect((result as IdentifySuccess).matches, isEmpty);
    });

    test('maps a picture without a phone', () async {
      final client = MockClient((_) async => http.Response(
            '{"isPhone":false,"brand":"","model":"","confidence":0.9,'
            '"matches":[]}',
            200,
          ));

      expect(
        await repositoryFor(client).identify(photo),
        isA<IdentifyNotPhone>(),
      );
    });

    test('maps 503 to not configured', () async {
      final client = MockClient((_) async => http.Response('{}', 503));

      expect(
        await repositoryFor(client).identify(photo),
        isA<IdentifyNotConfigured>(),
      );
    });

    test('maps 502 to a server failure', () async {
      final client = MockClient((_) async => http.Response('{}', 502));

      final result = await repositoryFor(client).identify(photo);

      expect(
        (result as IdentifyFailure).type,
        LookupFailureType.serverUnavailable,
      );
    });

    test('maps malformed json to a failure', () async {
      final client = MockClient((_) async => http.Response('{"x":', 200));

      expect(
        await repositoryFor(client).identify(photo),
        isA<IdentifyFailure>(),
      );
    });
  });
}
