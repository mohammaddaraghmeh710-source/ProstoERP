using System;
using System.Collections.Generic;
using System.Data;
using System.Net;
using Newtonsoft.Json.Linq;
using Prosto_ERP_API.Mobile;
using ProstoERP.Application.Abstractions;
using ProstoERP.Application.Data;
using ProstoERP.Application.Errors;
using ProstoERP.Contracts.Features.EmployeeAccess;

namespace ProstoERP.Application.Features.EmployeeAccess
{
    public sealed class EmployeeAccessService
    {
        private readonly IEmployeeAccessStore store;
        private readonly IMobileOptions options;
        private readonly IMobileTokenService tokens;
        private readonly IPasswordCipher cipher;
        private readonly IAssetUrlBuilder assets;

        public EmployeeAccessService(IEmployeeAccessStore store, IMobileOptions options,
            IMobileTokenService tokens, IPasswordCipher cipher, IAssetUrlBuilder assets)
        {
            this.store = store;
            this.options = options;
            this.tokens = tokens;
            this.cipher = cipher;
            this.assets = assets;
        }

        public EmployeeLoginResponse Login(MobileLoginRequest model)
        {
            var token = tokens.NewToken();
            var bioID = tokens.NewToken();
            var password = cipher.Encrypt(model.Password);
            var result = store.Login(model, password, tokens.TokenHash(token), tokens.TokenHash(bioID),
                options.IdleMinutes, options.MaximumMinutes);
            if (result.Tables.Count == 0 || result.Tables[0].Rows.Count == 0)
                throw new MobileBusinessException(HttpStatusCode.Unauthorized, "INVALID_CREDENTIALS",
                    "Invalid credentials or inactive account.");
            return LoginResponse(result, token, bioID);
        }

        public EmployeeLoginResponse LoginViaBio(BioLoginRequest model)
        {
            var token = tokens.NewToken();
            var result = store.LoginViaBio(tokens.TokenHash(model.BIOID), tokens.TokenHash(token),
                options.IdleMinutes, options.MaximumMinutes);
            return LoginResponse(result, token, model.BIOID);
        }

        public DeviceAccessResponse DeviceAccess(MobileLoginRequest model, bool submit)
        {
            var result = store.DeviceAccess(model, cipher.Encrypt(model.Password), submit);
            if (result.Tables.Count == 0 || result.Tables[0].Rows.Count == 0)
                throw new MobileBusinessException(HttpStatusCode.Unauthorized, "INVALID_CREDENTIALS",
                    "بيانات الدخول غير صحيحة أو الحساب غير فعال.");
            return JObject.FromObject(MobileRowMapper.Row(result.Tables[0].Rows[0]))
                .ToObject<DeviceAccessResponse>();
        }

        private EmployeeLoginResponse LoginResponse(DataSet result, string token, string bioID)
        {
            var user = Profile(result.Tables[0].Rows[0]);
            user.User_Image = assets.AssetUrl(user.User_Image);
            user.BIOID = bioID;
            var session = MobileRowMapper.Row(result.Tables[1].Rows[0]);
            foreach (var name in new[] { "DeviceManufacturer", "MACID", "AppBuild" })
                if (session[name] == null || string.IsNullOrEmpty(Convert.ToString(session[name])))
                    session.Remove(name);
            return new EmployeeLoginResponse
            {
                User = user, AccessToken = token, TokenType = "Bearer",
                ExpiresAt = (DateTime?)session["ExpiresAt"],
                AbsoluteExpiresAt = (DateTime?)session["AbsoluteExpiresAt"],
                IdleTimeoutMinutes = options.IdleMinutes,
                Session = JObject.FromObject(session).ToObject<EmployeeSession>()
            };
        }

        private static EmployeeProfile Profile(DataRow row)
        {
            var data = MobileRowMapper.Row(row);
            var profile = new Dictionary<string, object>();
            foreach (var name in new[]
                     {
                         "ID", "Employee_Number", "FullName_Ar", "Fullname_En", "User_Image", "PhoneNumber",
                         "MobileNumber", "Email", "UserName"
                     })
                profile[name] = data[name];
            profile["userType"] = Lookup(data, "Type", "UserType");
            profile["brand"] = Lookup(data, "Brand_ID", "Brand");
            profile["branch"] = Lookup(data, "Branch_ID", "Branch");
            profile["department"] = Lookup(data, "Department_ID", "Department");
            profile["jobTitle"] = Lookup(data, "JobTitle_ID", "JobTitle");
            profile["shift"] = Lookup(data, "Shif_ID", "Shift");
            profile["gender"] = Lookup(data, "Gender", "Gender");
            profile["nationality"] = Lookup(data, "Nationality", "Nationality");
            return JObject.FromObject(profile).ToObject<EmployeeProfile>();
        }

        private static object Lookup(Dictionary<string, object> data, string id, string prefix)
        {
            if (data[id] == null) return null;
            return new EmployeeLookup
            {
                ID = (int?)data[id], Title_Ar = (string)data[prefix + "_Ar"],
                Title_En = (string)data[prefix + "_En"]
            };
        }
    }
}
