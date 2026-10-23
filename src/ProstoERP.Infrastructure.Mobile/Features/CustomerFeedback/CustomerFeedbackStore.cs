using System;
using System.Data;
using ProstoERP.Application.Features.CustomerFeedback;
using ProstoERP.Infrastructure.Mobile.Data;

namespace ProstoERP.Infrastructure.Mobile.Features.CustomerFeedback
{
    public sealed class CustomerFeedbackStore : ICustomerFeedbackStoreFactory
    {
        private readonly MobileDataSessionFactory sessions;

        public CustomerFeedbackStore(Func<string> connectionString)
        {
            sessions = new MobileDataSessionFactory(connectionString);
        }

        public ICustomerFeedbackStore Open()
        {
            return new StoreSession(sessions.Open());
        }

        private sealed class StoreSession : MobileTransactionalStore, ICustomerFeedbackStore
        {
            internal StoreSession(IMobileDataSession session) : base(session) { }

            public DataSet SelectCustomerFeedbackOptions(params object[] parameters)
            {
                return Session.Execute(MobileStatement.CustomerFeedback_SelectCustomerFeedbackOptions, parameters);
            }

            public DataSet CreateLock(params object[] parameters)
            {
                return Session.Execute(MobileStatement.CustomerFeedback_CreateLock, parameters);
            }

            public DataSet CreateCustomerFeedbackSubmissions(params object[] parameters)
            {
                return Session.Execute(MobileStatement.CustomerFeedback_CreateCustomerFeedbackSubmissions, parameters);
            }

            public DataSet InsertCustomerFeedbackRequest(params object[] parameters)
            {
                return Session.Execute(MobileStatement.CustomerFeedback_InsertCustomerFeedbackRequest, parameters);
            }

            public DataSet CreateEmployeeFeedbackWorkflow(params object[] parameters)
            {
                return Session.Execute(MobileStatement.CustomerFeedback_CreateEmployeeFeedbackWorkflow, parameters);
            }

            public DataSet CustomerFeedbackCheckRate(params object[] parameters)
            {
                return Session.Execute(MobileStatement.CustomerFeedback_CustomerFeedbackCheckRate, parameters);
            }
        }
    }
}
