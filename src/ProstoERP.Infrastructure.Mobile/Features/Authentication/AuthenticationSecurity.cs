using System;
using System.Configuration;
using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using ProstoERP.Application.Features.Authentication;

namespace ProstoERP.Infrastructure.Mobile.Features.Authentication
{
    public sealed class AuthenticationSecurity : IAuthenticationSecurity
    {
        public byte[] Hash(string value)
        {
            var key = Convert.FromBase64String(ConfigurationManager.AppSettings["PasswordReset.HashKey"] ?? "");
            if (key.Length < 32) throw new ConfigurationErrorsException("Authentication signing key unavailable.");
            using (var hash = new HMACSHA256(key)) return hash.ComputeHash(Encoding.UTF8.GetBytes(value));
        }

        public bool IsOtpAllowed(string code) { return LocalOtpDelivery.IsValidCode(code); }

        public string Otp()
        {
            var local = LocalOtpDelivery.FixedCode();
            if (local != null) return local;
            using (var rng = RandomNumberGenerator.Create())
            {
                var bytes = new byte[4]; uint value;
                do { rng.GetBytes(bytes); value = BitConverter.ToUInt32(bytes, 0); } while (value >= 4294000000u);
                return (value % 1000000).ToString("D6", CultureInfo.InvariantCulture);
            }
        }

        private static byte[] Decode(string value)
        {
            if (value == null || value.Length > 684 || !Regex.IsMatch(value, "\\A[A-Za-z0-9_-]+\\z")) throw new FormatException();
            var text = value.Replace('-', '+').Replace('_', '/');
            var bytes = Convert.FromBase64String(text.PadRight((text.Length + 3) / 4 * 4, '='));
            if (Convert.ToBase64String(bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_') != value) throw new FormatException();
            return bytes;
        }

        private static RSA PublicKey(string modulus, string exponent)
        {
            var n = Decode(modulus);
            if ((n.Length != 256 && n.Length != 384 && n.Length != 512) || n[0] < 128 || exponent != "AQAB") throw new FormatException();
            var rsa = RSA.Create();
            try { rsa.ImportParameters(new RSAParameters { Modulus = n, Exponent = Decode(exponent) }); return rsa; }
            catch { rsa.Dispose(); throw; }
        }

        public bool ValidPublicKey(string modulus, string exponent)
        {
            try { using (var rsa = PublicKey(modulus, exponent)) return true; }
            catch (FormatException) { return false; }
            catch (CryptographicException) { return false; }
            catch (ArgumentException) { return false; }
        }

        public bool Verify(string modulus, string exponent, string challenge, string signature)
        {
            try
            {
                using (var rsa = PublicKey(modulus, exponent))
                    return rsa.VerifyData(Encoding.UTF8.GetBytes(challenge), Decode(signature), HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1);
            }
            catch (FormatException) { return false; }
            catch (CryptographicException) { return false; }
            catch (ArgumentException) { return false; }
        }
    }
}
