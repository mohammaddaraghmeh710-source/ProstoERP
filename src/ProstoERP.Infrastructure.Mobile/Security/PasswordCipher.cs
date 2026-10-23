using Echo.Encrptor;
using ProstoERP.Application.Abstractions;
namespace ProstoERP.Infrastructure.Mobile.Security
{
    public sealed class PasswordCipher : IPasswordCipher
    {
        public string Encrypt(string password) { return new TripleDesEncryptor().Encrypt(password); }
    }
}
