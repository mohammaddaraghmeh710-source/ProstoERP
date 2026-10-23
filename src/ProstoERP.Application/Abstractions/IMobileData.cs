using System;
using System.Data;
using ProstoERP.Application.Data;

namespace ProstoERP.Application.Abstractions
{
    // One instance owns one connection and its transaction. Never share it between requests.
    public interface IMobileDataSession : IDisposable
    {
        void Begin();
        void Commit();
        bool RollbackConfirmed();
        DataSet Execute(MobileStatement statement, params object[] parameters);
    }

    public interface IMobileDataSessionFactory
    {
        IMobileDataSession Open();
    }
}
