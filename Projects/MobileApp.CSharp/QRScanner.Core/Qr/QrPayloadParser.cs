using System.Text.Json;
using System.Text.RegularExpressions;

namespace QRScanner.Core.Qr;

/// <summary>
/// Parses QR content without assuming a single business format.
/// Accepted, in order: JSON with an identifier field, an HTTP(S) URL carrying
/// an identifier, or a plain identifier.
/// </summary>
public static class QrPayloadParser
{
    private const int MaxLength = 1024;
    private const int MaxCodeLength = 128;

    private static readonly string[] IdKeys = ["id", "recordId", "record_id", "code", "qr"];

    private static readonly Regex PlainCode = new(
        "^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$",
        RegexOptions.Compiled | RegexOptions.CultureInvariant);

    public static QrParseResult Parse(string raw)
    {
        if (string.IsNullOrWhiteSpace(raw))
        {
            return new QrParseResult.Invalid(raw, "The QR code is empty.");
        }

        if (raw.Length > MaxLength)
        {
            return new QrParseResult.Invalid(raw, "The QR code contains too much data.");
        }

        var trimmed = raw.Trim().TrimStart('﻿');
        if (trimmed.Length == 0)
        {
            return new QrParseResult.Invalid(raw, "The QR code is empty.");
        }

        if (trimmed.Any(c => char.IsControl(c)))
        {
            return new QrParseResult.Invalid(
                raw,
                "The QR code contains unsupported control characters.");
        }

        if (trimmed.StartsWith('{') || trimmed.StartsWith('['))
        {
            return ParseJson(raw, trimmed);
        }

        if (trimmed.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
            trimmed.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
        {
            return ParseUrl(raw, trimmed);
        }

        if (IsValidCode(trimmed))
        {
            return new QrParseResult.Success(
                new QrPayload(raw, trimmed, QrFormat.PlainText));
        }

        return new QrParseResult.Invalid(
            raw,
            "The QR code does not contain a supported record identifier.");
    }

    private static QrParseResult ParseJson(string raw, string content)
    {
        JsonDocument document;
        try
        {
            document = JsonDocument.Parse(content);
        }
        catch (JsonException)
        {
            return new QrParseResult.Invalid(raw, "The QR code contains malformed JSON.");
        }

        using (document)
        {
            var root = document.RootElement;
            if (root.ValueKind != JsonValueKind.Object)
            {
                return new QrParseResult.Invalid(raw, "The QR code JSON must be an object.");
            }

            foreach (var key in IdKeys)
            {
                if (!root.TryGetProperty(key, out var element))
                {
                    continue;
                }

                var value = element.ValueKind switch
                {
                    JsonValueKind.String => element.GetString(),
                    JsonValueKind.Number => element.GetRawText(),
                    _ => null,
                };

                if (string.IsNullOrWhiteSpace(value))
                {
                    continue;
                }

                var code = value.Trim();
                return IsValidCode(code)
                    ? new QrParseResult.Success(new QrPayload(raw, code, QrFormat.Json))
                    : new QrParseResult.Invalid(
                        raw,
                        "The QR code contains an invalid record identifier.");
            }
        }

        return new QrParseResult.Invalid(
            raw,
            "The QR code JSON does not contain a record identifier.");
    }

    private static QrParseResult ParseUrl(string raw, string content)
    {
        if (!Uri.TryCreate(content, UriKind.Absolute, out var uri))
        {
            return new QrParseResult.Invalid(raw, "The QR code contains a malformed URL.");
        }

        if (uri.Scheme != Uri.UriSchemeHttp && uri.Scheme != Uri.UriSchemeHttps)
        {
            return new QrParseResult.Invalid(
                raw,
                "The QR code does not contain a supported record identifier.");
        }

        var query = ParseQuery(uri.Query);
        foreach (var key in IdKeys)
        {
            if (!query.TryGetValue(key, out var values))
            {
                continue;
            }

            var value = values
                .Select(candidate => candidate.Trim())
                .FirstOrDefault(candidate => candidate.Length > 0);

            if (value is not null && IsValidCode(value))
            {
                return new QrParseResult.Success(new QrPayload(raw, value, QrFormat.Url));
            }
        }

        var path = uri.AbsolutePath.TrimEnd('/');
        var lastSegment = path[(path.LastIndexOf('/') + 1)..].Trim();

        if (IsValidCode(lastSegment))
        {
            return new QrParseResult.Success(new QrPayload(raw, lastSegment, QrFormat.Url));
        }

        return new QrParseResult.Invalid(
            raw,
            "The QR code URL does not contain a valid record identifier.");
    }

    private static Dictionary<string, List<string>> ParseQuery(string? rawQuery)
    {
        var result = new Dictionary<string, List<string>>(StringComparer.OrdinalIgnoreCase);
        if (string.IsNullOrWhiteSpace(rawQuery))
        {
            return result;
        }

        var query = rawQuery.TrimStart('?');
        foreach (var part in query.Split('&', StringSplitOptions.RemoveEmptyEntries))
        {
            var separator = part.IndexOf('=');
            var key = Decode(separator >= 0 ? part[..separator] : part);
            var value = separator >= 0 ? Decode(part[(separator + 1)..]) : string.Empty;

            if (!result.TryGetValue(key, out var values))
            {
                values = [];
                result[key] = values;
            }

            values.Add(value);
        }

        return result;
    }

    private static string Decode(string value)
    {
        try
        {
            return Uri.UnescapeDataString(value.Replace("+", " "));
        }
        catch (UriFormatException)
        {
            return value;
        }
    }

    private static bool IsValidCode(string value) =>
        value.Length is >= 1 and <= MaxCodeLength && PlainCode.IsMatch(value);
}
