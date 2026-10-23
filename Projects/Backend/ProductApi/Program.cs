using Npgsql;
using ProductApi;

var builder = WebApplication.CreateBuilder(args);

var connectionString =
    builder.Configuration.GetConnectionString("Products")
    ?? Environment.GetEnvironmentVariable("CONNECTIONSTRINGS__PRODUCTS")
    ?? throw new InvalidOperationException(
        "Set ConnectionStrings:Products or CONNECTIONSTRINGS__PRODUCTS.");

builder.Services.AddSingleton(_ => NpgsqlDataSource.Create(connectionString));
builder.Services.AddSingleton(_ => VisionOptions.FromEnvironment());
builder.Services.AddHttpClient("vision", client => client.Timeout = TimeSpan.FromSeconds(30));

var app = builder.Build();

app.MapGet("/health", () => Results.Ok(new { status = "ok" }));

app.MapGet("/products", async (NpgsqlDataSource db, CancellationToken cancellationToken) =>
{
    const string sql = """
        SELECT id, name, description, color, quantity, barcode, qr_code
        FROM products
        ORDER BY id
        """;

    await using var command = db.CreateCommand(sql);
    await using var reader = await command.ExecuteReaderAsync(cancellationToken);

    var products = new List<Product>();
    while (await reader.ReadAsync(cancellationToken))
    {
        products.Add(ReadProduct(reader));
    }

    return Results.Ok(products);
});

app.MapPost(
    "/products",
    async (Product product, NpgsqlDataSource db, CancellationToken cancellationToken) =>
    {
        if (string.IsNullOrWhiteSpace(product.Id) ||
            string.IsNullOrWhiteSpace(product.Name) ||
            string.IsNullOrWhiteSpace(product.Barcode) ||
            string.IsNullOrWhiteSpace(product.QrCode))
        {
            return Results.BadRequest(new
            {
                message = "id, name, barcode, and qrCode are required.",
            });
        }

        if (product.Quantity < 0)
        {
            return Results.BadRequest(new { message = "quantity must be >= 0." });
        }

        const string sql = """
            INSERT INTO products
                (id, name, description, color, quantity, barcode, qr_code)
            VALUES
                (@id, @name, @description, @color, @quantity, @barcode, @qrCode)
            ON CONFLICT (id) DO UPDATE SET
                name = EXCLUDED.name,
                description = EXCLUDED.description,
                color = EXCLUDED.color,
                quantity = EXCLUDED.quantity,
                barcode = EXCLUDED.barcode,
                qr_code = EXCLUDED.qr_code
            RETURNING id, name, description, color, quantity, barcode, qr_code
            """;

        try
        {
            await using var command = db.CreateCommand(sql);
            command.Parameters.AddWithValue("id", product.Id.Trim());
            command.Parameters.AddWithValue("name", product.Name.Trim());
            command.Parameters.AddWithValue("description", product.Description);
            command.Parameters.AddWithValue("color", product.Color);
            command.Parameters.AddWithValue("quantity", product.Quantity);
            command.Parameters.AddWithValue("barcode", product.Barcode.Trim());
            command.Parameters.AddWithValue("qrCode", product.QrCode);

            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            await reader.ReadAsync(cancellationToken);
            Product saved = ReadProduct(reader);

            return Results.Created(
                $"/products/{Uri.EscapeDataString(saved.Id)}",
                saved);
        }
        catch (PostgresException exception)
            when (exception.SqlState == PostgresErrorCodes.UniqueViolation)
        {
            return Results.Conflict(new
            {
                message = "A product with this barcode or QR code already exists.",
            });
        }
    });

