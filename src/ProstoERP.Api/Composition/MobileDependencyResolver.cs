using System;
using System.Collections.Generic;
using System.Web.Http.Dependencies;
using Prosto_ERP_API.Mobile;

namespace Prosto_ERP_API.Composition
{
    internal sealed class MobileDependencyResolver : IDependencyResolver
    {
        private readonly IDependencyScope fallback;
        private readonly IDependencyResolver root;
        internal MobileDependencyResolver(IDependencyResolver fallback) : this(fallback, fallback) { }
        private MobileDependencyResolver(IDependencyScope fallback, IDependencyResolver root)
        {
            this.fallback = fallback;
            this.root = root;
        }
        public object GetService(Type serviceType)
        {
            if (serviceType == typeof(Prosto_ERP_API.Features.Authentication.AuthenticationController))
                return new Prosto_ERP_API.Features.Authentication.AuthenticationController(MobileBackend.Current.CreateAuthentication());
            if (serviceType == typeof(UsersController))
                return new UsersController(MobileBackend.Current.EmployeeAccess);
            if (serviceType == typeof(MobileController))
                return new MobileController(MobileBackend.Current.EmployeeAccess, MobileBackend.Current.Content);
            if (serviceType == typeof(CircularsController))
                return new CircularsController(MobileBackend.Current.Circulars);
            if (serviceType == typeof(FeedbackController))
                return new FeedbackController(MobileBackend.Current.CreateFeedback);
            if (serviceType == typeof(CorrespondenceController))
                return new CorrespondenceController(MobileBackend.Current.CreateCorrespondence);
            if (serviceType == typeof(CustomerFeedbackController))
                return new CustomerFeedbackController(MobileBackend.Current.CreateCustomerFeedback);
            if (serviceType == typeof(CustomerPortalController))
                return new CustomerPortalController(MobileBackend.Current.CreateCustomerPortal);
            return fallback.GetService(serviceType);
        }
        public IEnumerable<object> GetServices(Type serviceType) { return fallback.GetServices(serviceType); }
        public IDependencyScope BeginScope() { return new MobileDependencyResolver(root.BeginScope(), root); }
        public void Dispose() { fallback.Dispose(); }
    }
}
