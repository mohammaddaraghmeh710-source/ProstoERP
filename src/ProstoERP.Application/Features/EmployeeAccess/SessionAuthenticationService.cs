using System.Collections.Generic;
using System.Data;
using ProstoERP.Application.Abstractions;
using ProstoERP.Application.Data;

namespace ProstoERP.Application.Features.EmployeeAccess
{
    public interface ISessionAuthenticationStore
    {
        DataSet Employee(byte[] hash, int idleMinutes);
        DataSet Customer(byte[] hash);
    }
    public sealed class SessionAuthenticationService
    {
        private readonly ISessionAuthenticationStore store;
        private readonly IMobileOptions options;
        public SessionAuthenticationService(ISessionAuthenticationStore store, IMobileOptions options)
        {
            this.store = store;
            this.options = options;
        }
        public Dictionary<string, object> Employee(byte[] hash)
        {
            var result = store.Employee(hash, options.IdleMinutes);
            return result.Tables.Count == 0 || result.Tables[0].Rows.Count == 0
                ? null : MobileRowMapper.Row(result.Tables[0].Rows[0]);
        }
        public List<Dictionary<string, object>> Customer(byte[] hash)
        {
            return MobileRowMapper.PortalRows(store.Customer(hash));
        }
    }
}
