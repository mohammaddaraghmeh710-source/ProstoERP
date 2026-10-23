using System.Data;

namespace ProstoERP.Application.Features.EmployeeAccess
{
    public interface IMobileContentStore
    {
        DataSet News(object actor, int brandID);
        DataSet InformationPages(object actor);
        void Logout(object tokenHash);
    }
}
