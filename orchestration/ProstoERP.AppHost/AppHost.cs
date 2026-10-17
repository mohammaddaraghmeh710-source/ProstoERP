using System.Net.Sockets;
using System.Xml.Linq;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.DependencyInjection;

var builder = DistributedApplication.CreateBuilder(args);
var root = Path.GetFullPath(Path.Combine(builder.AppHostDirectory, "..", ".."));
var configPath = Path.Combine(root, "src", "ProstoERP.Api", "Web.config");
if (!File.Exists(configPath))
    throw new InvalidOperationException("Run python3 scripts/setup_development.py --build --database first.");

// Keep the existing Web.config and database volume as the source of local settings.
// Framework applications do not consume Aspire connection-string environment variables.
var connection = XDocument.Load(configPath).Root?.Element("connectionStrings")?
    .Elements("add").FirstOrDefault(e => (string?)e.Attribute("name") == "Prosto_ERP_ConnectionConnection")?
    .Attribute("connectionString")?.Value
    ?? throw new InvalidOperationException("The local API database connection string is missing.");
builder.Configuration["ConnectionStrings:erp-database"] = connection;
builder.Services.AddHealthChecks().AddCheck<LocalSqlHealthCheck>("local-sql");
var database = builder.AddConnectionString("erp-database").WithHealthCheck("local-sql");

var xsp = Environment.GetEnvironmentVariable("PROSTO_XSP_PATH") ?? "xsp4";
var api = builder.AddExecutable("api", xsp, Path.Combine(root, "src", "ProstoERP.Api"),
        "--nonstop", "--address=127.0.0.1", "--port=3001",
        "--applications=/:" + Path.Combine(root, "src", "ProstoERP.Api"))
    .WithHttpEndpoint(port: 3001, targetPort: 3001, name: "http", isProxied: false)
    .WithHttpHealthCheck("/swagger/docs/v1")
    .WithUrl("/swagger", "Swagger")
    .WaitFor(database);

builder.AddExecutable("portal", xsp, Path.Combine(root, "src", "Portal"),
        "--nonstop", "--address=127.0.0.1", "--port=52219",
        "--applications=/:" + Path.Combine(root, "src", "Portal"))
    .WithHttpEndpoint(port: 52219, targetPort: 52219, name: "http", isProxied: false)
    .WithHttpHealthCheck("/login.aspx")
    .WithUrl("/login.aspx", "Portal login")
    .WaitFor(api);

builder.Build().Run();