app.MapPost(
    "/products/register",
    async (
        RegisterProductRequest request,
        NpgsqlDataSource db,
        CancellationToken cancellationToken) =>
    {
        var code = request.Code?.Trim() ?? string.Empty;
        var name = request.Name?.Trim() ?? string.Empty;
        var description = request.Description?.Trim() ?? string.Empty;
        var color = request.Color?.Trim() ?? string.Empty;

        if (code.Length is 0 or > 200 || code.Any(char.IsControl))
        {
            return Results.BadRequest(new
            {
                message = "code is required (max 200 characters, no control characters).",
            });
        }

        if (name.Length is 0 or > 100)
        {
            return Results.BadRequest(new { message = "name is required (max 100 characters)." });
        }

        if (description.Length > 500 || color.Length > 50)
        {
            return Results.BadRequest(new
            {
                message = "description (max 500) or color (max 50) is too long.",
            });
        }

        if (request.Quantity is < 0 or > 100000)
        {
            return Results.BadRequest(new { message = "quantity must be between 0 and 100000." });
        }

        try
        {
            await using var connection = await db.OpenConnectionAsync(cancellationToken);
            await using var transaction = await connection.BeginTransactionAsync(cancellationToken);

            await using (var lockCommand = new NpgsqlCommand(
                "SELECT pg_advisory_xact_lock(727001)", connection, transaction))
            {
                await lockCommand.ExecuteNonQueryAsync(cancellationToken);
            }

            const string existsSql = """
                SELECT id, name, description, color, quantity, barcode, qr_code
                FROM products
                WHERE lower(id) = lower(@code)
                   OR barcode = @code
                   OR lower(qr_code) = lower(@code)
                LIMIT 1
                """;

            await using (var existsCommand = new NpgsqlCommand(existsSql, connection, transaction))
            {
                existsCommand.Parameters.AddWithValue("code", code);
                await using var existing = await existsCommand.ExecuteReaderAsync(cancellationToken);
                if (await existing.ReadAsync(cancellationToken))
                {
                    return Results.Conflict(new
                    {
                        message = "A product with this code already exists.",
                        product = ReadProduct(existing),
                    });
                }
            }

            const string nextIdSql = """
                SELECT COALESCE(MAX((substring(id from '^PHN-([0-9]+)$'))::int), 0) + 1
                FROM products
                WHERE id ~ '^PHN-[0-9]+$'
                """;

            int next;
            await using (var nextCommand = new NpgsqlCommand(nextIdSql, connection, transaction))
            {
                next = Convert.ToInt32(await nextCommand.ExecuteScalarAsync(cancellationToken));
            }

            var id = $"PHN-{next:000}";
            var qrCode = $"{{\"id\":\"{id}\",\"type\":\"phone\"}}";

            const string insertSql = """
                INSERT INTO products
                    (id, name, description, color, quantity, barcode, qr_code)
                VALUES
                    (@id, @name, @description, @color, @quantity, @barcode, @qrCode)
                RETURNING id, name, description, color, quantity, barcode, qr_code
                """;

            Product saved;
            await using (var insertCommand = new NpgsqlCommand(insertSql, connection, transaction))
            {
                insertCommand.Parameters.AddWithValue("id", id);
                insertCommand.Parameters.AddWithValue("name", name);
                insertCommand.Parameters.AddWithValue("description", description);
                insertCommand.Parameters.AddWithValue("color", color);
                insertCommand.Parameters.AddWithValue("quantity", request.Quantity);
                insertCommand.Parameters.AddWithValue("barcode", code);
                insertCommand.Parameters.AddWithValue("qrCode", qrCode);

                await using var inserted = await insertCommand.ExecuteReaderAsync(cancellationToken);
                await inserted.ReadAsync(cancellationToken);
                saved = ReadProduct(inserted);
            }

            await transaction.CommitAsync(cancellationToken);

            return Results.Created($"/products/{Uri.EscapeDataString(saved.Id)}", saved);
        }
        catch (PostgresException exception)
            when (exception.SqlState == PostgresErrorCodes.UniqueViolation)
        {
            return Results.Conflict(new { message = "A product with this code already exists." });
        }
    });

app.MapPost(
    "/identify",
    async (
        IdentifyRequest request,
        VisionOptions vision,
        IHttpClientFactory clients,
        NpgsqlDataSource db,
        CancellationToken cancellationToken) =>
    {
        if (!vision.IsConfigured)
        {
            return Results.Json(
                new { message = "Phone recognition is not configured on the server." },
                statusCode: StatusCodes.Status503ServiceUnavailable);
        }

        if (!PhoneIdentification.TryDecodeJpeg(request.Image, out var jpeg))
        {
            return Results.BadRequest(new
            {
                message = "image must be a base64 JPEG of at most 4 MB.",
            });
        }

        VisionAnswer? answer;
        int status;
        try
        {
            (answer, status) = await PhoneIdentification.AskAsync(
                clients.CreateClient("vision"), vision, jpeg, cancellationToken);
        }
        catch (TaskCanceledException)
        {
            return Results.Json(
                new { message = "Phone recognition timed out." },
                statusCode: StatusCodes.Status504GatewayTimeout);
        }
        catch (HttpRequestException)
        {
            return Results.Json(
                new { message = "Could not reach the recognition service." },
                statusCode: StatusCodes.Status502BadGateway);
        }

        if (status != 200 || answer is null)
        {
            return Results.Json(
                new { message = "The recognition service did not return a usable answer." },
                statusCode: StatusCodes.Status502BadGateway);
        }

        var modelMatches = new List<Product>();
        var keys = PhoneIdentification.MatchKeys(answer);
        if (answer.IsPhone && keys.Length > 0)
        {
            const string sql = """
                SELECT id, name, description, color, quantity, barcode, qr_code
                FROM products
                WHERE regexp_replace(lower(name), '[^a-z0-9]', '', 'g') = ANY(@keys)
                ORDER BY quantity DESC, id
                LIMIT 10
                """;

            await using var command = db.CreateCommand(sql);
            command.Parameters.AddWithValue("keys", keys);
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            while (await reader.ReadAsync(cancellationToken))
            {
                modelMatches.Add(ReadProduct(reader));
            }
        }

        var matches = string.IsNullOrWhiteSpace(answer.Color)
            ? modelMatches
            : modelMatches
                .Where(product => PhoneIdentification.ColorMatches(answer.Color, product.Color))
                .ToList();

        return Results.Ok(new
        {
            isPhone = answer.IsPhone,
            brand = answer.Brand,
            model = answer.Model,
            color = answer.Color,
            confidence = answer.Confidence,
            matches,
            modelMatches,
        });
    });

app.MapGet(
    "/products/{code}",
    async (string code, NpgsqlDataSource db, CancellationToken cancellationToken) =>
    {
        const string sql = """
            SELECT id, name, description, color, quantity, barcode, qr_code
            FROM products
            WHERE lower(id) = lower(@code)
               OR barcode = @code
               OR lower(qr_code) = lower(@code)
            LIMIT 1
            """;

        await using var command = db.CreateCommand(sql);
        command.Parameters.AddWithValue("code", code);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        if (!await reader.ReadAsync(cancellationToken))
        {
            return Results.NotFound(new { message = "No such product." });
        }

        return Results.Ok(ReadProduct(reader));
    });

app.Run();

static Product ReadProduct(NpgsqlDataReader reader) => new(
    Id: reader.GetString(0),
    Name: reader.GetString(1),
    Description: reader.GetString(2),
    Color: reader.GetString(3),
    Quantity: reader.GetInt32(4),
    Barcode: reader.GetString(5),
    QrCode: reader.GetString(6));
