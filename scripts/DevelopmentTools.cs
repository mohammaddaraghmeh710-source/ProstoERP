using System;
using System.Configuration;
using System.Security.Cryptography;
using Echo.Encrptor;

public static class DevelopmentTools
{
    public static int Main(string[] args)
    {
        try
        {
            var cipher = new TripleDesEncryptor();
            if (args.Length == 1 && args[0] == "encrypt")
            {
                Console.Write(cipher.Encrypt(Console.In.ReadToEnd()));
                return 0;
            }
            if (args.Length == 1 && args[0] == "decrypt")
            {
                Console.Write(cipher.Decrypt(Console.In.ReadToEnd()));
                return 0;
            }
            var samples = new[] { "", "local password", "كلمة مرور تجريبية", new string('x', 2000) };
            foreach (var value in samples)
            {
                var encrypted = cipher.Encrypt(value);
                if (cipher.Decrypt(encrypted) != value) throw new Exception("Roundtrip failed.");
                if (new TripleDesEncryptor().Encrypt(value) != encrypted) throw new Exception("Determinism failed.");
                var bytes = Convert.FromBase64String(encrypted.Substring("prosto-dev1:".Length));
                bytes[17] ^= 1;
                ExpectRejected(cipher, "prosto-dev1:" + Convert.ToBase64String(bytes));
            }
            ExpectRejected(cipher, "a legacy ciphertext");
            ExpectRejected(cipher, "prosto-dev1:not-base64");
            ExpectRejected(cipher, "prosto-dev1:AA==");
            Console.WriteLine("Encryptor: roundtrip, deterministic instances, Unicode, tamper and malformed/legacy rejection passed.");
            return 0;
        }
        catch (Exception e)
        {
            Console.Error.WriteLine(e.Message);
            return 1;
        }
    }

    private static void ExpectRejected(TripleDesEncryptor cipher, string value)
    {
        try { cipher.Decrypt(value); }
        catch (CryptographicException) { return; }
        throw new Exception("Invalid ciphertext was accepted.");
    }
}
