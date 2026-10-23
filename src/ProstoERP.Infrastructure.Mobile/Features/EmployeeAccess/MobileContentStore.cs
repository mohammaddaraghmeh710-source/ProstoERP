using System.Data;
using ProstoERP.Application.Abstractions;
using ProstoERP.Infrastructure.Mobile.Data;
using ProstoERP.Application.Features.EmployeeAccess;

namespace ProstoERP.Infrastructure.Mobile.Features.EmployeeAccess
{
    public sealed class MobileContentStore : IMobileContentStore
    {
        private readonly IMobileQueryStore queries;
        public MobileContentStore(IMobileQueryStore queries) { this.queries = queries; }
        public DataSet News(object actor, int brandID)
        {
            return queries.Query("dbo.MobileApi_News",
                SqlParameters.P("@Actor", SqlDbType.Int, actor),
                SqlParameters.P("@BrandID", SqlDbType.Int, brandID));
        }
        public DataSet InformationPages(object actor)
        {
            return queries.Query("dbo.MobileApi_InfoPages", SqlParameters.P("@Actor", SqlDbType.Int, actor));
        }
        public void Logout(object tokenHash)
        {
            queries.Query("dbo.MobileApi_Logout", SqlParameters.P("@TokenHash", SqlDbType.Binary, tokenHash, 32));
        }
    }
}
