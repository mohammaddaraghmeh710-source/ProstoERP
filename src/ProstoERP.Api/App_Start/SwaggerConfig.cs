using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web.Http;
using System.Web.Http.Description;
using Prosto_ERP_API.Authentication;
using Prosto_ERP_API.Mobile;
using Swashbuckle.Application;
using Prosto_ERP_API.Documentation;
using Swashbuckle.Swagger;

namespace Prosto_ERP_API
{
    public static class SwaggerConfig
    {
        public static void Register(HttpConfiguration config)
        {
            // Serve only the generator here; the MVC page uses locally hosted Swagger UI.
            config.EnableSwagger(c =>
            {
                const string responseDescription =
                    "Explore and test the ERP API. Login returns an access token for employee endpoints. " +
                    "Use Authorize with Bearer followed by a space and the token. " +
                    "Integration and attendance endpoints use their configured Basic credentials. " +
                    "JSON responses omit null, empty-string and empty-collection properties recursively; " +
                    "false and zero remain present. Optional Data may be absent when empty.";
                c.MultipleApiVersions(SwaggerModules.Includes, versions =>
                {
                    foreach (var module in SwaggerModules.Modules)
                        versions.Version(module.Document, "Prosto ERP — " + module.Title)
                            .Description(responseDescription);
                });
                c.GroupActionsBy(SwaggerModules.Tag);
                c.UseFullTypeNameInSchemaIds();
                c.BasicAuth("basic")
                    .Description("Integration credentials, or brand attendance credentials for attendance endpoints.");
                c.ApiKey("bearer").Name("Authorization").In("header")
                    .Description("Enter Bearer followed by a space and the access token returned by login.");
                c.OperationFilter<SwaggerAuthenticationFilter>();
                c.SchemaFilter<SwaggerAuthenticationSchemaFilter>();
            });
        }
    }

