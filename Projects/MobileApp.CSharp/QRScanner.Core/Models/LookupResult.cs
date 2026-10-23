namespace QRScanner.Core.Models;

public abstract record LookupResult
{
    public sealed record Found(Product Product) : LookupResult;

    public sealed record OutOfStock(Product Product) : LookupResult;

    public sealed record NotFound : LookupResult;

    public sealed record Failure(string Message, Exception? Cause = null) : LookupResult;
}
