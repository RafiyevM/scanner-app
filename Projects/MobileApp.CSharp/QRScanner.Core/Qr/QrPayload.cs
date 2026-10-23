namespace QRScanner.Core.Qr;

public sealed record QrPayload(string Raw, string Code, QrFormat Format);
