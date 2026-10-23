using System.Text.Json;
using QRScanner.Core.Models;

namespace QRScanner.Core.Data;

public sealed class LocalProductRepository : IProductRepository
{
    private readonly IProductStore _store;
    private readonly SemaphoreSlim _mutex = new(1, 1);
    private Dictionary<string, Product>? _cache;

    public LocalProductRepository(IProductStore store) => _store = store;

    public async Task<LookupResult> FindByCodeAsync(
        string code,
        CancellationToken cancellationToken = default)
    {
        var key = Normalize(code);
        if (key.Length == 0)
        {
            return new LookupResult.NotFound();
        }

        try
        {
            var products = await GetProductsAsync(cancellationToken).ConfigureAwait(false);
            if (!products.TryGetValue(key, out var product))
            {
                return new LookupResult.NotFound();
            }

            return product.InStock
                ? new LookupResult.Found(product)
                : new LookupResult.OutOfStock(product);
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception exception)
        {
            return new LookupResult.Failure("Could not read the local product data.", exception);
        }
    }

    private async Task<Dictionary<string, Product>> GetProductsAsync(
        CancellationToken cancellationToken)
    {
        var cache = _cache;
        if (cache is not null)
        {
            return cache;
        }

        await _mutex.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            if (_cache is not null)
            {
                return _cache;
            }

            var json = await _store.ReadAsync(cancellationToken).ConfigureAwait(false);
            var parsed = Parse(json);
            _cache = parsed;
            return parsed;
        }
        finally
        {
            _mutex.Release();
        }
    }

    private static Dictionary<string, Product> Parse(string json)
    {
        using var document = JsonDocument.Parse(json);
        if (!document.RootElement.TryGetProperty("products", out var productsElement) ||
            productsElement.ValueKind != JsonValueKind.Array)
        {
            return [];
        }

        var products = new Dictionary<string, Product>(StringComparer.Ordinal);
        foreach (var element in productsElement.EnumerateArray())
        {
            if (element.ValueKind != JsonValueKind.Object)
            {
                continue;
            }

            var id = GetString(element, "id").Trim();
            if (id.Length == 0)
            {
                continue;
            }

            var product = new Product(
                Id: id,
                Name: GetString(element, "name"),
                Description: GetString(element, "description"),
                Color: GetString(element, "color"),
                Quantity: GetInt(element, "quantity"),
                Barcode: GetString(element, "barcode").Trim(),
                QrCode: GetString(element, "qrCode"));

            products[Normalize(product.Id)] = product;
            if (product.Barcode.Length > 0)
            {
                products[Normalize(product.Barcode)] = product;
            }
            if (product.QrCode.Length > 0)
            {
                products[Normalize(product.QrCode)] = product;
            }
        }

        return products;
    }

    private static string GetString(JsonElement element, string propertyName) =>
        element.TryGetProperty(propertyName, out var value) &&
        value.ValueKind == JsonValueKind.String
            ? value.GetString() ?? string.Empty
            : string.Empty;

    private static int GetInt(JsonElement element, string propertyName) =>
        element.TryGetProperty(propertyName, out var value) &&
        value.ValueKind == JsonValueKind.Number &&
        value.TryGetInt32(out var number)
            ? number
            : 0;

    private static string Normalize(string value) => value.Trim().ToLowerInvariant();
}
