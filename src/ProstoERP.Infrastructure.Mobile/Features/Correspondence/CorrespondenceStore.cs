using System;
using System.Data;
using ProstoERP.Application.Features.Correspondence;
using ProstoERP.Infrastructure.Mobile.Data;

namespace ProstoERP.Infrastructure.Mobile.Features.Correspondence
{
    public sealed class CorrespondenceStore : ICorrespondenceStoreFactory
    {
        private readonly MobileDataSessionFactory sessions;

        public CorrespondenceStore(Func<string> connectionString)
        {
            sessions = new MobileDataSessionFactory(connectionString);
        }

        public ICorrespondenceStore Open()
        {
            return new StoreSession(sessions.Open());
        }

        private sealed class StoreSession : MobileTransactionalStore, ICorrespondenceStore
        {
            internal StoreSession(IMobileDataSession session) : base(session) { }

            public DataSet MobileApiCorrespondenceActor(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Correspondence_MobileApiCorrespondenceActor, parameters);
            }

            public DataSet DetailCorrespondenceAccess(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Correspondence_DetailCorrespondenceAccess, parameters);
            }

            public DataSet CorrespondenceDetail(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Correspondence_CorrespondenceDetail, parameters);
            }

            public DataSet VisitCorrespondenceAudit(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Correspondence_VisitCorrespondenceAudit, parameters);
            }

            public DataSet CorrespondenceCatalogList(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Correspondence_CorrespondenceCatalogList, parameters);
            }

            public DataSet OptionsBrands(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Correspondence_OptionsBrands, parameters);
            }

            public DataSet OptionsCorrespondenceAllowedRecipients(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Correspondence_OptionsCorrespondenceAllowedRecipients, parameters);
            }

            public DataSet OptionsCorrespondenceAllowedRecipients2(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Correspondence_OptionsCorrespondenceAllowedRecipients2, parameters);
            }

            public DataSet CorrespondenceOptions(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Correspondence_CorrespondenceOptions, parameters);
            }

            public DataSet RecipientsCorrespondenceAllowedRecipients(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Correspondence_RecipientsCorrespondenceAllowedRecipients, parameters);
            }

            public DataSet MobileApiCorrespondenceList(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Correspondence_MobileApiCorrespondenceList, parameters);
            }

            public DataSet CorrespondenceLogView(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Correspondence_CorrespondenceLogView, parameters);
            }

            public DataSet CorrespondenceOrganization(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Correspondence_CorrespondenceOrganization, parameters);
            }

            public DataSet CorrespondenceRelated(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Correspondence_CorrespondenceRelated, parameters);
            }

            public DataSet CorrespondenceAuditList(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Correspondence_CorrespondenceAuditList, parameters);
            }

            public DataSet MobileApiCorrespondenceMessages(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Correspondence_MobileApiCorrespondenceMessages, parameters);
            }

            public DataSet UploadCorrespondenceAllowedRecipients(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Correspondence_UploadCorrespondenceAllowedRecipients, parameters);
            }

            public DataSet InsertCorrespondenceThread(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Correspondence_InsertCorrespondenceThread, parameters);
            }

            public DataSet InsertCorrespondenceThreadMessage(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Correspondence_InsertCorrespondenceThreadMessage, parameters);
            }

            public DataSet UpdateCorrespondenceThreadClose(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Correspondence_UpdateCorrespondenceThreadClose, parameters);
            }

            public DataSet ReadCorrespondenceThreadMessages(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Correspondence_ReadCorrespondenceThreadMessages, parameters);
            }

            public DataSet UpdateCorrespondenceMessagesRead(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Correspondence_UpdateCorrespondenceMessagesRead, parameters);
            }

            public DataSet CorrespondenceArchive(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Correspondence_CorrespondenceArchive, parameters);
            }

            public DataSet NotificationsCorrespondenceNotifications(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Correspondence_NotificationsCorrespondenceNotifications, parameters);
            }

            public DataSet SelectCorrespondenceUnreadCount(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Correspondence_SelectCorrespondenceUnreadCount, parameters);
            }

            public DataSet NotificationReadN(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Correspondence_NotificationReadN, parameters);
            }

            public DataSet ReplayLock(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Correspondence_ReplayLock, parameters);
            }

            public DataSet ReplayMobileApiCorrespondenceEvents(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Correspondence_ReplayMobileApiCorrespondenceEvents, parameters);
            }

            public DataSet RecordLock(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Correspondence_RecordLock, parameters);
            }
        }
    }
}
