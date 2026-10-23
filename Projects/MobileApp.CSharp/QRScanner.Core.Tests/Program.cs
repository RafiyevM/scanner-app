using System.Net;
using System.Text;
using QRScanner.Core.Data;
using QRScanner.Core.Models;
using QRScanner.Core.Qr;
using QRScanner.Core.State;

var tests = new List<(string Name, Func<Task> Run)>();

void Test(string name, Func<Task> run) => tests.Add((name, run));

void TestSync(string name, Action run) =>
    tests.Add((name, () =>
    {
        run();
        return Task.CompletedTask;
    }));

void Check(bool condition, string message)
{
    if (!condition)
    {
        throw new InvalidOperationException(message);
    }
}

var sampleProduct = new Product(
    "PHN-001",
    "Aurora X1",
    "A phone.",
    "Midnight Black",
    12,
    "2000000000015",
    """{"id":"PHN-001","type":"phone"}""");

var outOfStockProduct = new Product(
    "PHN-003",
    "Pulse 7",
    "An unavailable phone.",
    "Arctic White",
    0,
    "2000000000039",
    """{"id":"PHN-003","type":"phone"}""");

const string productJson = """
    {
      "products": [
        {
          "id": "PHN-001",
          "name": "Aurora X1",
          "description": "A phone.",
          "color": "Midnight Black",
          "quantity": 12,
          "barcode": "2000000000015",
          "qrCode": "{\"id\":\"PHN-001\",\"type\":\"phone\"}"
        },
        {
          "id": "PHN-003",
          "name": "Pulse 7",
          "description": "An unavailable phone.",
          "color": "Arctic White",
          "quantity": 0,
          "barcode": "2000000000039",
          "qrCode": "{\"id\":\"PHN-003\",\"type\":\"phone\"}"
        }
      ]
    }
    """;

QrParseResult.Invalid ExpectInvalid(string raw)
{
    var result = QrPayloadParser.Parse(raw);
    Check(result is QrParseResult.Invalid, $"Expected invalid for '{raw}', got {result}");
    return (QrParseResult.Invalid)result;
}

QrPayload ExpectSuccess(string raw)
{
    var result = QrPayloadParser.Parse(raw);
    Check(result is QrParseResult.Success, $"Expected success for '{raw}', got {result}");
    return ((QrParseResult.Success)result).Payload;
}

TestSync("plain identifier is accepted", () =>
{
    var payload = ExpectSuccess("SAMPLE-001");
    Check(payload.Code == "SAMPLE-001", "Unexpected code");
    Check(payload.Format == QrFormat.PlainText, "Unexpected format");
});

TestSync("barcode digits are accepted", () =>
{
    Check(ExpectSuccess("2000000000015").Code == "2000000000015", "Unexpected code");
});

TestSync("surrounding whitespace is trimmed", () =>
{
    Check(ExpectSuccess("  PHN-001\n").Code == "PHN-001", "Whitespace was not trimmed");
});

TestSync("json id is accepted", () =>
{
    var payload = ExpectSuccess("""{"id":"PHN-001"}""");
    Check(payload.Code == "PHN-001", "Unexpected code");
    Check(payload.Format == QrFormat.Json, "Unexpected format");
});

TestSync("json recordId is accepted", () =>
{
    Check(ExpectSuccess("""{"recordId":"PHN-002"}""").Code == "PHN-002", "Unexpected code");
});

TestSync("json numeric record_id is accepted", () =>
{
    Check(ExpectSuccess("""{"record_id":1003}""").Code == "1003", "Unexpected code");
});

TestSync("json code is accepted when id is absent", () =>
{
    Check(ExpectSuccess("""{"code":"ABC-1"}""").Code == "ABC-1", "Unexpected code");
});

TestSync("malformed json is rejected", () =>
{
    Check(
        ExpectInvalid("""{"id":""").Reason.Contains("malformed", StringComparison.OrdinalIgnoreCase),
        "Expected malformed-json reason");
});

TestSync("json without identifier is rejected", () =>
{
    Check(
        ExpectInvalid("""{"name":"Aurora X1"}""").Reason.Contains("identifier"),
        "Expected missing-identifier reason");
});

TestSync("json array is rejected", () =>
{
    Check(
        ExpectInvalid("""[{"id":"PHN-001"}]""").Reason.Contains("object"),
        "Expected object-required reason");
});

TestSync("url query identifier is accepted", () =>
{
    var payload = ExpectSuccess("https://example.com/scan?id=PHN-001");
    Check(payload.Code == "PHN-001", "Unexpected code");
    Check(payload.Format == QrFormat.Url, "Unexpected format");
});

TestSync("url encoded identifier is decoded", () =>
{
    Check(ExpectSuccess("https://example.com/scan?code=PHN%2D001").Code == "PHN-001", "Unexpected code");
});

