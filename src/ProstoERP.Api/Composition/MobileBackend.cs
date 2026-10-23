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
        private readonly ProstoERP.Application.Features.Feedback.IFeedbackStoreFactory feedbackStore;
        private readonly ProstoERP.Application.Features.Correspondence.ICorrespondenceStoreFactory correspondenceStore;
        private readonly ProstoERP.Application.Features.CustomerFeedback.ICustomerFeedbackStoreFactory customerFeedbackStore;
        private readonly ProstoERP.Application.Features.CustomerPortal.ICustomerPortalStoreFactory customerPortalStore;
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
            feedbackStore = new ProstoERP.Infrastructure.Mobile.Features.Feedback.FeedbackStore(connectionString);
            correspondenceStore = new ProstoERP.Infrastructure.Mobile.Features.Correspondence.CorrespondenceStore(connectionString);
            customerFeedbackStore = new ProstoERP.Infrastructure.Mobile.Features.CustomerFeedback.CustomerFeedbackStore(connectionString);
            customerPortalStore = new ProstoERP.Infrastructure.Mobile.Features.CustomerPortal.CustomerPortalStore(connectionString);
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
            return new ProstoERP.Application.Features.Feedback.FeedbackService(feedbackStore, context, files);
        }
        internal ProstoERP.Application.Features.Correspondence.CorrespondenceService CreateCorrespondence(IMobileWorkflowContext context, IMobileFiles files)
        {
            return new ProstoERP.Application.Features.Correspondence.CorrespondenceService(correspondenceStore, context, files, Assets);
        }
        internal ProstoERP.Application.Features.CustomerFeedback.CustomerFeedbackService CreateCustomerFeedback(IMobileWorkflowContext context, IMobileFiles files)
        {
            return new ProstoERP.Application.Features.CustomerFeedback.CustomerFeedbackService(customerFeedbackStore, context, files);
        }
        internal ProstoERP.Application.Features.CustomerPortal.CustomerPortalService CreateCustomerPortal(IMobileWorkflowContext context, IMobileFiles files)
        {
            return new ProstoERP.Application.Features.CustomerPortal.CustomerPortalService(customerPortalStore, context, files, Tokens, Options);
        }
        internal ProstoERP.Application.Features.Authentication.AuthenticationService CreateAuthentication(EmployeeAccessService employeeAccess = null)
        {
            var reset = CreatePasswordReset();
            return new ProstoERP.Application.Features.Authentication.AuthenticationService(
                new ProstoERP.Infrastructure.Mobile.Features.Authentication.AuthenticationStore(Queries),
                new ProstoERP.Infrastructure.Mobile.Features.Authentication.AuthenticationSecurity(),
                new ProstoERP.Infrastructure.Mobile.Features.Authentication.AuthenticationOtpSender(),
                employeeAccess ?? EmployeeAccess, reset, Passwords, Tokens, Options,
                new ProstoERP.Infrastructure.Mobile.Features.Authentication.PasswordRecoveryDispatcher(reset));
        }
        internal ProstoERP.Application.Features.PasswordReset.IPasswordResetService CreatePasswordReset()
        {
            return new Prosto_ERP_API.Mobile.PasswordResetService(tokens: Tokens);
        }
    }
}
