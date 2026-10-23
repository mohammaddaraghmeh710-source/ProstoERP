using System.Data;
using ProstoERP.Application.Abstractions;

namespace ProstoERP.Application.Features.Feedback
{
    // Each opened store owns one connection and its transaction for this workflow.
    public interface IFeedbackStoreFactory
    {
        IFeedbackStore Open();
    }

    public interface IFeedbackStore : IMobileTransaction
    {
        DataSet SelectEmployeeFeedbackTypes(params object[] parameters);
        DataSet SelectEmployeeFeedbackTopics(params object[] parameters);
        DataSet SelectEmployeeFeedbackTransferTargets(params object[] parameters);
        DataSet SelectEmployeeFeedbackRecipients(params object[] parameters);
        DataSet MobileApiFeedbackRequests(params object[] parameters);
        DataSet UploadEmployeeFeedbackRequests(params object[] parameters);
        DataSet UpdateEmployeeFeedbackAction(params object[] parameters);
        DataSet InsertEmployeeFeedbackRequest(params object[] parameters);
        DataSet UpdateEmployeeFeedbackRead(params object[] parameters);
        DataSet SelectEmployeeFeedbackRequest(params object[] parameters);
        DataSet OpenEmployeeFeedbackTypes(params object[] parameters);
        DataSet SelectEmployeeFeedbackAttachments(params object[] parameters);
        DataSet SelectEmployeeFeedbackContact(params object[] parameters);
        DataSet SelectEmployeeFeedbackWorkflow(params object[] parameters);
        DataSet SelectEmployeeFeedbackDownload(params object[] parameters);
        DataSet SelectEmployeeFeedbackNotifications(params object[] parameters);
        DataSet MobileApiFeedbackActor(params object[] parameters);
        DataSet SelectEmployeeFeedbackPermissions(params object[] parameters);
        DataSet SelectEmployeeFeedbackTargetTypes(params object[] parameters);
        DataSet RequireAccessEmployeeFeedbackAccess(params object[] parameters);
        DataSet FindReplayLock(params object[] parameters);
        DataSet FindReplayMobileApiFeedbackEvents(params object[] parameters);
        DataSet RecordEmployeeFeedbackWorkflow(params object[] parameters);
    }
}
