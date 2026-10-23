using System;
using System.Configuration;
using ProstoERP.Application.Abstractions;
using ProstoERP.Application.Features.EmployeeAccess;
using ProstoERP.Application.Training;
using ProstoERP.Infrastructure.Mobile.Configuration;
using ProstoERP.Infrastructure.Mobile.Data;
using ProstoERP.Infrastructure.Mobile.Features.EmployeeAccess;
using ProstoERP.Infrastructure.Mobile.Features.Learning;
using ProstoERP.Infrastructure.Mobile.Security;
using ProstoERP.Infrastructure.Mobile.Storage;

namespace Prosto_ERP_API.Composition
{
    // Only the composition root knows the implementations. Services have no Web/configuration dependency.
    internal sealed class MobileBackend
    {
        internal static readonly MobileBackend Current = new MobileBackend();
        internal readonly IMobileOptions Options;
        internal readonly IMobileQueryStore Queries;
        internal readonly IMobileDataSessionFactory Sessions;
        internal readonly IMobileTokenService Tokens;
        internal readonly IPasswordCipher Passwords;
        internal readonly IAssetUrlBuilder Assets;
        internal readonly EmployeeAccessService EmployeeAccess;
        internal readonly SessionAuthenticationService SessionAuthentication;
        internal readonly TrainingCatalogService TrainingCatalog;
        internal readonly ProstoERP.Application.Features.EmployeeAccess.MobileContentService Content;
        internal readonly ProstoERP.Application.Features.Circulars.CircularService Circulars;

        private MobileBackend()
        {
            Func<string> connectionString = () => ConfigurationManager
                .ConnectionStrings["Prosto_ERP_ConnectionConnection"].ConnectionString;
            Options = new MobileOptions();
            Queries = new MobileQueryStore(connectionString);
            Sessions = new MobileDataSessionFactory(connectionString);
            Tokens = new MobileTokenService();
            Passwords = new PasswordCipher();
            Assets = new AssetUrlBuilder(Options);
            EmployeeAccess = new EmployeeAccessService(new EmployeeAccessStore(Queries), Options,
                Tokens, Passwords, Assets);
            SessionAuthentication = new SessionAuthenticationService(new SessionAuthenticationStore(Queries), Options);
            Content = new MobileContentService(new MobileContentStore(Queries), Assets);
            Circulars = new ProstoERP.Application.Features.Circulars.CircularService(
                new ProstoERP.Infrastructure.Mobile.Features.Circulars.CircularStore(Queries));
            TrainingCatalog = new TrainingCatalogService(new TrainingCatalogStore());
        }
        internal ProstoERP.Application.Features.Feedback.FeedbackService CreateFeedback(IMobileWorkflowContext context, IMobileFiles files)
        {
            return new ProstoERP.Application.Features.Feedback.FeedbackService(Sessions, context, files);
        }
        internal ProstoERP.Application.Features.Correspondence.CorrespondenceService CreateCorrespondence(IMobileWorkflowContext context, IMobileFiles files)
        {
            return new ProstoERP.Application.Features.Correspondence.CorrespondenceService(Sessions, context, files, Assets);
        }
        internal ProstoERP.Application.Features.CustomerFeedback.CustomerFeedbackService CreateCustomerFeedback(IMobileWorkflowContext context, IMobileFiles files)
        {
            return new ProstoERP.Application.Features.CustomerFeedback.CustomerFeedbackService(Sessions, context, files);
        }
        internal ProstoERP.Application.Features.CustomerPortal.CustomerPortalService CreateCustomerPortal(IMobileWorkflowContext context, IMobileFiles files)
        {
            return new ProstoERP.Application.Features.CustomerPortal.CustomerPortalService(Sessions, context, files, Tokens, Options);
        }
        internal ProstoERP.Application.Features.PasswordReset.IPasswordResetService CreatePasswordReset()
        {
            return new Prosto_ERP_API.Mobile.PasswordResetService(tokens: Tokens);
        }
    }
}
