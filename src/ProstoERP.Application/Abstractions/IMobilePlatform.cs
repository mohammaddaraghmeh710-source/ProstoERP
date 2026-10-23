namespace ProstoERP.Application.Abstractions
{
    public interface IMobileOptions
    {
        int IdleMinutes { get; }
        int MaximumMinutes { get; }
        bool AllowHttp { get; }
        string AssetBaseUrl { get; }
        string PortalRoot { get; }
    }

    public interface IMobileTokenService
    {
        string NewToken();
        byte[] TokenHash(string token);
    }

    public interface IPasswordCipher
    {
        string Encrypt(string password);
    }

    public interface IAssetUrlBuilder
    {
        string AssetUrl(object value);
    }
}
