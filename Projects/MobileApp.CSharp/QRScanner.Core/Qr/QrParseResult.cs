namespace QRScanner.Core.Qr;

public abstract record QrParseResult
{
    public sealed record Success(QrPayload Payload) : QrParseResult;

    public sealed record Invalid(string Raw, string Reason) : QrParseResult;
}
