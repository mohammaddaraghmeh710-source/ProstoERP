using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using Prosto_ERP_API.Mobile;

namespace ProstoERP.Contracts.Features.Authentication
{
    public class DeviceContextRequest
    {
        [Required, StringLength(50)] public string AppVersion { get; set; }
        [StringLength(50)] public string AppBuild { get; set; }
        [Required] public MobileLoginDevice Device { get; set; }

        public bool NormalizeAndValidate()
        {
            var model = new MobileLoginRequest { Username = "context", Password = "context", AppVersion = AppVersion, AppBuild = AppBuild, Device = Device };
            if (!model.NormalizeAndValidate()) return false;
            AppVersion = model.AppVersion;
            AppBuild = model.AppBuild;
            return true;
        }
    }

    public sealed class VerifyOtpRequest
    {
        public Guid ChallengeID { get; set; }
        [Required]
#if DEBUG
        [RegularExpression("^(?:[0-9]{6}|12345)$")]
#else
        [RegularExpression("^[0-9]{6}$")]
#endif
        public string OTP { get; set; }
        [Required, RegularExpression("^(registration|device-replacement|password-reset)$")] public string Purpose { get; set; }
    }

    public sealed class OtpChallengeResponse
    {
        public Guid ChallengeID { get; set; }
        public string Purpose { get; set; }
        public string Message { get; set; }
        public int ExpiresInSeconds { get; set; } = 600;
        public int ResendAfterSeconds { get; set; } = 60;
    }

    public sealed class OtpVerificationResponse
    {
        public bool Verified { get; set; }
        public string Purpose { get; set; }
        public bool? DeviceRegistered { get; set; }
        public bool? LoginRequired { get; set; }
        public string ResetToken { get; set; }
        public int? ExpiresInSeconds { get; set; }
    }

    public sealed class BiometricEnrollmentRequest
    {
        [Required, StringLength(1024)] public string Password { get; set; }
        // RSA public key in JWK representation. Private keys never leave the device.
        [Required, StringLength(684, MinimumLength = 342)] public string Modulus { get; set; }
        [Required, RegularExpression("^AQAB$")] public string Exponent { get; set; }
    }

    public sealed class BiometricCredentialResponse
    {
        public Guid CredentialID { get; set; }
        public string Algorithm { get; set; } = "RS256";
    }

    public sealed class BiometricChallengeRequest : DeviceContextRequest
    {
        public Guid CredentialID { get; set; }
    }

    public sealed class BiometricLoginRequest : DeviceContextRequest
    {
        public Guid CredentialID { get; set; }
        public Guid ChallengeID { get; set; }
        [Required, StringLength(684, MinimumLength = 342)] public string Signature { get; set; }
    }

    public sealed class BiometricChallengeResponse
    {
        public Guid ChallengeID { get; set; }
        public Guid CredentialID { get; set; }
        public string Challenge { get; set; }
        public string Algorithm { get; set; } = "RS256";
        public int ExpiresInSeconds { get; set; } = 120;
    }
}
