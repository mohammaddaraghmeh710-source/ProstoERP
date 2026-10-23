using System;
using System.Data;
using ProstoERP.Application.Features.CustomerPortal;
using ProstoERP.Infrastructure.Mobile.Data;

namespace ProstoERP.Infrastructure.Mobile.Features.CustomerPortal
{
    public sealed class CustomerPortalStore : ICustomerPortalStoreFactory
    {
        private readonly MobileDataSessionFactory sessions;

        public CustomerPortalStore(Func<string> connectionString)
        {
            sessions = new MobileDataSessionFactory(connectionString);
        }

        public ICustomerPortalStore Open()
        {
            return new StoreSession(sessions.Open());
        }

        private sealed class StoreSession : MobileTransactionalStore, ICustomerPortalStore
        {
            internal StoreSession(IMobileDataSession session) : base(session) { }

            public DataSet CustomerApiCheckLoginRate(params object[] parameters)
            {
                return Session.Execute(MobileStatement.CustomerPortal_CustomerApiCheckLoginRate, parameters);
            }

            public DataSet CustomerCredentials(params object[] parameters)
            {
                return Session.Execute(MobileStatement.CustomerPortal_CustomerCredentials, parameters);
            }

            public DataSet CustomerLoginResult(params object[] parameters)
            {
                return Session.Execute(MobileStatement.CustomerPortal_CustomerLoginResult, parameters);
            }

            public DataSet CustomerLogLoginFailure(params object[] parameters)
            {
                return Session.Execute(MobileStatement.CustomerPortal_CustomerLogLoginFailure, parameters);
            }

            public DataSet CustomerApiCreateSession(params object[] parameters)
            {
                return Session.Execute(MobileStatement.CustomerPortal_CustomerApiCreateSession, parameters);
            }

            public DataSet CustomerApiLogout(params object[] parameters)
            {
                return Session.Execute(MobileStatement.CustomerPortal_CustomerApiLogout, parameters);
            }

            public DataSet SubmitFeedbackCustomerPortalFeedback(params object[] parameters)
            {
                return Session.Execute(MobileStatement.CustomerPortal_SubmitFeedbackCustomerPortalFeedback, parameters);
            }

            public DataSet SubmitFeedbackLock(params object[] parameters)
            {
                return Session.Execute(MobileStatement.CustomerPortal_SubmitFeedbackLock, parameters);
            }

            public DataSet LockLock(params object[] parameters)
            {
                return Session.Execute(MobileStatement.CustomerPortal_LockLock, parameters);
            }

            public DataSet CustomerSession(params object[] parameters)
            {
                return Session.Execute(MobileStatement.CustomerPortal_CustomerSession, parameters);
            }

            public DataSet CustomerFeedbackOptions(params object[] parameters)
            {
                return Session.Execute(MobileStatement.CustomerPortal_CustomerFeedbackOptions, parameters);
            }

            public DataSet CustomerApiFeedback(params object[] parameters)
            {
                return Session.Execute(MobileStatement.CustomerPortal_CustomerApiFeedback, parameters);
            }

            public DataSet CustomerSubmitFeedback(params object[] parameters)
            {
                return Session.Execute(MobileStatement.CustomerPortal_CustomerSubmitFeedback, parameters);
            }
        }
    }
}
