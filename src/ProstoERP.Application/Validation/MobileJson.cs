using Newtonsoft.Json;
namespace ProstoERP.Application.Validation
{
    public static class MobileJson
    {
        public static readonly JsonSerializerSettings Settings = new JsonSerializerSettings
        {
            MissingMemberHandling = MissingMemberHandling.Error, TypeNameHandling = TypeNameHandling.None, MaxDepth = 16
        };
    }
}
