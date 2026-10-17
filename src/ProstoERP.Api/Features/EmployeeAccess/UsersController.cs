using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Web.Http;
using Echo.Encrptor;
using Prosto_ERP_API.Authentication;
using Prosto_ERP_API.Responses;

namespace Prosto_ERP_API.Mobile
{
    [MobileTransport]
    [RoutePrefix("api/Users")]
    public sealed partial class UsersController : ApiController
    {
        [HttpPost]
        [Route("Login")]
        public HttpResponseMessage Login([FromBody] MobileLoginRequest model)
        {
            if (model == null || !ModelState.IsValid || !model.NormalizeAndValidate())
                return MobileApiSupport.Error(Request, HttpStatusCode.BadRequest, "INVALID_REQUEST",
                    "Username, Password, AppVersion and valid Device information are required.");
            return Execute(() =>
            {
                var token = MobileApiSupport.NewToken();
                var bioID = MobileApiSupport.NewToken();
                var password = new TripleDesEncryptor().Encrypt(model.Password);
                var result = MobileApiSupport.Query("dbo.MobileApi_Login",
                    MobileApiSupport.P("@Username", SqlDbType.NVarChar, model.Username.Trim(), 250),
                    MobileApiSupport.P("@EncryptedPassword", SqlDbType.NVarChar, password, -1),
                    MobileApiSupport.P("@TokenHash", SqlDbType.Binary, MobileApiSupport.TokenHash(token), 32),
                    MobileApiSupport.P("@IdleMinutes", SqlDbType.Int, MobileApiSupport.IdleMinutes),
                    MobileApiSupport.P("@MaximumMinutes", SqlDbType.Int, MobileApiSupport.MaximumMinutes),
                    MobileApiSupport.P("@AppVersion", SqlDbType.NVarChar, model.AppVersion, 50),
                    MobileApiSupport.P("@AppBuild", SqlDbType.NVarChar, model.AppBuild, 50),
                    MobileApiSupport.P("@DeviceID", SqlDbType.NVarChar, model.Device.DeviceID, 128),
                    MobileApiSupport.P("@DevicePlatform", SqlDbType.NVarChar, model.Device.Platform, 16),
                    MobileApiSupport.P("@DeviceManufacturer", SqlDbType.NVarChar, model.Device.Manufacturer, 100),
                    MobileApiSupport.P("@DeviceModel", SqlDbType.NVarChar, model.Device.Model, 150),
                    MobileApiSupport.P("@OSVersion", SqlDbType.NVarChar, model.Device.OSVersion, 50),
                    MobileApiSupport.P("@MACID", SqlDbType.VarChar, model.Device.MACID, 17),
                    MobileApiSupport.P("@BIOHash", SqlDbType.Binary, MobileApiSupport.TokenHash(bioID), 32));
                if (result.Tables.Count == 0 || result.Tables[0].Rows.Count == 0)
                    return MobileApiSupport.Error(Request, HttpStatusCode.Unauthorized, "INVALID_CREDENTIALS",
                        "Invalid credentials or inactive account.");
                return LoginResponse(result, token, bioID);
            });
        }

        [HttpPost]
        [Route("LoginViaBIO")]
        [IntegrationBasicAuthentication]
        public HttpResponseMessage LoginViaBIO([FromBody] BioLoginRequest model)
        {
            if (model == null || !ModelState.IsValid || (model.Extra != null && model.Extra.Count != 0) ||
                MobileApiSupport.TokenHash(model.BIOID) == null)
                return MobileApiSupport.Error(Request, HttpStatusCode.BadRequest, "INVALID_BIOID_FORMAT",
                    "يجب إرسال BIOID صالح فقط في جسم الطلب.");
            return Execute(() =>
            {
                var token = MobileApiSupport.NewToken();
                var result = MobileApiSupport.Query("dbo.MobileApi_LoginViaBIO",
                    MobileApiSupport.P("@BIOHash", SqlDbType.Binary, MobileApiSupport.TokenHash(model.BIOID), 32),
                    MobileApiSupport.P("@TokenHash", SqlDbType.Binary, MobileApiSupport.TokenHash(token), 32),
                    MobileApiSupport.P("@IdleMinutes", SqlDbType.Int, MobileApiSupport.IdleMinutes),
                    MobileApiSupport.P("@MaximumMinutes", SqlDbType.Int, MobileApiSupport.MaximumMinutes));
                return LoginResponse(result, token, model.BIOID);
            });
        }

        private HttpResponseMessage LoginResponse(DataSet result, string token, string bioID)
        {
            var user = EmployeeProfile(result.Tables[0].Rows[0]);
            user["User_Image"] = MobileApiSupport.AssetUrl(user["User_Image"]);
            user["BIOID"] = bioID;
            var session = MobileApiSupport.Row(result.Tables[1].Rows[0]);
            foreach (var name in new[] { "DeviceManufacturer", "MACID", "AppBuild" })
                if (session[name] == null || string.IsNullOrEmpty(Convert.ToString(session[name])))
                    session.Remove(name);
            return ApiResponseHandler.Success(Request, new
            {
                User = user, AccessToken = token, TokenType = "Bearer",
                ExpiresAt = session["ExpiresAt"], AbsoluteExpiresAt = session["AbsoluteExpiresAt"],
                IdleTimeoutMinutes = MobileApiSupport.IdleMinutes, Session = session
            });
        }

