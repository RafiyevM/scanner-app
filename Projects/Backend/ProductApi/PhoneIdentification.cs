using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;

namespace ProductApi;

public sealed record IdentifyRequest(string? Image);

public sealed record VisionAnswer(
    bool IsPhone,
    string Brand,
    string Model,
    string Color,
    double Confidence);

public sealed class VisionOptions
{
    public string? ApiKey { get; init; }
    public string ApiBase { get; init; } = "https://generativelanguage.googleapis.com/v1beta";
    public string Model { get; init; } = "gemini-3.5-flash";

    public bool IsConfigured => !string.IsNullOrWhiteSpace(ApiKey);

    public string Endpoint =>
        $"{ApiBase.TrimEnd('/')}/models/{Uri.EscapeDataString(Model)}:generateContent";

    public static VisionOptions FromEnvironment() => new()
    {
        ApiKey = Environment.GetEnvironmentVariable("GEMINI_API_KEY"),
        ApiBase = Environment.GetEnvironmentVariable("GEMINI_API_BASE")
            ?? "https://generativelanguage.googleapis.com/v1beta",
        Model = Environment.GetEnvironmentVariable("GEMINI_MODEL")
            ?? "gemini-3.5-flash",
    };
}

public static partial class PhoneIdentification
{
    public const int MaxImageBytes = 4 * 1024 * 1024;

    private const string Prompt =
        "You identify smartphones for a warehouse. Look at the image and reply " +
        "with ONLY a JSON object, no other text: " +
        "{\"is_phone\": true or false, \"brand\": string, \"model\": string, " +
        "\"color\": string, \"confidence\": number from 0 to 1}. " +
        "color is the main color of the phone body in plain English, for example " +
        "Black, White, Silver, Purple, Gold, Blue, Green, Pink or Red, or an empty " +
        "string if you cannot tell. " +
        "Use the most specific marketing model name you can read or recognise, " +
        "for example \"iPhone 14 Pro\" or \"Galaxy S23\". If you are unsure " +
        "between models, give your best guess with a lower confidence. If the " +
        "image does not show a smartphone, set is_phone to false and leave " +
        "brand and model empty.";

    public static bool TryDecodeJpeg(string? base64, out byte[] bytes)
    {
        bytes = [];
        if (string.IsNullOrWhiteSpace(base64) || base64.Length > MaxImageBytes * 2)
        {
            return false;
        }

        try
        {
            bytes = Convert.FromBase64String(base64);
        }
        catch (FormatException)
        {
            return false;
        }

        return bytes.Length is > 3 and <= MaxImageBytes
            && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
    }

    public static string BuildRequestBody(byte[] jpeg)
    {
        var payload = new
        {
            contents = new[]
            {
                new
                {
                    parts = new object[]
                    {
                        new
                        {
                            inline_data = new
                            {
                                mime_type = "image/jpeg",
                                data = Convert.ToBase64String(jpeg),
                            },
                        },
                        new { text = Prompt },
                    },
                },
            },
            generationConfig = new
            {
                temperature = 0,
                responseMimeType = "application/json",
            },
        };

        return JsonSerializer.Serialize(payload);
    }

    public static VisionAnswer? ParseAnswer(string responseBody)
    {
        try
        {
            using var response = JsonDocument.Parse(responseBody);
            var text = new StringBuilder();
            var parts = response.RootElement
                .GetProperty("candidates")[0]
                .GetProperty("content")
                .GetProperty("parts");
            foreach (var part in parts.EnumerateArray())
            {
                if (part.TryGetProperty("text", out var value))
                {
                    text.Append(value.GetString());
                }
            }

            var match = JsonObjectPattern().Match(text.ToString());
            if (!match.Success)
            {
                return null;
            }

            using var answer = JsonDocument.Parse(match.Value);
            var root = answer.RootElement;

            var isPhone = root.TryGetProperty("is_phone", out var phone)
                && phone.ValueKind == JsonValueKind.True;
            var brand = ReadString(root, "brand");
            var model = ReadString(root, "model");
            var color = ReadString(root, "color");
            var confidence = root.TryGetProperty("confidence", out var c)
                && c.ValueKind == JsonValueKind.Number
                ? Math.Clamp(c.GetDouble(), 0, 1)
                : 0;

            return new VisionAnswer(isPhone, brand, model, color, confidence);
        }
        catch (Exception exception) when (
            exception is JsonException
                or KeyNotFoundException
                or InvalidOperationException
                or ArgumentOutOfRangeException
                or IndexOutOfRangeException)
        {
            return null;
        }
    }

    public static string Normalize(string value) =>
        NonAlphanumeric().Replace(value.ToLowerInvariant(), string.Empty);

    public static bool ColorMatches(string detected, string depot)
    {
        var a = Normalize(detected);
        var b = Normalize(depot);
        return a.Length > 0 && b.Length > 0 && (a.Contains(b) || b.Contains(a));
    }

    public static string[] MatchKeys(VisionAnswer answer)
    {
        var keys = new List<string>();
        var model = Normalize(answer.Model);
        var full = Normalize(answer.Brand + answer.Model);

        if (model.Length >= 3)
        {
            keys.Add(model);
        }

        if (full.Length >= 3 && !keys.Contains(full))
        {
            keys.Add(full);
        }

        return [.. keys];
    }

    public static async Task<(VisionAnswer? Answer, int Status)> AskAsync(
        HttpClient client,
        VisionOptions options,
        byte[] jpeg,
        CancellationToken cancellationToken)
    {
        using var request = new HttpRequestMessage(HttpMethod.Post, options.Endpoint)
        {
            Content = new StringContent(
                BuildRequestBody(jpeg),
                Encoding.UTF8,
                new MediaTypeHeaderValue("application/json")),
        };
        request.Headers.Add("x-goog-api-key", options.ApiKey);

        using var response = await client.SendAsync(request, cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            return (null, (int)response.StatusCode);
        }

        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        return (ParseAnswer(body), 200);
    }

    private static string ReadString(JsonElement root, string name) =>
        root.TryGetProperty(name, out var value) && value.ValueKind == JsonValueKind.String
            ? value.GetString()?.Trim() ?? string.Empty
            : string.Empty;

    [GeneratedRegex(@"\{[^{}]*\}", RegexOptions.Singleline)]
    private static partial Regex JsonObjectPattern();

    [GeneratedRegex("[^a-z0-9]")]
    private static partial Regex NonAlphanumeric();
}
