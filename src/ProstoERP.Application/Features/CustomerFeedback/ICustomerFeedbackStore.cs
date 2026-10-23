using System.Data;
using ProstoERP.Application.Abstractions;

namespace ProstoERP.Application.Features.CustomerFeedback
{
    // Each opened store owns one connection and its transaction for this workflow.
    public interface ICustomerFeedbackStoreFactory
    {
        ICustomerFeedbackStore Open();
    }

    public interface ICustomerFeedbackStore : IMobileTransaction
    {
        DataSet SelectCustomerFeedbackOptions(params object[] parameters);
        DataSet CreateLock(params object[] parameters);
        DataSet CreateCustomerFeedbackSubmissions(params object[] parameters);
        DataSet InsertCustomerFeedbackRequest(params object[] parameters);
        DataSet CreateEmployeeFeedbackWorkflow(params object[] parameters);
        DataSet CustomerFeedbackCheckRate(params object[] parameters);
    }
}
