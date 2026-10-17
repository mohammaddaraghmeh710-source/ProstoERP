using System.Net.Sockets;
using Microsoft.Extensions.Diagnostics.HealthChecks;

internal sealed class LocalSqlHealthCheck : IHealthCheck
{
    public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        try
        {
            using var client = new TcpClient();
            await client.ConnectAsync("127.0.0.1", 14333, cancellationToken);
            return HealthCheckResult.Healthy("Local SQL Server accepts TCP connections on port 14333.");
        }
        catch (SocketException)
        {
            return HealthCheckResult.Unhealthy("Start the prosto-erp Colima VM and prosto-erp-dev-sql container.");
        }
    }
}
