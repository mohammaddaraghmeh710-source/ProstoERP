using System;

namespace ProstoERP.Contracts.Features.PasswordReset
{
    public sealed class ResetChallengeResponse
    {
        public Guid ChallengeID { get; set; }
        public string MaskedEmail { get; set; }
        public int ExpiresInSeconds { get; set; }
        public int ResendAfterSeconds { get; set; }
    }
    public sealed class ResetVerificationResponse
    {
        public string ResetToken { get; set; }
        public int ExpiresInSeconds { get; set; }
    }
    public sealed class ResetCompletionResponse
    {
        public bool PasswordChanged { get; set; }
    }
    public sealed class PasswordResetResponse<T>
    {
        public bool Success { get; set; }
        public T Data { get; set; }
        public string Message { get; set; }
    }
}
