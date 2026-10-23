using System;
using System.Data;
using ProstoERP.Application.Features.Feedback;
using ProstoERP.Infrastructure.Mobile.Data;

namespace ProstoERP.Infrastructure.Mobile.Features.Feedback
{
    public sealed class FeedbackStore : IFeedbackStoreFactory
    {
        private readonly MobileDataSessionFactory sessions;

        public FeedbackStore(Func<string> connectionString)
        {
            sessions = new MobileDataSessionFactory(connectionString);
        }

        public IFeedbackStore Open()
        {
            return new StoreSession(sessions.Open());
        }

        private sealed class StoreSession : MobileTransactionalStore, IFeedbackStore
        {
            internal StoreSession(IMobileDataSession session) : base(session) { }

            public DataSet SelectEmployeeFeedbackTypes(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Feedback_SelectEmployeeFeedbackTypes, parameters);
            }

            public DataSet SelectEmployeeFeedbackTopics(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Feedback_SelectEmployeeFeedbackTopics, parameters);
            }

            public DataSet SelectEmployeeFeedbackTransferTargets(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Feedback_SelectEmployeeFeedbackTransferTargets, parameters);
            }

            public DataSet SelectEmployeeFeedbackRecipients(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Feedback_SelectEmployeeFeedbackRecipients, parameters);
            }

            public DataSet MobileApiFeedbackRequests(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Feedback_MobileApiFeedbackRequests, parameters);
            }

            public DataSet UploadEmployeeFeedbackRequests(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Feedback_UploadEmployeeFeedbackRequests, parameters);
            }

            public DataSet UpdateEmployeeFeedbackAction(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Feedback_UpdateEmployeeFeedbackAction, parameters);
            }

            public DataSet InsertEmployeeFeedbackRequest(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Feedback_InsertEmployeeFeedbackRequest, parameters);
            }

            public DataSet UpdateEmployeeFeedbackRead(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Feedback_UpdateEmployeeFeedbackRead, parameters);
            }

            public DataSet SelectEmployeeFeedbackRequest(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Feedback_SelectEmployeeFeedbackRequest, parameters);
            }

            public DataSet OpenEmployeeFeedbackTypes(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Feedback_OpenEmployeeFeedbackTypes, parameters);
            }

            public DataSet SelectEmployeeFeedbackAttachments(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Feedback_SelectEmployeeFeedbackAttachments, parameters);
            }

            public DataSet SelectEmployeeFeedbackContact(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Feedback_SelectEmployeeFeedbackContact, parameters);
            }

            public DataSet SelectEmployeeFeedbackWorkflow(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Feedback_SelectEmployeeFeedbackWorkflow, parameters);
            }

            public DataSet SelectEmployeeFeedbackDownload(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Feedback_SelectEmployeeFeedbackDownload, parameters);
            }

            public DataSet SelectEmployeeFeedbackNotifications(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Feedback_SelectEmployeeFeedbackNotifications, parameters);
            }

            public DataSet MobileApiFeedbackActor(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Feedback_MobileApiFeedbackActor, parameters);
            }

            public DataSet SelectEmployeeFeedbackPermissions(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Feedback_SelectEmployeeFeedbackPermissions, parameters);
            }

            public DataSet SelectEmployeeFeedbackTargetTypes(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Feedback_SelectEmployeeFeedbackTargetTypes, parameters);
            }

            public DataSet RequireAccessEmployeeFeedbackAccess(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Feedback_RequireAccessEmployeeFeedbackAccess, parameters);
            }

            public DataSet FindReplayLock(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Feedback_FindReplayLock, parameters);
            }

            public DataSet FindReplayMobileApiFeedbackEvents(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Feedback_FindReplayMobileApiFeedbackEvents, parameters);
            }

            public DataSet RecordEmployeeFeedbackWorkflow(params object[] parameters)
            {
                return Session.Execute(MobileStatement.Feedback_RecordEmployeeFeedbackWorkflow, parameters);
            }
        }
    }
}
