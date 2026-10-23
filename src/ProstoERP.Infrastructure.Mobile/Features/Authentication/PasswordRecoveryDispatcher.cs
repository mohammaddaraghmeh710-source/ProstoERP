using System;
using System.Diagnostics;
using System.Configuration;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Hosting;
using ProstoERP.Application.Features.Authentication;
using ProstoERP.Application.Features.PasswordReset;

namespace ProstoERP.Infrastructure.Mobile.Features.Authentication
{
    public sealed class PasswordRecoveryDispatcher : IPasswordRecoveryDispatcher
    {
        private readonly IPasswordResetService reset;
        public PasswordRecoveryDispatcher(IPasswordResetService reset) { this.reset = reset; }

        public void Dispatch(int employee, string source, Guid challengeId)
        {
            Func<CancellationToken, Task> work = async cancellation =>
            {
                if (cancellation.IsCancellationRequested) return;
                try { await reset.Request(employee, source, challengeId); }
                catch (Exception ex)
                {
                    // Never log employee identity, OTP, reset permission, credentials or SMTP messages.
                    Trace.TraceWarning("Password recovery delivery unavailable ({0}).", ex.GetType().Name);
                }
            };
            bool localHttp;
            if (Type.GetType("Mono.Runtime") != null &&
                bool.TryParse(ConfigurationManager.AppSettings["MobileApi.AllowHttp"], out localHttp) && localHttp)
            {
                // XSP lacks the IIS background-work host; this fallback is for local HTTP development only.
                Task.Run(() => work(CancellationToken.None));
                return;
            }
            HostingEnvironment.QueueBackgroundWorkItem(work);
        }
    }
}