    public sealed class SwaggerAuthenticationFilter : IOperationFilter
    {
        public void Apply(Operation operation, SchemaRegistry schemaRegistry, ApiDescription apiDescription)
        {
            // Overloaded actions (for example Values.Get) must have distinct operation IDs.
            operation.operationId += "_" + apiDescription.HttpMethod.Method + "_" +
                                     Regex.Replace(apiDescription.RelativePath.Split('?')[0], "[^a-zA-Z0-9_]", "_");
            var action = apiDescription.ActionDescriptor;
            if (action.ControllerDescriptor.ControllerName == "Authentication")
            {
                switch (action.ActionName)
                {
                    case "Register":
                        operation.summary = "Activate mobile access for an existing ERP employee";
                        operation.description = "Use existing ERP credentials and a persistent DeviceID. Copy the returned ChallengeID into verify-otp with Purpose=registration, then login with the same device. A different registered device requires devices/replace. Codes arrive at the employee email; local development uses the Mailpit inbox on port 8025.";
                        break;
                    case "VerifyOtp":
                        operation.summary = "Verify a registration or password recovery code";
                        operation.description = "Copy ChallengeID from register, devices/replace or forgot-password, and use its exact Purpose. Registration returns LoginRequired; password-reset returns a single-use ResetToken for reset-password. Codes expire after ten minutes and cannot be reused. The fixed 12345 code works only when Debug local OTP mode is configured.";
                        break;
                    case "Login":
                        operation.summary = "Login with ERP credentials and the activated device";
                        operation.description = "First register and verify the device by email. Reuse its DeviceID and platform, and supply OSVersion, Model, AppVersion and FCMToken. Copy AccessToken into Authorize as Bearer followed by a space and the token.";
                        break;
                    case "ForgotPassword":
                        operation.summary = "Request a password recovery email";
                        operation.description = "Use the ERP EmployeeNumber. Delivery runs in the background: wait for the email, then verify its ChallengeID with Purpose=password-reset. The acknowledgement is generic for account privacy and does not guarantee delivery. Wait at least 60 seconds before requesting another code.";
                        break;
                    case "ResetPassword":
                        operation.summary = "Set a password using verified recovery permission";
                        operation.description = "Use ResetToken from verify-otp and a NewPassword of 8–128 characters. ResetToken is single-use. This invalidates existing sessions and biometric credentials; login again with the new password and the same activated device.";
                        break;
                    case "ReplaceDevice":
                        operation.summary = "Replace the employee's single registered device by email OTP";
                        operation.description = "Submit existing ERP credentials with the NEW device metadata. The current device remains active until verify-otp succeeds with this ChallengeID and Purpose=device-replacement. Verification atomically approves only the new device and revokes previous sessions and biometric keys. Login on the new device, then enroll its own biometric key. Wait at least 60 seconds between activation requests.";
                        break;
                    case "EnrollBiometric":
                        operation.summary = "Enroll the current device's biometric-protected public key";
                        operation.description = "Authorize with the current Bearer session and reauthenticate with Password. Send only RSA JWK public Modulus (2048, 3072 or 4096 bits) and Exponent=AQAB, encoded as unpadded base64url. Keep the private key in the mobile device's biometric-protected keystore. CredentialID is an identifier, not a login secret. Enrolling again replaces the previous key; device replacement requires fresh enrollment.";
                        break;
                    case "BiometricChallenge":
                        operation.summary = "Request a one-time biometric signing challenge";
                        operation.description = "Supply CredentialID and the activated device's complete app/device metadata, including FCMToken. A different device is rejected. Sign the exact UTF-8 bytes of returned Challenge with the enrolled private key using SHA-256 with RSA PKCS#1 v1.5 (RS256). Do not reserialize or trim Challenge. It expires after 120 seconds; requesting another challenge replaces the previous one. Swagger does not hold or generate your private key.";
                        break;
                    case "BiometricLogin":
                        operation.summary = "Login using a biometric-protected RSA signature";
                        operation.description = "Use CredentialID, ChallengeID and an unpadded base64url Signature from the matching biometric/challenge. Send exactly the same app/device metadata as that request, including FCMToken. A GUID alone never authenticates. The challenge is consumed on signature verification, including an invalid signature; request a fresh challenge after any failed proof. Reused, expired, revoked and replaced-device credentials are rejected.";
                        break;
                }
                foreach (var code in new[] { "400", "429", "503" })
                    if (!operation.responses.ContainsKey(code))
                        operation.responses.Add(code, new Response { description = code == "400" ? "Invalid fields, expired code or used recovery permission." : code == "429" ? "Authentication attempt limit reached. Retry later." : "Authentication or email delivery unavailable." });
                if (new[] { "Login", "Register", "ReplaceDevice", "BiometricChallenge", "BiometricLogin" }.Contains(action.ActionName))
                    operation.responses["401"] = new Response { description = "Invalid credentials, revoked biometric enrollment or invalid/replayed biometric proof." };
                if (new[] { "Register", "ReplaceDevice" }.Contains(action.ActionName))
                    operation.responses["409"] = new Response { description = "Another device is already registered. Use email-verified device replacement." };
                if (action.ActionName == "Login")
                    operation.responses["403"] = new Response { description = "This device is not activated. Register or replace it and verify the email OTP first." };
            }
            if (action.GetCustomAttributes<System.ObsoleteAttribute>().Any()) operation.deprecated = true;
            var filters = action.GetFilterPipeline().Select(f => f.Instance).ToList();
            if (action.GetCustomAttributes<AllowAnonymousAttribute>().Any() ||
                action.ControllerDescriptor.GetCustomAttributes<AllowAnonymousAttribute>().Any()) return;

            string scheme = null;
            if (filters.Any(f => f is MobileSessionAttribute || f is CustomerSessionAttribute)) scheme = "bearer";
            else if (filters.Any(f => f is AuthenticationAttribute ||
                                      f is AttendanceCredentialAuthenticationAttribute ||
                                      f is IntegrationBasicAuthenticationAttribute)) scheme = "basic";
            if (scheme == null) return;

            operation.security = new List<IDictionary<string, IEnumerable<string>>>
            {
                new Dictionary<string, IEnumerable<string>> { { scheme, new string[0] } }
            };
            if (!operation.responses.ContainsKey("401"))
                operation.responses.Add("401",
                    new Response { description = "Missing, invalid or expired credentials." });
        }
    }

    public sealed class SwaggerAuthenticationSchemaFilter : ISchemaFilter
    {
        public void Apply(Schema schema, SchemaRegistry schemaRegistry, System.Type type)
        {
            if (type == typeof(MobileLoginDevice) && schema.properties != null)
            {
                schema.properties["Platform"].example = "Android";
                schema.properties["Model"].example = "Swagger";
                schema.properties["OSVersion"].example = "14";
                schema.properties["MACID"].example = "02:00:00:00:00:00";
                schema.properties["FCMToken"].example = "local-swagger-no-real-push-token";
                schema.properties["DeviceID"].description = "Persistent installation ID. Reuse the activated device's exact ID and platform. Replacement requires email OTP.";
                return;
            }
            if (type != typeof(ProstoERP.Contracts.Features.Authentication.VerifyOtpRequest) &&
                type != typeof(VerifyResetRequest)) return;
            Schema otp;
            if (schema.properties == null || !schema.properties.TryGetValue("OTP", out otp)) return;
            otp.example = "123456";
#if DEBUG
            bool local, fixedCode;
            if (bool.TryParse(System.Configuration.ConfigurationManager.AppSettings["LocalOtp.Enabled"], out local) && local &&
                bool.TryParse(System.Configuration.ConfigurationManager.AppSettings["LocalOtp.FixedCode"], out fixedCode) && fixedCode)
                otp.example = "12345";
#endif
            otp.description = "Code from the employee email. Copy ChallengeID from the matching request response.";
        }
    }
}
