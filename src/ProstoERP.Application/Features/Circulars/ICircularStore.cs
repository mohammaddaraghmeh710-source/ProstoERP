using System.Data;
using Prosto_ERP_API.Mobile;

namespace ProstoERP.Application.Features.Circulars
{
    public interface ICircularStore
    {
        void Employee(int actor, int number);
        DataSet List(int actor, int page, int pageSize, string search, bool unreadOnly);
        DataSet Detail(int actor, int id);
        DataSet File(int actor, int id, CircularFileEvent model, object tokenHash);
    }
}
