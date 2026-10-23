namespace QRScanner.Core.Data;

public interface IProductStore
{
    Task<string> ReadAsync(CancellationToken cancellationToken = default);
}
