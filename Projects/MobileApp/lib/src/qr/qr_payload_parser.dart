import 'dart:convert';

import 'qr_payload.dart';

/// Parses QR content without assuming a single business format.
///
/// Accepted, in order: a JSON object with an identifier field, an HTTP(S) URL
/// carrying an identifier, or a plain identifier.
class QrPayloadParser {
  static const int _maxLength = 1024;
  static const int _maxCodeLength = 128;
  static const List<String> _idKeys = <String>[
    'id',
    'recordId',
    'record_id',
    'code',
    'qr',
  ];

  static final RegExp _plainCode =
      RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$');

  static QrParseResult parse(String raw) {
    if (raw.trim().isEmpty) {
      return QrParseInvalid(raw: raw, reason: 'The QR code is empty.');
    }
    if (raw.length > _maxLength) {
      return QrParseInvalid(
        raw: raw,
        reason: 'The QR code contains too much data.',
      );
    }

    var trimmed = raw.trim();
    if (trimmed.startsWith('﻿')) {
      trimmed = trimmed.substring(1);
    }
    if (trimmed.isEmpty) {
      return QrParseInvalid(raw: raw, reason: 'The QR code is empty.');
    }
    if (trimmed.runes.any((int rune) => rune < 0x20 || rune == 0x7F)) {
      return QrParseInvalid(
        raw: raw,
        reason: 'The QR code contains unsupported control characters.',
      );
    }

    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      return _parseJson(raw, trimmed);
    }

    final lower = trimmed.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return _parseUrl(raw, trimmed);
    }

    if (_isValidCode(trimmed)) {
      return QrParseSuccess(
        QrPayload(raw: raw, code: trimmed, format: QrFormat.plainText),
      );
    }

    return QrParseInvalid(
      raw: raw,
      reason: 'The QR code does not contain a supported record identifier.',
    );
  }

  static QrParseResult _parseJson(String raw, String content) {
    dynamic decoded;
    try {
      decoded = jsonDecode(content);
    } on FormatException {
      return QrParseInvalid(
        raw: raw,
        reason: 'The QR code contains malformed JSON.',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      return QrParseInvalid(
        raw: raw,
        reason: 'The QR code JSON must be an object.',
      );
    }

    for (final key in _idKeys) {
      final value = decoded[key];
      String? code;
      if (value is String) {
        code = value.trim();
      } else if (value is num) {
        code = value.toString();
      }
      if (code == null || code.isEmpty) {
        continue;
      }
      return _isValidCode(code)
          ? QrParseSuccess(
              QrPayload(raw: raw, code: code, format: QrFormat.json),
            )
          : QrParseInvalid(
              raw: raw,
              reason: 'The QR code contains an invalid record identifier.',
            );
    }

    return QrParseInvalid(
      raw: raw,
      reason: 'The QR code JSON does not contain a record identifier.',
    );
  }

  static QrParseResult _parseUrl(String raw, String content) {
    Uri uri;
    try {
      uri = Uri.parse(content);
    } on FormatException {
      return QrParseInvalid(
        raw: raw,
        reason: 'The QR code contains a malformed URL.',
      );
    }

    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return QrParseInvalid(
        raw: raw,
        reason: 'The QR code does not contain a supported record identifier.',
      );
    }

    for (final key in _idKeys) {
      final values = uri.queryParametersAll[key];
      if (values == null) {
        continue;
      }
      for (final value in values) {
        final code = value.trim();
        if (code.isNotEmpty && _isValidCode(code)) {
          return QrParseSuccess(
            QrPayload(raw: raw, code: code, format: QrFormat.url),
          );
        }
      }
    }

    final path = uri.path.replaceAll(RegExp(r'/+$'), '');
    final lastSegment =
        path.contains('/') ? path.substring(path.lastIndexOf('/') + 1) : path;

    if (_isValidCode(lastSegment)) {
      return QrParseSuccess(
        QrPayload(raw: raw, code: lastSegment, format: QrFormat.url),
      );
    }

    return QrParseInvalid(
      raw: raw,
      reason: 'The QR code URL does not contain a valid record identifier.',
    );
  }

  static bool _isValidCode(String value) {
    return value.isNotEmpty &&
        value.length <= _maxCodeLength &&
        _plainCode.hasMatch(value);
  }
}