TestSync("url path identifier is accepted", () =>
{
    Check(ExpectSuccess("https://example.com/products/PHN-002").Code == "PHN-002", "Unexpected code");
});

TestSync("url without identifier is rejected", () =>
{
    Check(
        ExpectInvalid("https://example.com/").Reason.Contains("identifier"),
        "Expected missing-identifier reason");
});

TestSync("unsupported scheme is rejected", () =>
{
    Check(
        ExpectInvalid("ftp://example.com/PHN-001").Reason.Contains("identifier"),
        "Expected unsupported-format reason");
});

TestSync("empty content is rejected", () =>
{
    Check(
        ExpectInvalid("   ").Reason.Contains("empty", StringComparison.OrdinalIgnoreCase),
        "Expected empty reason");
});

TestSync("control characters are rejected", () =>
{
    Check(
        ExpectInvalid("PHN\u0000-001").Reason.Contains("control", StringComparison.OrdinalIgnoreCase),
        "Expected control-character reason");
});

TestSync("oversized content is rejected", () =>
{
    Check(
        ExpectInvalid(new string('A', 2000)).Reason.Contains("too much", StringComparison.OrdinalIgnoreCase),
        "Expected size reason");
});

TestSync("plain content with spaces is rejected", () =>
{
    Check(ExpectInvalid("not a code").Reason.Contains("identifier"), "Expected invalid reason");
});

Test("local repository finds a product by id ignoring case", async () =>
{
    var repository = new LocalProductRepository(new MemoryStore(productJson));
    var result = await repository.FindByCodeAsync("phn-001");

    Check(result is LookupResult.Found, $"Expected found, got {result}");
    Check(((LookupResult.Found)result).Product.Name == "Aurora X1", "Unexpected name");
});

Test("local repository finds a product by barcode", async () =>
{
    var repository = new LocalProductRepository(new MemoryStore(productJson));
    var result = await repository.FindByCodeAsync("2000000000015");

    Check(result is LookupResult.Found, $"Expected found, got {result}");
    Check(((LookupResult.Found)result).Product.Id == "PHN-001", "Unexpected id");
});

Test("local repository finds a product by QR payload", async () =>
{
    var repository = new LocalProductRepository(new MemoryStore(productJson));
    var result = await repository.FindByCodeAsync("""{"id":"PHN-001","type":"phone"}""");

    Check(result is LookupResult.Found, $"Expected found, got {result}");
    Check(((LookupResult.Found)result).Product.Color == "Midnight Black", "Unexpected color");
});

Test("local repository reports out of stock", async () =>
{
    var repository = new LocalProductRepository(new MemoryStore(productJson));
    var result = await repository.FindByCodeAsync("PHN-003");

    Check(result is LookupResult.OutOfStock, $"Expected out of stock, got {result}");
    Check(((LookupResult.OutOfStock)result).Product.Name == "Pulse 7", "Unexpected name");
});

Test("local repository returns not found for an unknown code", async () =>
{
    var repository = new LocalProductRepository(new MemoryStore(productJson));
    Check(await repository.FindByCodeAsync("UNKNOWN") is LookupResult.NotFound, "Expected not found");
});

Test("local repository returns not found for a blank code", async () =>
{
    var repository = new LocalProductRepository(new MemoryStore(productJson));
    Check(await repository.FindByCodeAsync("   ") is LookupResult.NotFound, "Expected not found");
});

Test("local repository returns failure for malformed data", async () =>
{
    var repository = new LocalProductRepository(new MemoryStore("{not json"));
    Check(await repository.FindByCodeAsync("PHN-001") is LookupResult.Failure, "Expected failure");
});

Test("remote repository maps an in-stock response", async () =>
{
    var handler = new StubHandler(
        HttpStatusCode.OK,
        """{"id":"PHN-001","name":"Aurora X1","description":"A phone.","color":"Midnight Black","quantity":12,"barcode":"2000000000015","qrCode":"{\"id\":\"PHN-001\"}"}""");
    var repository = RepositoryFor(handler);

    var result = await repository.FindByCodeAsync("PHN-001");

    Check(handler.LastPath == "/products/PHN-001", $"Unexpected path {handler.LastPath}");
    Check(result is LookupResult.Found, $"Expected found, got {result}");
    Check(((LookupResult.Found)result).Product.Name == "Aurora X1", "Unexpected name");
});

