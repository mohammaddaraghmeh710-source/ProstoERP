using System.Data;
using Prosto_ERP_API.Mobile;
using ProstoERP.Application.Abstractions;
using ProstoERP.Infrastructure.Mobile.Data;
using ProstoERP.Application.Features.EmployeeAccess;
namespace ProstoERP.Infrastructure.Mobile.Features.EmployeeAccess
{
    public sealed class EmployeeAccessStore : IEmployeeAccessStore
    {
        private readonly IMobileQueryStore store;
        public EmployeeAccessStore(IMobileQueryStore store) { this.store = store; }
        public DataSet Login(MobileLoginRequest model, string password, byte[] tokenHash, byte[] bioHash, int idleMinutes, int maximumMinutes)
        {
            return store.Query("dbo.MobileApi_Login",
                    SqlParameters.P("@Username", SqlDbType.NVarChar, model.Username.Trim(), 250),
                    SqlParameters.P("@EncryptedPassword", SqlDbType.NVarChar, password, -1),
                    SqlParameters.P("@TokenHash", SqlDbType.Binary, tokenHash, 32),
                    SqlParameters.P("@IdleMinutes", SqlDbType.Int, idleMinutes),
                    SqlParameters.P("@MaximumMinutes", SqlDbType.Int, maximumMinutes),
                    SqlParameters.P("@AppVersion", SqlDbType.NVarChar, model.AppVersion, 50),
                    SqlParameters.P("@AppBuild", SqlDbType.NVarChar, model.AppBuild, 50),
                    SqlParameters.P("@DeviceID", SqlDbType.NVarChar, model.Device.DeviceID, 128),
                    SqlParameters.P("@DevicePlatform", SqlDbType.NVarChar, model.Device.Platform, 16),
                    SqlParameters.P("@DeviceManufacturer", SqlDbType.NVarChar, model.Device.Manufacturer, 100),
                    SqlParameters.P("@DeviceModel", SqlDbType.NVarChar, model.Device.Model, 150),
                    SqlParameters.P("@OSVersion", SqlDbType.NVarChar, model.Device.OSVersion, 50),
                    SqlParameters.P("@MACID", SqlDbType.VarChar, model.Device.MACID, 17),
                    SqlParameters.P("@BIOHash", SqlDbType.Binary, bioHash, 32),
                    SqlParameters.P("@FCMToken", SqlDbType.NVarChar, model.Device.FCMToken, 4000));
        }
        public DataSet LoginViaBio(byte[] bioHash, byte[] tokenHash, int idleMinutes, int maximumMinutes)
        {
            return store.Query("dbo.MobileApi_LoginViaBIO",
                    SqlParameters.P("@BIOHash", SqlDbType.Binary, bioHash, 32),
                    SqlParameters.P("@TokenHash", SqlDbType.Binary, tokenHash, 32),
                    SqlParameters.P("@IdleMinutes", SqlDbType.Int, idleMinutes),
                    SqlParameters.P("@MaximumMinutes", SqlDbType.Int, maximumMinutes));
        }
        public DataSet DeviceAccess(MobileLoginRequest model, string password, bool submit)
        {
            return store.Query("dbo.MobileApi_DeviceAccess",
                SqlParameters.P("@Username", SqlDbType.NVarChar, model.Username, 250),
                SqlParameters.P("@EncryptedPassword", SqlDbType.NVarChar,
                    password, -1),
                SqlParameters.P("@AppVersion", SqlDbType.NVarChar, model.AppVersion, 50),
                SqlParameters.P("@AppBuild", SqlDbType.NVarChar, model.AppBuild, 50),
                SqlParameters.P("@DeviceID", SqlDbType.NVarChar, model.Device.DeviceID, 128),
                SqlParameters.P("@DevicePlatform", SqlDbType.NVarChar, model.Device.Platform, 16),
                SqlParameters.P("@DeviceManufacturer", SqlDbType.NVarChar, model.Device.Manufacturer, 100),
                SqlParameters.P("@DeviceModel", SqlDbType.NVarChar, model.Device.Model, 150),
                SqlParameters.P("@OSVersion", SqlDbType.NVarChar, model.Device.OSVersion, 50),
                SqlParameters.P("@MACID", SqlDbType.VarChar, model.Device.MACID, 17),
                SqlParameters.P("@Submit", SqlDbType.Bit, submit));
        }
    }
}
