using ProstoERP.Application.Abstractions;

namespace ProstoERP.Infrastructure.Mobile.Data
{
    internal abstract class MobileTransactionalStore : IMobileTransaction
    {
        protected readonly IMobileDataSession Session;

        protected MobileTransactionalStore(IMobileDataSession session) { Session = session; }
        public void Begin() { Session.Begin(); }
        public void Commit() { Session.Commit(); }
        public bool RollbackConfirmed() { return Session.RollbackConfirmed(); }
        public void Dispose() { Session.Dispose(); }
    }
}
