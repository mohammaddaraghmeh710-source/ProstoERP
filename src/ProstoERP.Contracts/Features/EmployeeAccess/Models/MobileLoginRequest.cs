using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text.RegularExpressions;

namespace Prosto_ERP_API.Mobile
{
    public sealed class MobileLoginRequest
    {
        [Required] [StringLength(250)] public string Username { get; set; }
        [Required] [StringLength(1024)] public string Password { get; set; }
        [Required] [StringLength(50)] public string AppVersion { get; set; }
        [StringLength(50)] public string AppBuild { get; set; }
        [Required] public MobileLoginDevice Device { get; set; }

        internal bool NormalizeAndValidate()
        {
            if (!Validator.TryValidateObject(this, new ValidationContext(this), new List<ValidationResult>(), true) ||
                Device == null ||
                !Validator.TryValidateObject(Device, new ValidationContext(Device), new List<ValidationResult>(), true))
                return false;
            Username = Username.Trim();
            AppVersion = AppVersion.Trim();
            AppBuild = Clean(AppBuild);
            Device.DeviceID = Device.DeviceID.Trim();
            Device.Model = Device.Model.Trim();
            Device.OSVersion = Device.OSVersion.Trim();
            Device.Manufacturer = Clean(Device.Manufacturer);
            if (string.Equals(Device.Platform, "Android", StringComparison.OrdinalIgnoreCase))
                Device.Platform = "Android";
            else if (string.Equals(Device.Platform, "iOS", StringComparison.OrdinalIgnoreCase)) Device.Platform = "iOS";
            else return false;
            var mac = Clean(Device.MACID);
            if (mac != null)
            {
                if (!Regex.IsMatch(mac,
                        @"\A(?:[0-9a-fA-F]{12}|(?:[0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}|(?:[0-9a-fA-F]{2}-){5}[0-9a-fA-F]{2})\z"))
                    return false;
                mac = mac.Replace(":", "").Replace("-", "").ToUpperInvariant();
                // Common OS privacy placeholders are not real device MAC addresses.
                Device.MACID = new[] { "000000000000", "020000000000", "FFFFFFFFFFFF" }.Contains(mac)
                    ? null
                    : string.Join(":", Enumerable.Range(0, 6).Select(i => mac.Substring(i * 2, 2)));
            }
            else
            {
                Device.MACID = null;
            }

            return true;
        }

        private static string Clean(string value)
        {
            return string.IsNullOrWhiteSpace(value) ? null : value.Trim();
        }
    }

    public sealed class MobileLoginDevice
    {
        [Required] [StringLength(128)] public string DeviceID { get; set; }
        [Required] [StringLength(16)] public string Platform { get; set; }
        [StringLength(100)] public string Manufacturer { get; set; }
        [Required] [StringLength(150)] public string Model { get; set; }
        [Required] [StringLength(50)] public string OSVersion { get; set; }
        [StringLength(32)] public string MACID { get; set; }
    }
}
