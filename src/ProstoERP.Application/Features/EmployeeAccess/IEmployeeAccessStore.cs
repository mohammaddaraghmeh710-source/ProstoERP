using System.Data;
using Prosto_ERP_API.Mobile;

namespace ProstoERP.Application.Features.EmployeeAccess
{
    public interface IEmployeeAccessStore
    {
        DataSet Login(MobileLoginRequest model, string password, byte[] tokenHash, byte[] bioHash,
            int idleMinutes, int maximumMinutes);
        DataSet LoginViaBio(byte[] bioHash, byte[] tokenHash, int idleMinutes, int maximumMinutes);
        DataSet DeviceAccess(MobileLoginRequest model, string password, bool submit);
    }
}
