namespace ProductApi;

public sealed record Product(
    string Id,
    string Name,
    string Description,
    string Color,
    int Quantity,
    string Barcode,
    string QrCode)
{
    public bool InStock => Quantity > 0;
}

public sealed record RegisterProductRequest(
    string Code,
    string Name,
    string? Description,
    string? Color,
    int Quantity);
