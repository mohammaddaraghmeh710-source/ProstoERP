using System;
using System.ComponentModel.DataAnnotations;

namespace Prosto_ERP_API.Mobile
{
    public sealed class CustomerPortalLogin
    {
        [Required] [StringLength(100)] public string Username { get; set; }
        [Required] [StringLength(128)] public string Password { get; set; }
    }

    public sealed class CustomerPortalFeedbackCreate
    {
        public Guid OperationID { get; set; }
        [Range(1, int.MaxValue)] public int TypeID { get; set; }
        [Range(1, int.MaxValue)] public int TopicID { get; set; }
        [Range(1, int.MaxValue)] public int BrandID { get; set; }
        [Range(1, int.MaxValue)] public int BranchID { get; set; }

        [Required]
        [StringLength(30)]
        [RegularExpression(@"\+?[0-9][0-9 ()-]{5,28}")]
        public string Mobile { get; set; }

        [Required] [StringLength(300)] public string Title { get; set; }
        [Required] [StringLength(10000)] public string Details { get; set; }
    }
}
