using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Globalization;
using System.Net;
using System.Text.RegularExpressions;
using Prosto_ERP_API.Mobile;
namespace ProstoERP.Application.Validation
{
    public static class MobileValidation
    {
        public static DateTimeOffset ParseTime(string value)
        {
            DateTimeOffset parsed;
            if (value == null || !Regex.IsMatch(value, @"(?:Z|[+-]\d{2}:\d{2})$") ||
                !DateTimeOffset.TryParse(value, CultureInfo.InvariantCulture, DateTimeStyles.None, out parsed))
                throw Invalid();
            return parsed;
        }
        public static void ValidateOperation(Guid operation, string occurredAt)
        {
            var time = ParseTime(occurredAt);
            if (operation == Guid.Empty || time.Year < 2000 || time > DateTimeOffset.UtcNow.AddMinutes(5))
                throw Invalid();
        }
        public static FeedbackException Invalid()
        {
            return new FeedbackException(HttpStatusCode.BadRequest, "INVALID_REQUEST",
                "تحقق من الحقول المطلوبة والقيم المرسلة.");
        }
        public static bool IsValidModel(object model)
        {
            return Validator.TryValidateObject(model, new ValidationContext(model), new List<ValidationResult>(), true);
        }
        public static void RequirePage(int page, int size, int maximumPage)
        {
            if (page < 1 || page > maximumPage || size < 1 || size > 100) throw Invalid();
        }
    }
}