Test("remote repository maps zero quantity to out of stock", async () =>
{
    var handler = new StubHandler(
        HttpStatusCode.OK,
        """{"id":"PHN-003","name":"Pulse 7","description":"An unavailable phone.","color":"Arctic White","quantity":0,"barcode":"2000000000039","qrCode":"{\"id\":\"PHN-003\"}"}""");
    var repository = RepositoryFor(handler);

    var result = await repository.FindByCodeAsync("PHN-003");

    Check(result is LookupResult.OutOfStock, $"Expected out of stock, got {result}");
    Check(((LookupResult.OutOfStock)result).Product.Id == "PHN-003", "Unexpected id");
});

Test("remote repository maps 404 to not found", async () =>
{
    var repository = RepositoryFor(new StubHandler(HttpStatusCode.NotFound, ""));
    Check(await repository.FindByCodeAsync("MISSING") is LookupResult.NotFound, "Expected not found");
});

Test("remote repository maps 500 to a retryable failure", async () =>
{
    var repository = RepositoryFor(new StubHandler(HttpStatusCode.InternalServerError, ""));
    var result = await repository.FindByCodeAsync("PHN-001");

    Check(result is LookupResult.Failure, "Expected failure");
    Check(
        ((LookupResult.Failure)result).Message.Contains("unavailable"),
        "Expected server-unavailable message");
});

Test("remote repository maps 401 to an authorization failure", async () =>
{
    var repository = RepositoryFor(new StubHandler(HttpStatusCode.Unauthorized, ""));
    var result = await repository.FindByCodeAsync("PHN-001");

    Check(result is LookupResult.Failure, "Expected failure");
    Check(
        ((LookupResult.Failure)result).Message.Contains("authorized"),
        "Expected authorization message");
});

Test("remote repository maps malformed json to a failure", async () =>
{
    var repository = RepositoryFor(new StubHandler(HttpStatusCode.OK, """{"id":"""));
    Check(await repository.FindByCodeAsync("PHN-001") is LookupResult.Failure, "Expected failure");
});

Test("view model rejects invalid content without a lookup", async () =>
{
    var repository = new QueueRepository();
    var viewModel = new ScannerViewModel(repository);

    await viewModel.OnQrDetectedAsync("not a valid code");

    Check(viewModel.State is ScanUiState.Invalid, $"Expected invalid, got {viewModel.State}");
    Check(repository.Calls == 0, $"Expected 0 calls, got {repository.Calls}");
});

Test("view model loads an in-stock product", async () =>
{
    var repository = new QueueRepository(new LookupResult.Found(sampleProduct));
    var viewModel = new ScannerViewModel(repository);

    await viewModel.OnQrDetectedAsync("PHN-001");

    Check(viewModel.State is ScanUiState.Success, $"Expected success, got {viewModel.State}");
    Check(repository.Calls == 1, $"Expected 1 call, got {repository.Calls}");
});

Test("view model reports out of stock", async () =>
{
    var repository = new QueueRepository(new LookupResult.OutOfStock(outOfStockProduct));
    var viewModel = new ScannerViewModel(repository);

    await viewModel.OnQrDetectedAsync("PHN-003");

    Check(viewModel.State is ScanUiState.OutOfStock, $"Expected out of stock, got {viewModel.State}");
});

Test("view model reports a missing product", async () =>
{
    var viewModel = new ScannerViewModel(new QueueRepository(new LookupResult.NotFound()));

    await viewModel.OnQrDetectedAsync("UNKNOWN");

    Check(
        viewModel.State is ScanUiState.NotFound notFound && notFound.Code == "UNKNOWN",
        $"Unexpected state {viewModel.State}");
});

Test("view model reports a retryable failure", async () =>
{
    var viewModel = new ScannerViewModel(
        new QueueRepository(new LookupResult.Failure("Server unavailable.")));

    await viewModel.OnQrDetectedAsync("PHN-001");

    Check(
        viewModel.State is ScanUiState.Error { Retryable: true },
        $"Unexpected state {viewModel.State}");
});

Test("view model locks scanning after success", async () =>
{
    var repository = new QueueRepository(new LookupResult.Found(sampleProduct));
    var viewModel = new ScannerViewModel(repository);

    await viewModel.OnQrDetectedAsync("PHN-001");
    await viewModel.OnQrDetectedAsync("PHN-002");

    Check(repository.Calls == 1, $"Expected 1 call, got {repository.Calls}");
});

Test("view model locks scanning after out of stock", async () =>
{
    var repository = new QueueRepository(new LookupResult.OutOfStock(outOfStockProduct));
    var viewModel = new ScannerViewModel(repository);

    await viewModel.OnQrDetectedAsync("PHN-003");
    await viewModel.OnQrDetectedAsync("PHN-002");

    Check(repository.Calls == 1, $"Expected 1 call, got {repository.Calls}");
});

