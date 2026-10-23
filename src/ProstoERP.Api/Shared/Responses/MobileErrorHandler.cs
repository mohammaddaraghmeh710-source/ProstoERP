using System.IO;
using System.Net.Mail;
using System.Net.Sockets;
using System.Threading.Tasks;
using MailKit.Net.Smtp;
using MailKit.Security;
using ProstoERP.Contracts.Features.PasswordReset;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using Newtonsoft.Json;
using Prosto_ERP_API.Mobile;
using ProstoERP.Application.Errors;
namespace Prosto_ERP_API.Responses
{
    internal static class MobileErrorHandler
    {
        internal static HttpResponseMessage Users(HttpRequestMessage request, Func<HttpResponseMessage> action)
        {
            try
            {
                return action();
            }
            catch (MobileBusinessException ex)
            {
                return MobileApiSupport.Error(request, ex.Status, ex.Code, ex.Message);
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
                var response = MobileApiSupport.Error(request, error.Item1, error.Item2, error.Item3);
                if (error.Item1 == HttpStatusCode.Unauthorized)
                {
                    response.Headers.WwwAuthenticate.Clear();
                    response.Headers.WwwAuthenticate.Add(new AuthenticationHeaderValue("Basic"));
                }

                return response;
            }
            catch (SqlException ex) when (ex.Number == 51710)
            {
                return MobileApiSupport.Error(request, HttpStatusCode.Forbidden, "DEVICE_APPROVAL_REQUIRED",
                    "لا يمكنك تسجيل الدخول من جهاز غير معتمد. يمكنك إرسال طلب للسماح بهذا الجهاز إلى مدير النظام.");
            }
            catch (SqlException ex) when (ex.Number == 51713)
            {
                return MobileApiSupport.Error(request, (HttpStatusCode)429, "DEVICE_REQUEST_LIMIT",
                    "لديك طلبات أجهزة قيد المراجعة. يرجى انتظار قرار مدير النظام.");
            }
            catch (Exception ex)
            {
                Trace.TraceError("Mobile API request failed ({0}).", ex.GetType().Name);
                return MobileApiSupport.Error(request, HttpStatusCode.InternalServerError, "SERVER_ERROR",
                    "Unable to complete the request.");
            }
        }

        internal static HttpResponseMessage Mobile(HttpRequestMessage request, Func<HttpResponseMessage> action)
        {
            try
            {
                return action();
            }
            catch (MobileBusinessException ex)
            {
                return MobileApiSupport.Error(request, ex.Status, ex.Code, ex.Message);
            }
            catch (SqlException ex) when (ex.Number == 51953)
            {
                return MobileApiSupport.Error(request, HttpStatusCode.Forbidden, "BRAND_ACCESS_DENIED",
                    "العلامة المطلوبة غير متاحة أو لا تطابق علامة الموظف الحالية.");
            }
            catch (SqlException ex) when (ex.Number == 51710)
            {
                return MobileApiSupport.Error(request, HttpStatusCode.Forbidden, "DEVICE_APPROVAL_REQUIRED",
                    "لا يمكنك تسجيل الدخول من جهاز غير معتمد. يمكنك إرسال طلب للسماح بهذا الجهاز إلى مدير النظام.");
            }
            catch (SqlException ex) when (ex.Number == 51713)
            {
                return MobileApiSupport.Error(request, (HttpStatusCode)429, "DEVICE_REQUEST_LIMIT",
                    "لديك طلبات أجهزة قيد المراجعة. يرجى انتظار قرار مدير النظام.");
            }
            catch (Exception ex)
            {
                Trace.TraceError("Mobile API request failed ({0}).", ex.GetType().Name);
                return MobileApiSupport.Error(request, HttpStatusCode.InternalServerError, "SERVER_ERROR",
                    "Unable to complete the request.");
            }
        }

