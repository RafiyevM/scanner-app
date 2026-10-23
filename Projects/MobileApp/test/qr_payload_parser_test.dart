import 'package:flutter_test/flutter_test.dart';
import 'package:qr_scanner/src/qr/qr_payload.dart';
import 'package:qr_scanner/src/qr/qr_payload_parser.dart';

QrPayload success(String raw) {
  final result = QrPayloadParser.parse(raw);
  expect(result, isA<QrParseSuccess>(), reason: 'Expected success for: $raw');
  return (result as QrParseSuccess).payload;
}

QrParseInvalid invalid(String raw) {
  final result = QrPayloadParser.parse(raw);
  expect(result, isA<QrParseInvalid>(), reason: 'Expected invalid for: $raw');
  return result as QrParseInvalid;
}

void main() {
  group('QrPayloadParser', () {
    test('plain identifier is accepted', () {
      final payload = success('SAMPLE-001');
      expect(payload.code, 'SAMPLE-001');
      expect(payload.format, QrFormat.plainText);
    });

    test('surrounding whitespace is trimmed', () {
      expect(success('  QR-1001\n').code, 'QR-1001');
    });

    test('json id is accepted', () {
      final payload = success('{"id":"QR-1001"}');
      expect(payload.code, 'QR-1001');
      expect(payload.format, QrFormat.json);
    });

    test('json recordId is accepted', () {
      expect(success('{"recordId":"QR-1002"}').code, 'QR-1002');
    });

    test('json numeric record_id is accepted', () {
      expect(success('{"record_id":1003}').code, '1003');
    });

    test('json code is accepted when id is absent', () {
      expect(success('{"code":"ABC-1"}').code, 'ABC-1');
    });

    test('malformed json is rejected', () {
      expect(
        invalid('{"id":').reason.toLowerCase(),
        contains('malformed'),
      );
    });

    test('json without identifier is rejected', () {
      expect(invalid('{"name":"Blue Widget"}').reason, contains('identifier'));
    });

    test('json array is rejected', () {
      expect(invalid('[{"id":"QR-1001"}]').reason, contains('object'));
    });

    test('url query identifier is accepted', () {
      final payload = success('https://example.com/scan?id=QR-1001');
      expect(payload.code, 'QR-1001');
      expect(payload.format, QrFormat.url);
    });

    test('url encoded identifier is decoded', () {
      expect(
          success('https://example.com/scan?code=QR%2D1001').code, 'QR-1001');
    });

    test('url path identifier is accepted', () {
      expect(success('https://example.com/records/QR-1002').code, 'QR-1002');
    });

    test('url without identifier is rejected', () {
      expect(invalid('https://example.com/').reason, contains('identifier'));
    });

    test('unsupported scheme is rejected', () {
      expect(
          invalid('ftp://example.com/QR-1001').reason, contains('identifier'));
    });

    test('empty content is rejected', () {
      expect(invalid('   ').reason.toLowerCase(), contains('empty'));
    });

    test('control characters are rejected', () {
      expect(
        invalid('SAMPLE\u0000-001').reason.toLowerCase(),
        contains('control'),
      );
    });

    test('oversized content is rejected', () {
      expect(
        invalid('A' * 2000).reason.toLowerCase(),
        contains('too much'),
      );
    });

    test('plain content with spaces is rejected', () {
      expect(invalid('not a code').reason, contains('identifier'));
    });
  });
}