        [HttpPost]
        [Route("AddNewDevices")]
        public HttpResponseMessage Add_New_Devices([FromBody] MobileLoginRequest model)
        {
            return DeviceAccess(model, true);
        }

        private HttpResponseMessage DeviceAccess(MobileLoginRequest model, bool submit)
        {
            if (model == null || !ModelState.IsValid || !model.NormalizeAndValidate())
                return MobileApiSupport.Error(Request, HttpStatusCode.BadRequest, "INVALID_REQUEST",
                    "بيانات الدخول والجهاز وإصدار التطبيق مطلوبة.");
            return Execute(() =>
            {
                var result = MobileApiSupport.QueryDeviceAccess(model, submit);
                if (result.Tables.Count == 0 || result.Tables[0].Rows.Count == 0)
                    return MobileApiSupport.Error(Request, HttpStatusCode.Unauthorized, "INVALID_CREDENTIALS",
                        "بيانات الدخول غير صحيحة أو الحساب غير فعال.");
                return ApiResponseHandler.Success(Request, MobileApiSupport.Row(result.Tables[0].Rows[0]));
            });
        }

        // Explicit public DTO: new database columns never leak into employee responses.
        private static Dictionary<string, object> EmployeeProfile(DataRow row)
        {
            var data = MobileApiSupport.Row(row);
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
            return profile;
        }

        private static object Lookup(Dictionary<string, object> data, string id, string prefix)
        {
            if (data[id] == null) return null;
            return new { ID = data[id], Title_Ar = data[prefix + "_Ar"], Title_En = data[prefix + "_En"] };
        }

        // Retained for the password-reset partial controller's existing response shape.
        private HttpResponseMessage Success(object body)
        {
            var response = Request.CreateResponse(HttpStatusCode.OK, body);
            MobileApiSupport.NoCache(response);
            return response;
        }

        private HttpResponseMessage Execute(Func<HttpResponseMessage> action)
        {
            try
            {
                return action();
            }
            catch (SqlException ex) when (ex.Number >= 51720 && ex.Number <= 51727)
            {
                var errors = new Dictionary<int, Tuple<HttpStatusCode, string, string>>
                {
                    {
                        51720,
                        Tuple.Create(HttpStatusCode.Unauthorized, "BIOID_INVALID",
                            "BIOID غير صحيح أو تم استبداله. سجّل الدخول بكلمة المرور.")
                    },
                    {
                        51721,
                        Tuple.Create(HttpStatusCode.Unauthorized, "BIOID_EXPIRED",
                            "انتهت صلاحية BIOID. سجّل الدخول بكلمة المرور لتفعيله مجددًا.")
                    },
                    {
                        51722,
                        Tuple.Create(HttpStatusCode.Unauthorized, "BIOID_REVOKED",
                            "أُلغي دخول هذا الجهاز. سجّل الدخول بكلمة المرور بعد اعتماده مجددًا.")
                    },
                    {
                        51723,
                        Tuple.Create(HttpStatusCode.Forbidden, "ACCOUNT_INACTIVE",
                            "حساب الموظف موقوف. راجع مدير النظام.")
                    },
                    {
                        51724,
                        Tuple.Create(HttpStatusCode.Forbidden, "ACCOUNT_DELETED",
                            "حساب الموظف محذوف ولا يمكن تسجيل الدخول.")
                    },
                    {
                        51725,
                        Tuple.Create(HttpStatusCode.Unauthorized, "PASSWORD_CHANGED",
                            "تغيّرت كلمة مرور الموظف. سجّل الدخول بكلمة المرور الجديدة.")
                    },
                    {
                        51726,
                        Tuple.Create(HttpStatusCode.Forbidden, "DEVICE_NOT_APPROVED",
                            "هذا الجهاز غير معتمد أو أُلغي اعتماده. راجع مدير النظام.")
                    },
                    {
                        51727,
                        Tuple.Create(HttpStatusCode.Forbidden, "ACCOUNT_TYPE_NOT_ALLOWED",
                            "هذا الحساب غير مخوّل للدخول كتطبيق موظف.")
                    }
                };
                var error = errors[ex.Number];
                var response = MobileApiSupport.Error(Request, error.Item1, error.Item2, error.Item3);
                if (error.Item1 == HttpStatusCode.Unauthorized)
                {
                    response.Headers.WwwAuthenticate.Clear();
                    response.Headers.WwwAuthenticate.Add(new AuthenticationHeaderValue("Basic"));
                }

                return response;
            }
            catch (SqlException ex) when (ex.Number == 51710)
            {
                return MobileApiSupport.Error(Request, HttpStatusCode.Forbidden, "DEVICE_APPROVAL_REQUIRED",
                    "لا يمكنك تسجيل الدخول من جهاز غير معتمد. يمكنك إرسال طلب للسماح بهذا الجهاز إلى مدير النظام.");
            }
            catch (SqlException ex) when (ex.Number == 51713)
            {
                return MobileApiSupport.Error(Request, (HttpStatusCode)429, "DEVICE_REQUEST_LIMIT",
                    "لديك طلبات أجهزة قيد المراجعة. يرجى انتظار قرار مدير النظام.");
            }
            catch (Exception ex)
            {
                Trace.TraceError("Mobile API request failed ({0}).", ex.GetType().Name);
                return MobileApiSupport.Error(Request, HttpStatusCode.InternalServerError, "SERVER_ERROR",
                    "Unable to complete the request.");
            }
        }
    }
}
