namespace QRScanner.Core.Models;

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
