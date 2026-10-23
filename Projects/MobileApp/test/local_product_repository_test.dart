import 'package:flutter_test/flutter_test.dart';
import 'package:qr_scanner/src/data/local_product_repository.dart';
import 'package:qr_scanner/src/data/product_repository.dart';
import 'package:qr_scanner/src/data/product_store.dart';

class MemoryStore implements ProductStore {
  MemoryStore(this.content);

  final String content;

  @override
  Future<String> read() async => content;
}

const String products = r'''
{
  "products": [
    {
      "id": "PHN-001",
      "name": "Aurora X1",
      "description": "A phone.",
      "color": "Midnight Black",
      "quantity": 12,
      "barcode": "2000000000015",
      "qrCode": "{\"id\":\"PHN-001\",\"type\":\"phone\"}"
    },
    {
      "id": "PHN-003",
      "name": "Pulse 7",
      "description": "An unavailable phone.",
      "color": "Arctic White",
      "quantity": 0,
      "barcode": "2000000000039",
      "qrCode": "{\"id\":\"PHN-003\",\"type\":\"phone\"}"
    }
  ]
}
''';

void main() {
  group('LocalProductRepository', () {
    test('finds a product by id ignoring case', () async {
      final repository = LocalProductRepository(MemoryStore(products));

      final result = await repository.findByCode('phn-001');

      expect(result, isA<ProductFound>());
      expect((result as ProductFound).product.name, 'Aurora X1');
    });

    test('finds a product by barcode', () async {
      final repository = LocalProductRepository(MemoryStore(products));

      final result = await repository.findByCode('2000000000015');

      expect(result, isA<ProductFound>());
      expect((result as ProductFound).product.id, 'PHN-001');
    });

    test('finds a product by its QR payload', () async {
      final repository = LocalProductRepository(MemoryStore(products));

      final result = await repository.findByCode(
        '{"id":"PHN-001","type":"phone"}',
      );

      expect(result, isA<ProductFound>());
      expect((result as ProductFound).product.color, 'Midnight Black');
    });

    test('reports an out-of-stock product', () async {
      final repository = LocalProductRepository(MemoryStore(products));

      final result = await repository.findByCode('PHN-003');

      expect(result, isA<ProductOutOfStock>());
      expect((result as ProductOutOfStock).product.name, 'Pulse 7');
      expect(result.product.inStock, isFalse);
    });

    test('returns not found for an unknown code', () async {
      final repository = LocalProductRepository(MemoryStore(products));

      expect(await repository.findByCode('UNKNOWN'), isA<ProductNotFound>());
    });

    test('returns not found for a blank code', () async {
      final repository = LocalProductRepository(MemoryStore(products));

      expect(await repository.findByCode('   '), isA<ProductNotFound>());
    });

    test('returns failure for malformed data', () async {
      final repository = LocalProductRepository(MemoryStore('{not json'));

      expect(
        await repository.findByCode('PHN-001'),
        isA<ProductLookupFailure>(),
      );
    });
  });
}
