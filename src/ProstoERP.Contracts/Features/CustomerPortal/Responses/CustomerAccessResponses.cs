using System;

namespace ProstoERP.Contracts.Features.CustomerPortal
{
    public sealed class CustomerIdentity
    {
        public object AccountID { get; set; }
        public object Name { get; set; }
    }
    public sealed class CustomerLoginResponse
    {
        public string Token { get; set; }
        public string TokenType { get; set; }
        public object ExpiresUtc { get; set; }
        public int IdleMinutes { get; set; }
        public CustomerIdentity Customer { get; set; }
    }
    public sealed class CustomerSessionResponse
    {
        public int AccountID { get; set; }
        public object Name { get; set; }
        public object ExpiresUtc { get; set; }
    }
    public sealed class CustomerLogoutResponse
    {
        public bool LoggedOut { get; set; }
    }
}
