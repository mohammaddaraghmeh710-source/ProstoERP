using System.Data;
using ProstoERP.Application.Abstractions;

namespace ProstoERP.Application.Features.Correspondence
{
    // Each opened store owns one connection and its transaction for this workflow.
    public interface ICorrespondenceStoreFactory
    {
        ICorrespondenceStore Open();
    }

    public interface ICorrespondenceStore : IMobileTransaction
    {
        DataSet MobileApiCorrespondenceActor(params object[] parameters);
        DataSet DetailCorrespondenceAccess(params object[] parameters);
        DataSet CorrespondenceDetail(params object[] parameters);
        DataSet VisitCorrespondenceAudit(params object[] parameters);
        DataSet CorrespondenceCatalogList(params object[] parameters);
        DataSet OptionsBrands(params object[] parameters);
        DataSet OptionsCorrespondenceAllowedRecipients(params object[] parameters);
        DataSet OptionsCorrespondenceAllowedRecipients2(params object[] parameters);
        DataSet CorrespondenceOptions(params object[] parameters);
        DataSet RecipientsCorrespondenceAllowedRecipients(params object[] parameters);
        DataSet MobileApiCorrespondenceList(params object[] parameters);
        DataSet CorrespondenceLogView(params object[] parameters);
        DataSet CorrespondenceOrganization(params object[] parameters);
        DataSet CorrespondenceRelated(params object[] parameters);
        DataSet CorrespondenceAuditList(params object[] parameters);
        DataSet MobileApiCorrespondenceMessages(params object[] parameters);
        DataSet UploadCorrespondenceAllowedRecipients(params object[] parameters);
        DataSet InsertCorrespondenceThread(params object[] parameters);
        DataSet InsertCorrespondenceThreadMessage(params object[] parameters);
        DataSet UpdateCorrespondenceThreadClose(params object[] parameters);
        DataSet ReadCorrespondenceThreadMessages(params object[] parameters);
        DataSet UpdateCorrespondenceMessagesRead(params object[] parameters);
        DataSet CorrespondenceArchive(params object[] parameters);
        DataSet NotificationsCorrespondenceNotifications(params object[] parameters);
        DataSet SelectCorrespondenceUnreadCount(params object[] parameters);
        DataSet NotificationReadN(params object[] parameters);
        DataSet ReplayLock(params object[] parameters);
        DataSet ReplayMobileApiCorrespondenceEvents(params object[] parameters);
        DataSet RecordLock(params object[] parameters);
    }
}
