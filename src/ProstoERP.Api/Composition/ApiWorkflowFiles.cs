using System.Threading.Tasks;
using System.Net.Http;
using Prosto_ERP_API.Mobile;
using ProstoERP.Application.Abstractions;

namespace Prosto_ERP_API.Composition
{
    internal sealed class ApiWorkflowFiles : IMobileFiles
    {
        private readonly HttpRequestMessage request;
        private readonly bool correspondence;
        internal ApiWorkflowFiles(HttpRequestMessage request, bool correspondence)
        {
            this.request = request;
            this.correspondence = correspondence;
        }
        public int MaxBytes => correspondence ? CorrespondenceFiles.MaxBytes : FeedbackFiles.MaxBytes;
        public string Root => correspondence ? CorrespondenceFiles.Root : FeedbackFiles.Root;
        public string Mime(string extension)
        {
            return correspondence ? CorrespondenceFiles.Mime(extension) : FeedbackFiles.Mime(extension);
        }
        public async Task<IMobileUpload> Read()
        {
            if (correspondence) return await CorrespondenceFiles.Read(request);
            return await FeedbackFiles.Read(request);
        }
    }
}
