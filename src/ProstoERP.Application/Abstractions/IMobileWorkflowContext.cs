using System;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;

namespace ProstoERP.Application.Abstractions
{
    // HTTP hosts supply request metadata without exposing Web API types to use cases.
    public interface IMobileWorkflowContext
    {
        bool IsModelValid { get; }
        int Actor { get; }
        Dictionary<string, object> CustomerSession { get; }
        object CustomerTokenHash { get; }
        string ClientAddress { get; }
        DateTime ReceivedUtc { get; }
        string Link(string route, object values);
    }
    public interface IMobileUpload : IDisposable
    {
        string Data { get; }
        bool PreserveFiles { get; set; }
        string Xml { get; }
        byte[] Hash(string model);
        void Prepare();
    }
    public interface IMobileFiles
    {
        int MaxBytes { get; }
        string Root { get; }
        string Mime(string extension);
        Task<IMobileUpload> Read();
    }
    public sealed class MobileFileResult
    {
        public Stream Stream { get; set; }
        public string Mime { get; set; }
        public string Name { get; set; }
        public bool Download { get; set; }
        public bool Sandbox { get; set; }
    }
}
