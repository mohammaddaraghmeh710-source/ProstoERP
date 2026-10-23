using System;
using System.Data;

namespace ProstoERP.Infrastructure.Mobile.Data
{
    // One instance owns one connection and its transaction. Never share it between requests.
    internal interface IMobileDataSession : IDisposable
    {
        void Begin();
        void Commit();
        bool RollbackConfirmed();
        DataSet Execute(MobileStatement statement, params object[] parameters);
    }

    internal interface IMobileDataSessionFactory
    {
        IMobileDataSession Open();
    }
}
