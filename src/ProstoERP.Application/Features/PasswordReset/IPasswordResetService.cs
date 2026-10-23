using System;
using System.Threading.Tasks;
namespace ProstoERP.Application.Features.PasswordReset
{
    public interface IPasswordResetService
    {
        Task<object> Request(int employee, string source, Guid? challengeId = null);
        object Verify(Guid id, string otp);
        object Complete(string token, string password);
    }
}
