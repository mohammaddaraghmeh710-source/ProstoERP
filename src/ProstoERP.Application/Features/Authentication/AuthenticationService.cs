using System;
using System.Data;
using System.Diagnostics;
using System.Net;
using System.Threading.Tasks;
using Newtonsoft.Json;
using Prosto_ERP_API.Mobile;
using ProstoERP.Application.Abstractions;
using ProstoERP.Application.Errors;
using ProstoERP.Application.Features.EmployeeAccess;
using ProstoERP.Application.Features.PasswordReset;
using ProstoERP.Contracts.Features.Authentication;
using ProstoERP.Contracts.Features.EmployeeAccess;
using ProstoERP.Contracts.Features.PasswordReset;

namespace ProstoERP.Application.Features.Authentication
{
    public sealed class AuthenticationService
    {
        private readonly IAuthenticationStore store;
        private readonly IAuthenticationSecurity security;
        private readonly IAuthenticationOtpSender sender;
        private readonly EmployeeAccessService employees;
        private readonly IPasswordResetService reset;
        private readonly IPasswordCipher cipher;
        private readonly IMobileTokenService tokens;
        private readonly IMobileOptions options;
        private readonly IPasswordRecoveryDispatcher recovery;

        public AuthenticationService(IAuthenticationStore store, IAuthenticationSecurity security,
            IAuthenticationOtpSender sender, EmployeeAccessService employees, IPasswordResetService reset,
            IPasswordCipher cipher, IMobileTokenService tokens, IMobileOptions options, IPasswordRecoveryDispatcher recovery)
        {
            this.store = store; this.security = security; this.sender = sender; this.employees = employees;
            this.reset = reset; this.cipher = cipher; this.tokens = tokens; this.options = options; this.recovery = recovery;
        }

        private void Limit(string scope, string account, string source)
        {
            store.CheckRate(scope, security.Hash("account:" + (account ?? "").Trim().ToUpperInvariant()),
                security.Hash("client:" + (source ?? "unknown")));
        }

        public EmployeeLoginResponse Login(MobileLoginRequest model, string source)
        {
            Limit("login", model.Username, source);
            return employees.Login(model);
        }

        public async Task<OtpChallengeResponse> Register(MobileLoginRequest model, string source, bool replace)
        {
            var purpose = replace ? "device-replacement" : "registration";
            Limit("activation", model.Username, source);
            var id = Guid.NewGuid();
            var code = security.Otp();
            var recipient = store.BeginRegistration(id, model, cipher.Encrypt(model.Password),
                security.Hash("activation:" + id.ToString("D") + ":" + code), purpose);
            try
            {
                await sender.Send(recipient, code, purpose);
                store.RegistrationDelivery(id, true);
            }
            catch
            {
                try { store.RegistrationDelivery(id, false); }
                catch { Trace.TraceWarning("Failed to invalidate activation delivery."); }
                throw;
            }
            return new OtpChallengeResponse { ChallengeID = id, Purpose = purpose, Message = "A verification code was sent to your employee email." };
        }

        public OtpVerificationResponse VerifyOtp(VerifyOtpRequest model, string source)
        {
            if (!security.IsOtpAllowed(model.OTP))
                throw new MobileBusinessException(HttpStatusCode.BadRequest, "INVALID_OTP_FORMAT", "Enter a valid verification code from your employee email.");
            Limit("verify-otp", model.ChallengeID.ToString("D"), source);
            if (model.Purpose == "password-reset")
            {
                var result = (ResetVerificationResponse)reset.Verify(model.ChallengeID, model.OTP);
                return new OtpVerificationResponse { Verified = true, Purpose = model.Purpose, ResetToken = result.ResetToken, ExpiresInSeconds = result.ExpiresInSeconds };
            }
            store.VerifyRegistration(model.ChallengeID,
                security.Hash("activation:" + model.ChallengeID.ToString("D") + ":" + model.OTP), model.Purpose);
            return new OtpVerificationResponse { Verified = true, Purpose = model.Purpose, DeviceRegistered = true, LoginRequired = true };
        }

        public Task<OtpChallengeResponse> ForgotPassword(int employee, string source)
        {
            Limit("forgot-password", employee.ToString(System.Globalization.CultureInfo.InvariantCulture), source);
            var id = Guid.NewGuid();
            // Account lookup and SMTP run outside the response path for both eligible and missing employees.
            recovery.Dispatch(employee, source, id);
            return Task.FromResult(new OtpChallengeResponse { ChallengeID = id, Purpose = "password-reset", Message = "If the employee account is eligible, a verification code will be sent to its registered email." });
        }

        public object ResetPassword(CompleteResetRequest model, string source)
        {
            Limit("reset-password", model.ResetToken, source);
            return reset.Complete(model.ResetToken, model.NewPassword);
        }

        public void Logout(byte[] tokenHash) { store.Logout(tokenHash); }
        public void UpdateDevice(byte[] tokenHash, DeviceContextRequest model) { store.UpdateDevice(tokenHash, model); }

        public BiometricCredentialResponse EnrollBiometric(byte[] tokenHash, BiometricEnrollmentRequest model, string source)
        {
            Limit("biometric-enroll", Convert.ToBase64String(tokenHash), source);
            if (!security.ValidPublicKey(model.Modulus, model.Exponent)) throw Invalid();
            var credential = Guid.NewGuid();
            store.EnrollBiometric(credential, tokenHash, cipher.Encrypt(model.Password), model.Modulus, model.Exponent);
            return new BiometricCredentialResponse { CredentialID = credential };
        }

        private byte[] Binding(DeviceContextRequest model)
        {
            return security.Hash("device:" + JsonConvert.SerializeObject(new { model.AppVersion, model.AppBuild, model.Device }));
        }

        public BiometricChallengeResponse BiometricChallenge(BiometricChallengeRequest model, string source)
        {
            Limit("biometric", model.CredentialID.ToString("D"), source);
            var id = Guid.NewGuid();
            var binding = Binding(model);
            var challenge = "prosto-mobile-biometric-v1\n" + model.CredentialID.ToString("D") + "\n" + id.ToString("D") + "\n" + Convert.ToBase64String(binding) + "\n" + tokens.NewToken();
            store.BeginBiometric(id, model.CredentialID, binding, challenge, model);
            return new BiometricChallengeResponse { ChallengeID = id, CredentialID = model.CredentialID, Challenge = challenge };
        }

        public EmployeeLoginResponse BiometricLogin(BiometricLoginRequest model, string source)
        {
            Limit("biometric", model.CredentialID.ToString("D"), source);
            // Consume before verification: successful or failed proofs cannot replay this challenge.
            var row = store.ConsumeBiometric(model.ChallengeID, model.CredentialID, Binding(model));
            if (row == null || !security.Verify((string)row["Modulus"], (string)row["Exponent"], (string)row["Challenge"], model.Signature))
                throw new MobileBusinessException(HttpStatusCode.Unauthorized, "BIOMETRIC_PROOF_INVALID", "The biometric proof is invalid or expired. Request a new challenge.");
            var token = tokens.NewToken();
            var result = store.BiometricLogin(model.CredentialID, tokens.TokenHash(token), options.IdleMinutes, options.MaximumMinutes, model);
            return employees.CreateLoginResponse(result, token);
        }

        private static MobileBusinessException Invalid()
        {
            return new MobileBusinessException(HttpStatusCode.BadRequest, "INVALID_REQUEST", "Invalid public key or authentication request.");
        }
    }
}
