using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using QRScanner.Core.Models;

namespace QRScanner.Core.Data;

/// <summary>
/// Provisional remote contract: GET {baseUrl}products/{code}.
/// Replace this implementation once the real API contract is known.
/// </summary>
public sealed class RemoteProductRepository : IProductRepository
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
    };

    private readonly HttpClient _httpClient;

    public RemoteProductRepository(HttpClient httpClient)
    {
        _httpClient = httpClient;
        if (_httpClient.BaseAddress is null)
        {
            throw new ArgumentException(
                "HttpClient.BaseAddress must be configured.",
                nameof(httpClient));
        }
    }

    public async Task<LookupResult> FindByCodeAsync(
        string code,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var path = $"products/{Uri.EscapeDataString(code)}";
            using var response = await _httpClient
                .GetAsync(path, cancellationToken)
                .ConfigureAwait(false);

            if (response.StatusCode == HttpStatusCode.NotFound)
            {
                return new LookupResult.NotFound();
            }

            if (!response.IsSuccessStatusCode)
            {
                return new LookupResult.Failure(MessageFor((int)response.StatusCode));
            }

            var dto = await response.Content
                .ReadFromJsonAsync<ProductDto>(JsonOptions, cancellationToken)
                .ConfigureAwait(false);

            if (dto is null || string.IsNullOrWhiteSpace(dto.Id))
            {
                return new LookupResult.Failure("The server returned an unexpected response.");
            }

            var product = dto.ToProduct();
            return product.InStock
                ? new LookupResult.Found(product)
                : new LookupResult.OutOfStock(product);
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (HttpRequestException exception)
        {
            return new LookupResult.Failure(
                "Could not reach the server. Check your connection and try again.",
                exception);
        }
        catch (JsonException exception)
        {
            return new LookupResult.Failure(
                "The server returned an unexpected response.",
                exception);
        }
        catch (NotSupportedException exception)
        {
            return new LookupResult.Failure(
                "The server returned an unexpected response.",
                exception);
        }
    }

    private static string MessageFor(int statusCode) => statusCode switch
    {
        401 or 403 => "You are not authorized to view this product.",
        >= 500 and <= 599 => "The server is unavailable. Try again later.",
        _ => $"The request failed (HTTP {statusCode}).",
    };
}

internal sealed class ProductDto
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Color { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public string Barcode { get; set; } = string.Empty;
    public string QrCode { get; set; } = string.Empty;

    public Product ToProduct() =>
        new(Id, Name, Description, Color, Quantity, Barcode, QrCode);
}
