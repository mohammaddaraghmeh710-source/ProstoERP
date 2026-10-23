using System.Data;
using ProstoERP.Application.Features.EmployeeAccess;
using ProstoERP.Infrastructure.Mobile.Data;

namespace ProstoERP.Infrastructure.Mobile.Features.EmployeeAccess
{
    public sealed class SessionAuthenticationStore : ISessionAuthenticationStore
    {
        private readonly IMobileQueryStore queries;
        public SessionAuthenticationStore(IMobileQueryStore queries) { this.queries = queries; }
        public DataSet Employee(byte[] hash, int idleMinutes)
        {
            return queries.Query("dbo.MobileApi_Authenticate",
                SqlParameters.P("@TokenHash", SqlDbType.Binary, hash, 32),
                SqlParameters.P("@IdleMinutes", SqlDbType.Int, idleMinutes));
        }
        public DataSet Customer(byte[] hash)
        {
            return queries.Query("dbo.CustomerApi_Authenticate",
                SqlParameters.P("@TokenHash", SqlDbType.Binary, hash, 32));
        }
    }
}