        internal static HttpResponseMessage Circulars(HttpRequestMessage request, Func<HttpResponseMessage> action)
        {
            try
            {
                return action();
            }
            catch (SqlException e) when (e.Number >= 51800 && e.Number <= 51809)
            {
                if (e.Number == 51804)
                    return MobileApiSupport.Error(request, HttpStatusCode.NotFound, "CIRCULAR_UNAVAILABLE",
                        "التعميم غير متاح أو خارج فترة الصلاحية.");
                if (e.Number == 51803)
                    return MobileApiSupport.Error(request, HttpStatusCode.Forbidden, "DOWNLOAD_NOT_ALLOWED",
                        "تنزيل هذا التعميم غير مسموح.");
                if (e.Number == 51801)
                    return MobileApiSupport.Error(request, HttpStatusCode.Forbidden, "ACCESS_DENIED",
                        "لا تملك صلاحية الوصول بهذه الهوية.");
                if (e.Number == 51809)
                    return MobileApiSupport.Error(request, HttpStatusCode.Conflict, "EVENT_CONFLICT",
                        "معرف العملية مستخدم لعملية مختلفة. حدّث البيانات.");
                return MobileApiSupport.Error(request, HttpStatusCode.BadRequest, "INVALID_REQUEST", "بيانات الطلب غير صحيحة.");
            }
            catch (Exception e)
            {
                Trace.TraceError("Circular API failed ({0}).", e.GetType().Name);
                return MobileApiSupport.Error(request, HttpStatusCode.InternalServerError, "SERVER_ERROR",
                    "تعذر تنفيذ الطلب.");
            }
        }

        internal static HttpResponseMessage Feedback(HttpRequestMessage request, Exception ex)
        {
            var known = ex as FeedbackException;
            if (known != null) return MobileApiSupport.Error(request, known.Status, known.Code, known.Message);
            var sql = ex as SqlException;
            if (sql != null)
            {
                if (sql.Number == 51801)
                    return MobileApiSupport.Error(request, HttpStatusCode.Forbidden, "EMPLOYEE_MISMATCH", sql.Message);
                if (sql.Number == 51500)
                    return MobileApiSupport.Error(request, HttpStatusCode.BadRequest, "BUSINESS_RULE", sql.Message);
                if (sql.Number == 51802 || sql.Number == 1205)
                    return MobileApiSupport.Error(request, HttpStatusCode.Conflict, "RETRY_OPERATION",
                        "أعد المحاولة بنفس رقم العملية.");
            }

            if (ex is JsonException || ex is ArgumentException || ex is FormatException)
                return MobileApiSupport.Error(request, HttpStatusCode.BadRequest, "INVALID_REQUEST",
                    "تحقق من البيانات وصيغة الملفات والتاريخ.");
            Trace.TraceError("Feedback API failed ({0}).", ex.GetType().Name);
            return MobileApiSupport.Error(request, HttpStatusCode.InternalServerError, "SERVER_ERROR",
                "تعذر إتمام العملية. أعد المحاولة بنفس رقم العملية.");
        }

        internal static HttpResponseMessage Correspondence(HttpRequestMessage request, Exception ex)
        {
            var known = ex as FeedbackException;
            if (known != null) return MobileApiSupport.Error(request, known.Status, known.Code, known.Message);
            var sql = ex as SqlException;
            if (sql != null)
            {
                if (sql.Number == 51801)
                    return MobileApiSupport.Error(request, HttpStatusCode.Forbidden, "EMPLOYEE_MISMATCH", sql.Message);
                if (sql.Number == 51400)
                    return MobileApiSupport.Error(request, HttpStatusCode.BadRequest, "BUSINESS_RULE", sql.Message);
                if (sql.Number == 51802 || sql.Number == 1205)
                    return MobileApiSupport.Error(request, HttpStatusCode.Conflict, "RETRY_OPERATION",
                        "أعد المحاولة بنفس رقم العملية.");
            }

            if (ex is JsonException || ex is ArgumentException || ex is FormatException)
                return MobileApiSupport.Error(request, HttpStatusCode.BadRequest, "INVALID_REQUEST",
                    "تحقق من الحقول وصيغة التاريخ والملفات.");
            Trace.TraceError("Correspondence API failed ({0}).", ex.GetType().Name);
            return MobileApiSupport.Error(request, HttpStatusCode.InternalServerError, "SERVER_ERROR",
                "تعذر إتمام العملية. أعد المحاولة بنفس رقم العملية.");
        }

