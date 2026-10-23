using System;

namespace ProstoERP.Application.Abstractions
{
    // Transaction lifecycle shared by module stores; exposes no cross-module queries.
    public interface IMobileTransaction : IDisposable
    {
        void Begin();
        void Commit();
        bool RollbackConfirmed();
    }
}
