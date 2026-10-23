using QRScanner.Core.Models;

namespace QRScanner.Core.Data;

public interface IProductRepository
{
    Task<LookupResult> FindByCodeAsync(
        string code,
        CancellationToken cancellationToken = default);
}
