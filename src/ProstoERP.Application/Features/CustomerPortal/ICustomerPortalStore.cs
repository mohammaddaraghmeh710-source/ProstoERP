using System.Data;
using ProstoERP.Application.Abstractions;

namespace ProstoERP.Application.Features.CustomerPortal
{
    // Each opened store owns one connection and its transaction for this workflow.
    public interface ICustomerPortalStoreFactory
    {
        ICustomerPortalStore Open();
    }

    public interface ICustomerPortalStore : IMobileTransaction
    {
        DataSet CustomerApiCheckLoginRate(params object[] parameters);
        DataSet CustomerCredentials(params object[] parameters);
        DataSet CustomerLoginResult(params object[] parameters);
        DataSet CustomerLogLoginFailure(params object[] parameters);
        DataSet CustomerApiCreateSession(params object[] parameters);
        DataSet CustomerApiLogout(params object[] parameters);
        DataSet SubmitFeedbackCustomerPortalFeedback(params object[] parameters);
        DataSet SubmitFeedbackLock(params object[] parameters);
        DataSet LockLock(params object[] parameters);
        DataSet CustomerSession(params object[] parameters);
        DataSet CustomerFeedbackOptions(params object[] parameters);
        DataSet CustomerApiFeedback(params object[] parameters);
        DataSet CustomerSubmitFeedback(params object[] parameters);
    }
}
