using QRScanner.Core.Data;
using QRScanner.Core.Models;
using QRScanner.Core.Qr;

namespace QRScanner.Core.State;

public sealed class ScannerViewModel
{
    private readonly IProductRepository _repository;
    private readonly SemaphoreSlim _scanGate = new(1, 1);

    private CancellationTokenSource? _lookupCts;
    private QrPayload? _lastPayload;
    private string? _lastRaw;

    public ScannerViewModel(IProductRepository repository) => _repository = repository;

    public ScanUiState State { get; private set; } = new ScanUiState.Scanning();

    public event EventHandler<ScanUiState>? StateChanged;

    public async Task OnQrDetectedAsync(
        string raw,
        CancellationToken cancellationToken = default)
    {
        if (State is ScanUiState.Loading or ScanUiState.Success or
            ScanUiState.OutOfStock or ScanUiState.Error)
        {
            return;
        }

        if (!await _scanGate.WaitAsync(0, cancellationToken).ConfigureAwait(false))
        {
            return;
        }

        try
        {
            // Ignore the same payload until a different code appears or Reset is called.
            if (raw == _lastRaw)
            {
                return;
            }

            _lastRaw = raw;

            switch (QrPayloadParser.Parse(raw))
            {
                case QrParseResult.Invalid invalid:
                    _lastPayload = null;
                    SetState(new ScanUiState.Invalid(invalid.Raw, invalid.Reason));
                    break;

                case QrParseResult.Success success:
                    await LookupAsync(success.Payload, cancellationToken).ConfigureAwait(false);
                    break;
            }
        }
        finally
        {
            _scanGate.Release();
        }
    }

    public async Task RetryAsync(CancellationToken cancellationToken = default)
    {
        var payload = _lastPayload;
        if (payload is null)
        {
            Reset();
            return;
        }

        await LookupAsync(payload, cancellationToken).ConfigureAwait(false);
    }

    public void Reset()
    {
        _lookupCts?.Cancel();
        _lookupCts?.Dispose();
        _lookupCts = null;
        _lastPayload = null;
        _lastRaw = null;
        SetState(new ScanUiState.Scanning());
    }

    private async Task LookupAsync(QrPayload payload, CancellationToken cancellationToken)
    {
        _lookupCts?.Cancel();
        _lookupCts?.Dispose();
        _lookupCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        var token = _lookupCts.Token;

        _lastPayload = payload;
        SetState(new ScanUiState.Loading(payload.Code));

        try
        {
            var result = await _repository
                .FindByCodeAsync(payload.Code, token)
                .ConfigureAwait(false);

            if (token.IsCancellationRequested)
            {
                return;
            }

            switch (result)
            {
                case LookupResult.Found found:
                    SetState(new ScanUiState.Success(found.Product));
                    break;

                case LookupResult.OutOfStock outOfStock:
                    SetState(new ScanUiState.OutOfStock(outOfStock.Product));
                    break;

                case LookupResult.NotFound:
                    SetState(new ScanUiState.NotFound(payload.Code));
                    break;

                case LookupResult.Failure failure:
                    SetState(new ScanUiState.Error(failure.Message, true, payload.Code));
                    break;
            }
        }
        catch (OperationCanceledException)
        {
            // Reset or a newer lookup superseded this one.
        }
    }

    private void SetState(ScanUiState state)
    {
        State = state;
        StateChanged?.Invoke(this, state);
    }
}
