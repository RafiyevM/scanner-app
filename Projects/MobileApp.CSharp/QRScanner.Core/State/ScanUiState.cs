using QRScanner.Core.Models;

namespace QRScanner.Core.State;

public abstract record ScanUiState
{
    public sealed record Scanning : ScanUiState;

    public sealed record Loading(string Code) : ScanUiState;

    public sealed record Success(Product Product) : ScanUiState;

    public sealed record OutOfStock(Product Product) : ScanUiState;

    public sealed record NotFound(string Code) : ScanUiState;

    public sealed record Invalid(string Raw, string Reason) : ScanUiState;

    public sealed record Error(string Message, bool Retryable, string? Code = null) : ScanUiState;
}
