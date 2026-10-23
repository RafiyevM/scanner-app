enum QrFormat { json, url, plainText }

class QrPayload {
  const QrPayload({
    required this.raw,
    required this.code,
    required this.format,
  });

  final String raw;
  final String code;
  final QrFormat format;
}

sealed class QrParseResult {
  const QrParseResult();
}

final class QrParseSuccess extends QrParseResult {
  const QrParseSuccess(this.payload);

  final QrPayload payload;
}

final class QrParseInvalid extends QrParseResult {
  const QrParseInvalid({required this.raw, required this.reason});

  final String raw;
  final String reason;
}
