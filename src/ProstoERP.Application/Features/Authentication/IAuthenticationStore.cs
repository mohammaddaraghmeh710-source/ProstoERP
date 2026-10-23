using System;
using System.Data;
using System.Threading.Tasks;
using Prosto_ERP_API.Mobile;
using ProstoERP.Contracts.Features.Authentication;

namespace ProstoERP.Application.Features.Authentication
{
    public sealed class OtpRecipient
    {
        public int BrandID { get; set; }
        public string Email { get; set; }
        public string EmployeeName { get; set; }
        public string BrandName { get; set; }
    }

    public interface IAuthenticationStore
    {
        void CheckRate(string scope, byte[] account, byte[] source);
        OtpRecipient BeginRegistration(Guid id, MobileLoginRequest model, string encryptedPassword, byte[] otpHash, string purpose);
        void RegistrationDelivery(Guid id, bool sent);
        void VerifyRegistration(Guid id, byte[] otpHash, string purpose);
        void Logout(byte[] tokenHash);
        void UpdateDevice(byte[] tokenHash, DeviceContextRequest model);
        void EnrollBiometric(Guid credential, byte[] tokenHash, string encryptedPassword, string modulus, string exponent);
        void BeginBiometric(Guid id, Guid credential, byte[] binding, string challenge, DeviceContextRequest device);
        DataRow ConsumeBiometric(Guid id, Guid credential, byte[] binding);
        DataSet BiometricLogin(Guid credential, byte[] tokenHash, int idleMinutes, int maximumMinutes, DeviceContextRequest device);
    }

    public interface IAuthenticationSecurity
    {
        byte[] Hash(string value);
        string Otp();
        bool IsOtpAllowed(string code);
        bool ValidPublicKey(string modulus, string exponent);
        bool Verify(string modulus, string exponent, string challenge, string signature);
    }

    public interface IAuthenticationOtpSender
    {
        Task Send(OtpRecipient recipient, string code, string purpose);
    }
    public interface IPasswordRecoveryDispatcher
    {
        void Dispatch(int employee, string source, Guid challengeId);
    }
}