        internal static HttpResponseMessage CustomerFeedback(HttpRequestMessage request, Exception ex, int retryAfter)
        {
            HttpResponseMessage response;
            var known = ex as FeedbackException;
            var sql = ex as SqlException;
            if (known != null)
            {
                response = MobileApiSupport.Error(request, known.Status, known.Code, known.Message);
            }
            else if (sql != null && sql.Number == 51500)
            {
                response = MobileApiSupport.Error(request, HttpStatusCode.BadRequest, "BUSINESS_RULE", sql.Message);
            }
            else if (sql != null && (sql.Number == 51802 || sql.Number == 1205))
            {
                response = MobileApiSupport.Error(request, HttpStatusCode.Conflict, "RETRY_OPERATION",
                    "أعد المحاولة بنفس رقم العملية.");
            }
            else if (ex is JsonException || ex is ArgumentException || ex is FormatException)
            {
                response = MobileApiSupport.Error(request, HttpStatusCode.BadRequest, "INVALID_REQUEST",
                    "تحقق من بيانات الطلب والملفات.");
            }
            else
            {
                Trace.TraceError("Customer feedback API failed ({0}).", ex.GetType().Name);
                response = MobileApiSupport.Error(request, HttpStatusCode.InternalServerError, "SERVER_ERROR",
                    "تعذر إتمام العملية. أعد المحاولة بنفس رقم العملية.");
            }

            if (retryAfter > 0)
                response.Headers.RetryAfter = new RetryConditionHeaderValue(TimeSpan.FromSeconds(retryAfter));
            return response;
        }

