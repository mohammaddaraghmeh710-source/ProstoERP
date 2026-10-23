using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Prosto_ERP_API.Mobile
{
    public class ResetInput
    {
        [JsonExtensionData] public IDictionary<string, JToken> Extra { get; set; }

        [JsonIgnore] public bool HasExtra => Extra != null && Extra.Count != 0;
    }

    public sealed class ResetRequest : ResetInput
    {
        [Range(1, int.MaxValue)] public int EmployeeNumber { get; set; }
    }

    public sealed class VerifyResetRequest : ResetInput
    {
        public Guid ChallengeID { get; set; }

        [Required]
#if DEBUG
        [RegularExpression("^(?:[0-9]{6}|12345)$")]
#else
        [RegularExpression("^[0-9]{6}$")]
#endif
        public string OTP { get; set; }
    }

    public sealed class CompleteResetRequest : ResetInput
    {
        [Required] public string ResetToken { get; set; }

        [Required]
        [StringLength(128, MinimumLength = 8)]
        public string NewPassword { get; set; }
    }
}
