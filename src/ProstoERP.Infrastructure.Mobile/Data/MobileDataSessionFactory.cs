using System;
namespace ProstoERP.Infrastructure.Mobile.Data
{
    internal sealed class MobileDataSessionFactory : IMobileDataSessionFactory
    {
        private readonly Func<string> connectionString;
        public MobileDataSessionFactory(Func<string> connectionString) { this.connectionString = connectionString; }
        public IMobileDataSession Open() { return new MobileDataSession(connectionString()); }
    }
}
