using System.Data;
using Prosto_ERP_API.Mobile;
using ProstoERP.Application.Abstractions;
using ProstoERP.Infrastructure.Mobile.Data;
using ProstoERP.Application.Features.Circulars;

namespace ProstoERP.Infrastructure.Mobile.Features.Circulars
{
    public sealed class CircularStore : ICircularStore
    {
        private readonly IMobileQueryStore queries;
        public CircularStore(IMobileQueryStore queries) { this.queries = queries; }
        public void Employee(int actor, int number)
        {
            queries.Query("dbo.Circular_Identity", SqlParameters.P("@Actor", SqlDbType.Int, actor),
                SqlParameters.P("@EmployeeNumber", SqlDbType.Int, number));
        }
        public DataSet List(int actor, int page, int pageSize, string search, bool unreadOnly)
        {
            return queries.Query("dbo.Circular_List", SqlParameters.P("@Actor", SqlDbType.Int, actor),
                SqlParameters.P("@Page", SqlDbType.Int, page), SqlParameters.P("@PageSize", SqlDbType.Int, pageSize),
                SqlParameters.P("@Search", SqlDbType.NVarChar, search ?? "", 250), SqlParameters.P("@UnreadOnly", SqlDbType.Bit, unreadOnly));
        }
        public DataSet Detail(int actor, int id)
        {
            return queries.Query("dbo.Circular_Detail", SqlParameters.P("@Actor", SqlDbType.Int, actor),
                SqlParameters.P("@ID", SqlDbType.Int, id));
        }
        public DataSet File(int actor, int id, CircularFileEvent model, object tokenHash)
        {
            return queries.Query("dbo.Circular_File", SqlParameters.P("@Actor", SqlDbType.Int, actor),
                SqlParameters.P("@ID", SqlDbType.Int, id),
                SqlParameters.P("@Action", SqlDbType.VarChar, model.Action, 16), SqlParameters.P("@Source", SqlDbType.VarChar, "Mobile", 10),
                SqlParameters.P("@EventID", SqlDbType.UniqueIdentifier, model.EventID),
                SqlParameters.P("@OccurredAtUtc", SqlDbType.DateTime2,
                    model.OccurredAt.HasValue ? (object)model.OccurredAt.Value.UtcDateTime : null),
                SqlParameters.P("@TokenHash", SqlDbType.Binary, tokenHash, 32));
        }
    }
}