        internal static HttpResponseMessage CustomerPortal(HttpRequestMessage request, Exception ex, int retryAfter)
        {
            var known = ex as FeedbackException;
            var sql = ex as SqlException;
            HttpResponseMessage response;
            if (known != null)
            {
                response = MobileApiSupport.Error(request, known.Status, known.Code, known.Message);
            }
            else if (sql != null && sql.Number == 51911)
            {
                response = MobileApiSupport.Error(request, HttpStatusCode.Unauthorized, "SESSION_INVALID",
                    "يلزم تسجيل الدخول مجددًا.");
            }
            else if (sql != null && sql.Number == 51912)
            {
                response = MobileApiSupport.Error(request, HttpStatusCode.NotFound, "NOT_FOUND", "الطلب غير متاح لك.");
            }
            else if (sql != null && (sql.Number == 51910 || sql.Number == 51500 ||
                                     (sql.Number >= 51100 && sql.Number <= 51109)))
            {
                response = MobileApiSupport.Error(request, HttpStatusCode.BadRequest, "BUSINESS_RULE", sql.Message);
            }
            else if (sql != null && (sql.Number == 51802 || sql.Number == 1205))
            {
                response = MobileApiSupport.Error(request, HttpStatusCode.Conflict, "RETRY_OPERATION",
                    "أعد المحاولة بنفس رقم العملية.");
            }
            else if (ex is JsonException || ex is ArgumentException || ex is FormatException)
            {
                response = MobileApiSupport.Error(request, HttpStatusCode.BadRequest, "INVALID_REQUEST",
                    "تحقق من بيانات الطلب.");
            }
            else
            {
                Trace.TraceError("Customer API failed ({0}).", ex.GetType().Name);
                response = MobileApiSupport.Error(request, HttpStatusCode.InternalServerError, "SERVER_ERROR",
                    "تعذر إتمام العملية.");
            }

            if (retryAfter > 0)
                response.Headers.RetryAfter = new RetryConditionHeaderValue(TimeSpan.FromSeconds(retryAfter));
            return response;
        }
        internal static async Task<HttpResponseMessage> PasswordReset(HttpRequestMessage request, Func<Task<object>> action, string message)
        {
            try
            {
                return ApiResponseHandler.Body(request, new PasswordResetResponse<object> { Success = true, Data = await action(), Message = message });
            }
            catch (ResetException ex)
            {
                return PasswordResetError(request, ex.Status, ex.Code, ex.Message);
            }
            catch (SqlException ex) when (ex.Number >= 51900 && ex.Number <= 51903)
            {
                var codes = new[] { "RESET_RATE_LIMITED", "OTP_UNAVAILABLE", "OTP_INVALID", "RESET_TOKEN_INVALID" };
                var messages = new[]
                {
                    "انتظر دقيقة بين الطلبات؛ الحد الأقصى 5 طلبات في الساعة.",
                    "انتهت صلاحية الرمز أو تم استخدامه أو تجاوز عدد المحاولات. اطلب رمزًا جديدًا.",
                    "رمز التحقق غير صحيح. لديك 5 محاولات كحد أقصى.",
                    "تصريح تغيير كلمة المرور غير صالح أو منتهي. ابدأ الاستعادة مجددًا."
                };
                return PasswordResetError(request, ex.Number == 51900 ? (HttpStatusCode)429 : HttpStatusCode.BadRequest,
                    codes[ex.Number - 51900], messages[ex.Number - 51900]);
            }
            catch (OperationCanceledException)
            {
                return PasswordResetError(request, HttpStatusCode.GatewayTimeout, "SMTP_TIMEOUT",
                    "انتهت مهلة الإرسال. تحقق من بريدك قبل إعادة المحاولة.");
            }
            catch (TimeoutException)
            {
                return PasswordResetError(request, HttpStatusCode.GatewayTimeout, "SMTP_TIMEOUT",
                    "انتهت مهلة الإرسال. أعد المحاولة بعد دقيقة.");
            }
            catch (AuthenticationException)
            {
                return PasswordResetError(request, HttpStatusCode.BadGateway, "SMTP_AUTH_FAILED",
                    "تعذّر تسجيل الدخول إلى بريد العلامة التجارية. يرجى التواصل مع مدير النظام.");
            }
            catch (SslHandshakeException)
            {
                return PasswordResetError(request, HttpStatusCode.BadGateway, "SMTP_TLS_FAILED", "تعذّر الاتصال الآمن بخدمة البريد.");
            }
            catch (SmtpCommandException)
            {
                return PasswordResetError(request, HttpStatusCode.BadGateway, "SMTP_SEND_FAILED",
                    "رفض خادم البريد إرسال رمز التحقق. يرجى التواصل مع مدير النظام.");
            }
            catch (SmtpProtocolException)
            {
                return PasswordResetError(request, HttpStatusCode.BadGateway, "SMTP_SEND_FAILED", "انقطع اتصال خدمة البريد.");
            }
            catch (IOException)
            {
                return PasswordResetError(request, HttpStatusCode.BadGateway, "SMTP_CONNECTION_FAILED", "تعذّر الاتصال بخدمة البريد.");
            }
            catch (SocketException)
            {
                return PasswordResetError(request, HttpStatusCode.BadGateway, "SMTP_CONNECTION_FAILED", "تعذّر الاتصال بخدمة البريد.");
            }
            catch (SmtpException)
            {
                return PasswordResetError(request, HttpStatusCode.BadGateway, "SMTP_SEND_FAILED", "تعذّر إرسال رمز التحقق عبر البريد.");
            }
            catch (Exception ex)
            {
                Trace.TraceError("Password reset failed ({0}).", ex.GetType().Name);
                return PasswordResetError(request, HttpStatusCode.ServiceUnavailable, "RESET_SERVICE_UNAVAILABLE",
                    "خدمة استعادة كلمة المرور غير متاحة حاليًا. يرجى التواصل مع مدير النظام.");
            }
        }
        internal static HttpResponseMessage PasswordResetError(HttpRequestMessage request, HttpStatusCode status, string code, string message)
        {
            var response = MobileApiSupport.Error(request, status, code, message);
            response.Headers.WwwAuthenticate.Clear();
            return response;
        }
    }
}
