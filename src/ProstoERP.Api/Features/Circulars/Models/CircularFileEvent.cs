using System;
using System.ComponentModel.DataAnnotations;

namespace Prosto_ERP_API.Mobile
{
    public sealed class CircularFileEvent
    {
        [Range(1,int.MaxValue)] public int EmployeeNumber {get;set;}
        [Required] public string Action {get;set;}
        public Guid EventID {get;set;}
        public DateTimeOffset? OccurredAt {get;set;}
    }
}
