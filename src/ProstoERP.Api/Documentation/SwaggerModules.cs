using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Http.Description;
using Prosto_ERP_API.Mobile;

namespace Prosto_ERP_API.Documentation
{
    public sealed class SwaggerModule
    {
        public string Key { get; private set; }
        public string Document { get; private set; }
        public string Title { get; private set; }

        internal SwaggerModule(string key, string document, string title)
        {
            Key = key;
            Document = document;
            Title = title;
        }
    }

    // One catalog drives both document selection and the Swagger UI menu.
    public static class SwaggerModules
    {
        public static readonly IReadOnlyList<SwaggerModule> Modules = Array.AsReadOnly(new[]
        {
            new SwaggerModule("mobile", "mobile-v1", "Mobile API — All modules"),
            new SwaggerModule("authentication", "authentication-v1", "Authentication"),
            new SwaggerModule("employee-access", "employee-access-v1", "Employee access and devices"),
            new SwaggerModule("employee-content", "employee-content-v1", "Employee content"),
            new SwaggerModule("password-reset", "password-reset-v1", "Password reset"),
            new SwaggerModule("feedback", "feedback-v1", "Employee feedback"),
            new SwaggerModule("circulars", "circulars-v1", "Circulars"),
            new SwaggerModule("correspondence", "correspondence-v1", "Correspondence"),
            new SwaggerModule("customer-portal", "customer-portal-v1", "Customer portal"),
            new SwaggerModule("customer-feedback", "customer-feedback-v1", "Customer feedback"),
            new SwaggerModule("learning", "learning-v1", "Learning"),
            new SwaggerModule("all", "v1", "All APIs")
        });

        public static SwaggerModule Find(string key)
        {
            return Modules.FirstOrDefault(module => module.Key == key) ?? Modules[0];
        }

        public static bool Includes(ApiDescription api, string document)
        {
            if (document == "v1") return true;
            var feature = Feature(api);
            return feature != null && (document == "mobile-v1" || document == Find(feature).Document);
        }

        public static string Tag(ApiDescription api)
        {
            var feature = Feature(api);
            return feature == null
                ? "Other modules / " + api.ActionDescriptor.ControllerDescriptor.ControllerName
                : "Mobile / " + Find(feature).Title;
        }

        private static string Feature(ApiDescription api)
        {
            var type = api.ActionDescriptor.ControllerDescriptor.ControllerType;
            var action = api.ActionDescriptor.ActionName;
            if (type == typeof(Prosto_ERP_API.Features.Authentication.AuthenticationController)) return "authentication";
            if (type == typeof(UsersController))
            {
                switch (action)
                {
                    case "RequestPasswordReset":
                    case "VerifyPasswordResetOTP":
                    case "ResetPassword": return "password-reset";
                    default: return "employee-access";
                }
            }
            if (type == typeof(MobileController))
                return action == "Get_News" || action == "Get_InfoPages" ? "employee-content" : "employee-access";
            if (type == typeof(FeedbackController)) return "feedback";
            if (type == typeof(CircularsController)) return "circulars";
            if (type == typeof(CorrespondenceController)) return "correspondence";
            if (type == typeof(CustomerPortalController)) return "customer-portal";
            if (type == typeof(CustomerFeedbackController)) return "customer-feedback";
            // Legacy learning routes remain unchanged, including their Basic authentication.
            if (type == typeof(Controllers.ERPController))
                return action == "GetNews" || action == "GetNewsByID" ? "employee-content" : "learning";
            return null;
        }
    }
}
