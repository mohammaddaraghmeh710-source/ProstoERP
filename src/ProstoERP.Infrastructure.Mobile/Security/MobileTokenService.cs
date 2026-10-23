using System;
using System.Security.Cryptography;
using System.Text.RegularExpressions;
using ProstoERP.Application.Abstractions;
namespace ProstoERP.Infrastructure.Mobile.Security
{
    public sealed class MobileTokenService : IMobileTokenService
    {
        public string NewToken()
        {
            var bytes = new byte[32];
            using (var random = RandomNumberGenerator.Create())
            {
                random.GetBytes(bytes);
            }

            return Convert.ToBase64String(bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_');
        }
        public byte[] TokenHash(string token)
        {
            if (token == null || !Regex.IsMatch(token, @"\A[A-Za-z0-9_-]{43}\z")) return null;
            byte[] bytes;
            try
            {
                bytes = Convert.FromBase64String(token.Replace('-', '+').Replace('_', '/') + "=");
            }
            catch (FormatException)
            {
                return null;
            }

            if (Convert.ToBase64String(bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_') != token) return null;
            using (var hash = SHA256.Create())
            {
                return hash.ComputeHash(bytes);
            }
        }
    }
}
