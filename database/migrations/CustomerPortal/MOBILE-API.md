# API حساب العميل لمطور التطبيق

المسار الأساسي: `https://{host}/api/v1/customer`. هذه الخدمات لحساب العميل المسجل في CRM. تسجيل الموظف وخدماته تبقى على مساراتها الحالية. يختار التطبيق «موظف» أو «عميل» قبل تسجيل الدخول.

مدير النظام وحده ينشئ الحساب ويعيد كلمة المرور. لا يوجد تسجيل ذاتي أو تعديل صلاحيات من العميل. تُدار بيانات العميل وجهات الاتصال من إدارة العملاء، وتُعرض في لوحة العميل بعد الدخول.

## المصادقة والاستجابة

كل المسارات تتطلب HTTPS. عدا `POST login`، أرسل `Authorization: Bearer {Token}`، بما فيها روابط الملفات. لا تضع الرمز في الرابط. النجاح: `{"Success":true,"Data":...}`. الخطأ: `{"Success":false,"Error":{"Code":"...","Message":"..."}}`.

`POST login` ببيانات JSON:

```json
{"Username":"customer-name","Password":"customer-password"}
```

تعيد `Data.Token`, `TokenType`, `ExpiresUtc`, `IdleMinutes` و`Customer:{AccountID,Name}`. الجلسة تنتهي بعد 8 ساعات خمول أو 30 يومًا كحد أقصى. تعطيل العميل/حسابه أو تغيير بيانات دخوله يلغي صلاحية الجلسة. خمسة إخفاقات تقفل الحساب 15 دقيقة؛ توجد أيضًا حدود لمحاولات عنوان الاتصال (30 محاولة/15 دقيقة). `429` يتضمن `Retry-After`.

- `GET me`: هوية العميل وانتهاء الجلسة.
- `POST logout`: إبطال الرمز الحالي، دون جسم طلب.

لا تُرسل AccountID أو EmployeeNumber لتحديد صاحب العملية؛ يؤخذ العميل من الرمز. رموز العملاء والموظفين غير قابلة للتبادل.

## الشكاوى والاقتراحات

Authenticated CRM feedback options and saves require the customer's exact active brand and branch assignments. A brand without explicitly assigned branches offers no branch fallback. Identity is always disclosed, and requests route/forward only to system administrators. Public intake remains independent. The mobile detail response still exposes original request data and initial attachments only; the portal additionally shows authorized workflow/action attachments.


| الطريقة والمسار | المدخلات / الناتج |
|---|---|
| `GET feedback/options?brandID=1&typeID=1` | `Types,Brands,Branches,Topics,RecipientTitle,FileRules`؛ اقرأ المعرفات من القوائم |
| `POST feedback/requests` | multipart يحتوي `data` JSON ومرفقات `files` اختيارية |
| `GET feedback/requests?page=1&pageSize=20&status=0&search=` | سجل العميل فقط؛ 0 جميع الحالات، 1 جديد، 2 قيد المعالجة، 3 مغلق |
| `GET feedback/requests/{id}` | `Request` بتفاصيل الطلب الأصلي وحالته و`Attachments` بروابط `DownloadUrl` |
| `GET feedback/attachments/{id}` | تنزيل مرفق أصلي يخص العميل مع Bearer |

الحقول داخل جزء `data`:

```json
{
  "OperationID":"61c28f96-a96b-4bbd-972c-030852d83ca7",
  "TypeID":1,
  "TopicID":2,
  "BrandID":1,
  "BranchID":3,
  "Mobile":"0790000000",
  "Title":"عنوان الشكوى أو الاقتراح",
  "Details":"تفاصيل الطلب"
}
```

الاسم والبريد يؤخذان من سجل العميل. لا يختار العميل جهة الإرسال؛ الطلب يصل إلى مدراء النظام مع التنبيهات الموجودة. الحد 300 حرف للعنوان و10000 للتفاصيل. الهاتف 7–15 رقمًا مع السماح بـ`+` والمسافات والأقواس والشرطة. حد المرفقات: خمسة ملفات، 10 MiB للملف، PDF/PNG/JPG/JPEG/GIF، وإجمالي جسم الطلب 51 MiB، وفق بنية رفع المرفقات الحالية للـAPI. هذا لا يغيّر مرفقات النظام القائمة. تواريخ الشكاوى/الاقتراحات في قاعدة البيانات UTC؛ تعامل مع قيمها بهذا التوقيت. لا تُعرض الملاحظات الداخلية أو مرفقات تداول الموظفين للعميل.

الناتج `RequestID,Replayed`. يُسجّل نوع العملية صراحةً «تقديم شكوى» أو «تقديم اقتراح» في نشاط العميل.

## إعادة المحاولة والأخطاء

أنشئ UUID جديدًا في `OperationID` لكل تقديم، واحتفظ به مع نفس البيانات والملفات حتى تأكيد النجاح. إعادة نفس العملية تعيد النتيجة دون إنشاء طلب أو مرفقات إضافية. تغيير البيانات مع نفس UUID يعيد `409 OPERATION_REUSED`؛ لا تعِد استخدام UUID بين نموذج الويب والتطبيق.

- `400 INVALID_REQUEST / BUSINESS_RULE`: بيانات غير صحيحة أو تغيرت القوائم.
- `401 SESSION_INVALID / INVALID_CREDENTIALS`: أعد تسجيل الدخول عند انتهاء الجلسة.
- `403 HTTPS_REQUIRED`: اتصال غير مشفر.
- `404 NOT_FOUND`: طلب أو ملف غير متاح لهذا العميل.
- `409 RETRY_OPERATION`: أعد نفس العملية بعد انتظار قصير.
- `413`: عدد/حجم المرفقات يتجاوز الحد.
- `429 RATE_LIMIT`: التزم بـRetry-After.
- `500 SERVER_ERROR`: قد تكون نتيجة الإرسال غير محسومة؛ أعد نفس OperationID والبيانات.

## النشر والتحقق

طبّق سكربتات CustomerPortal بالترتيب `001`, `002`, `003`, `004`, `006`, `007` داخل معاملة واحدة (`Apply.ps1`). انشر تجميعة API واضبط `MobileApi.FeedbackStoragePath` إلى مخزن المرفقات المشترك. أُلغيت جميع خدمات `guide/*` وتعيد 404. تتطلب النسخة الحالية ترحيلات CRM 009/010 وCustomerPortal 007 لسجل الدخول والخروج والتغييرات. تدعم لوحة الويب تعديل بيانات العميل وجهاته؛ لا توجد مسارات API جديدة لهذه التعديلات. يُنفذ حذف جداول الدليل القديمة عبر `database/migrations/WorkGuide_Retirement/Apply.ps1` بعد النسخ الاحتياطي المتحقق منه.

اختبارات التكامل تستخدم قاعدة مستقلة وHttpServer بمسارات Web API الفعلية:

```powershell
./Test-CustomerPortal.ps1 -ApiBuildDirectory C:/Projects/ERPProsto/tmp/customer-api-build
```

ملف `CustomerPortal.postman_collection.json` مرفق للتجربة. اضبط baseUrl وusername وpassword؛ يحفظ اختبار تسجيل الدخول الرمز في متغير المجموعة. لا تحفظ كلمات المرور أو الرموز في نسخة مشتركة من المجموعة.