Test("view model reset allows the next scan", async () =>
{
    var repository = new QueueRepository(
        new LookupResult.Found(sampleProduct),
        new LookupResult.Found(sampleProduct with { Id = "PHN-002" }));
    var viewModel = new ScannerViewModel(repository);

    await viewModel.OnQrDetectedAsync("PHN-001");
    viewModel.Reset();
    await viewModel.OnQrDetectedAsync("PHN-002");

    Check(repository.Calls == 2, $"Expected 2 calls, got {repository.Calls}");
});

Test("view model ignores duplicate payloads until the code changes", async () =>
{
    var repository = new QueueRepository(
        new LookupResult.NotFound(),
        new LookupResult.NotFound());
    var viewModel = new ScannerViewModel(repository);

    await viewModel.OnQrDetectedAsync("PHN-001");
    await viewModel.OnQrDetectedAsync("PHN-001");
    await viewModel.OnQrDetectedAsync("PHN-002");

    Check(repository.Calls == 2, $"Expected 2 calls, got {repository.Calls}");
});

Test("view model reset allows the same payload again", async () =>
{
    var repository = new QueueRepository(
        new LookupResult.NotFound(),
        new LookupResult.NotFound());
    var viewModel = new ScannerViewModel(repository);

    await viewModel.OnQrDetectedAsync("PHN-001");
    viewModel.Reset();
    await viewModel.OnQrDetectedAsync("PHN-001");

    Check(repository.Calls == 2, $"Expected 2 calls, got {repository.Calls}");
});

Test("view model retry repeats the last lookup", async () =>
{
    var repository = new QueueRepository(
        new LookupResult.Failure("Temporary failure."),
        new LookupResult.Found(sampleProduct));
    var viewModel = new ScannerViewModel(repository);

    await viewModel.OnQrDetectedAsync("PHN-001");
    Check(viewModel.State is ScanUiState.Error, "Expected error state");

    await viewModel.RetryAsync();

    Check(viewModel.State is ScanUiState.Success, $"Unexpected state {viewModel.State}");
    Check(repository.Calls == 2, $"Expected 2 calls, got {repository.Calls}");
});

Test("view model retry without a payload resets", async () =>
{
    var viewModel = new ScannerViewModel(new QueueRepository());

    await viewModel.RetryAsync();

    Check(viewModel.State is ScanUiState.Scanning, $"Unexpected state {viewModel.State}");
});

Test("view model raises state changes in order", async () =>
{
    var states = new List<ScanUiState>();
    var viewModel = new ScannerViewModel(
        new QueueRepository(new LookupResult.Found(sampleProduct)));
    viewModel.StateChanged += (_, state) => states.Add(state);

    await viewModel.OnQrDetectedAsync("PHN-001");

    Check(states.Count == 2, $"Expected 2 state changes, got {states.Count}");
    Check(states[0] is ScanUiState.Loading, "Expected loading first");
    Check(states[1] is ScanUiState.Success, "Expected success second");
});

var failures = 0;
foreach (var (name, run) in tests)
{
    try
    {
        await run();
        Console.WriteLine($"PASS  {name}");
    }
    catch (Exception exception)
    {
        failures++;
        Console.WriteLine($"FAIL  {name}: {exception.Message}");
    }
}

Console.WriteLine();
Console.WriteLine($"{tests.Count - failures}/{tests.Count} passed");
Environment.ExitCode = failures == 0 ? 0 : 1;

static RemoteProductRepository RepositoryFor(StubHandler handler)
{
    var client = new HttpClient(handler)
    {
        BaseAddress = new Uri("http://localhost/"),
        Timeout = TimeSpan.FromSeconds(5),
    };
    return new RemoteProductRepository(client);
}

sealed class MemoryStore(string content) : IProductStore
{
    public Task<string> ReadAsync(CancellationToken cancellationToken = default) =>
        Task.FromResult(content);
}

sealed class QueueRepository(params LookupResult[] results) : IProductRepository
{
    private readonly Queue<LookupResult> _results = new(results);

    public int Calls { get; private set; }

    public Task<LookupResult> FindByCodeAsync(
        string code,
        CancellationToken cancellationToken = default)
    {
        Calls++;
        return Task.FromResult(
            _results.Count > 0 ? _results.Dequeue() : new LookupResult.NotFound());
    }
}

sealed class StubHandler(
    HttpStatusCode statusCode,
    string body,
    string contentType = "application/json") : HttpMessageHandler
{
    public string? LastPath { get; private set; }

    protected override Task<HttpResponseMessage> SendAsync(
        HttpRequestMessage request,
        CancellationToken cancellationToken)
    {
        LastPath = request.RequestUri?.AbsolutePath;
        return Task.FromResult(new HttpResponseMessage(statusCode)
        {
            Content = new StringContent(body, Encoding.UTF8, contentType),
            RequestMessage = request,
        });
    }
}
