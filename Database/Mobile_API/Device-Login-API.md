# تسجيل دخول الموظف وحفظ بيانات الجهاز

## BIOID login — implemented 12 October 2026

Password login at POST /api/Users/Login now returns Data.User.BIOID: a separate random 256-bit, 43-character base64url secret bound to that employee and approved device. It is not a fingerprint template or evidence of biometric verification. The phone protects it with biometric-gated secure storage. Only its SHA-256 hash is stored server-side; do not log or share the value. Every successful password login replaces that device's previous BIOID. Other devices have independent values.

### POST /api/Users/LoginViaBIO

Authorization: **Basic Auth using the current fixed API integration username/password**, not employee credentials. All other mobile login/device/Bearer contracts remain unchanged. This POST body accepts BIOID only; unknown fields are rejected.

```http
POST /api/Users/LoginViaBIO
Authorization: Basic <Base64(INTEGRATION_USERNAME:INTEGRATION_PASSWORD)>
Content-Type: application/json
Accept: application/json
```

```json
{"BIOID":"<BIOID-from-Data.User.BIOID>"}
```

Success is the same Data.User, AccessToken, TokenType, expiry and Session structure as Login, with a fresh access token and the same BIOID. Employee/lookup data is current; device/app metadata comes only from the original password-login snapshot (because this request has no device fields). Unsubmitted optional metadata stays omitted. BIO login requires active/nondeleted employee, allowed type, unchanged password and current device approval. It cannot enroll or approve a new device.

The BIO secret expires after the configured MobileApi.MaximumMinutes interval (default 30 days) measured from password login. BIO requests do not extend its expiry. Issued access tokens keep their usual independent expiry rules. An expired access token does not prevent BIO login. Logout revokes the presented access token only; revoke/reset the device or change the password to prevent BIO login. Device revocation/reset/replacement history invalidates old BIO enrollment even after reapproval; a fresh password login is required.

| HTTP | Error.Code | Meaning / action |
|---|---|---|
| 400 | INVALID_BIOID_FORMAT | Send a canonical BIOID only; reject extra fields |
| 401 | BASIC_AUTH_REQUIRED / BASIC_AUTH_INVALID | Supply correct current integration Basic credentials |
| 401 | BIOID_INVALID | Unknown/replaced BIOID; sign in with employee password |
| 401 | BIOID_EXPIRED | BIO enrollment expired; sign in with password |
| 401 | BIOID_REVOKED | Old enrollment revoked; sign in with password after approval |
| 401 | PASSWORD_CHANGED | Use the employee's current password to enroll again |
| 403 | ACCOUNT_INACTIVE / ACCOUNT_DELETED | Account disabled/deleted; contact administrator |
| 403 | ACCOUNT_TYPE_NOT_ALLOWED | Account cannot use employee mobile login |
| 403 | DEVICE_NOT_APPROVED | Device approval missing/revoked; administrator action required |
| 403 | HTTPS_REQUIRED | Use the environment's required transport |
| 500 | SERVER_ERROR | Check matching deployed API/database versions |

Errors use Success:false and Error:{Code,Message}, with a readable Arabic explanation. No failed request creates a session. Responses are no-store. Apply Database/Mobile_API/008_BIOLogin.sql after 006 before publishing the updated API; Apply-BIOLogin.ps1 is local-only. Apply-DeviceAccess.ps1 now applies 006 and 008 together. Replaying 006 alone would replace the BIO-aware login procedure. Keep each source password-login session row while its BIO enrollment references it; migration preserves existing sessions/approvals and creates no BIO secrets for historical accounts. A matching API/database deployment is required; hosted behavior is unverified.

أرسل `Device.MACID` عند توفره. لا تُعاد `DeviceManufacturer` أو `MACID` أو `AppBuild` في `Session` إذا لم يرسل التطبيق قيمة صالحة لها؛ لا يستنتج الخادم بيانات الجهاز. MAC اختياري، والقيمة الصحيحة تُعاد بالصيغة الموحّدة.

تم تحديث `POST /api/Users/Login` ليحفظ بيانات الجهاز وإصدار التطبيق وهوية الموظف مع كل جلسة ناجحة. عنوان API واستخدام Bearer في الطلبات اللاحقة كما هما. الطلبات الجديدة لتسجيل الدخول تتطلب `AppVersion` و`Device` بالإضافة إلى اسم المستخدم وكلمة المرور.

سياسة الأجهزة الحالية موثقة في [إدارة اعتماد الأجهزة](Device-Access-Management.md): الجهاز الأول تلقائيًا، وأي جهاز إضافي يحتاج موافقة مدير النظام. تسجيل الدخول من جهاز غير معتمد يعيد 403 DEVICE_APPROVAL_REQUIRED دون توكن.

## طلب تسجيل الدخول

```http
POST /api/Users/Login
Content-Type: application/json
Accept: application/json
```

```json
{
  "Username": "employee-username",
  "Password": "employee-password",
  "AppVersion": "1.0.0",
  "AppBuild": "100",
  "Device": {
    "DeviceID": "fd292994-2a44-4e40-b84e-037f7d1155c0",
    "Platform": "Android",
    "Manufacturer": "Samsung",
    "Model": "SM-A556E",
    "OSVersion": "14",
    "MACID": "AA:BB:CC:DD:EE:01"
  }
}
```

القيم أمثلة فقط. يرسل التطبيق بيانات الجهاز الفعلية وإصداره الحالي. لا يرسل `UserID` أو `EmployeeID` أو الرقم الوظيفي لتحديد هوية صاحب الجلسة؛ يستخرج API هذه البيانات من الحساب بعد التحقق من كلمة المرور.

| الحقل | إلزامي | الحد / المعنى |
|---|---|---|
| `Username` | نعم | 250 حرفًا |
| `Password` | نعم | 1024 حرفًا؛ لا تحفظ ضمن معلومات الجهاز |
| `AppVersion` | نعم | 50 حرفًا؛ رقم الإصدار المعروض للتطبيق |
| `AppBuild` | لا | 50 حرفًا؛ رقم بناء التطبيق |
| `Device.DeviceID` | نعم | 128 حرفًا؛ معرّف تثبيت التطبيق على الجهاز |
| `Device.Platform` | نعم | `Android` أو `iOS`؛ تُوحّد حالة الأحرف عند الحفظ |
| `Device.Manufacturer` | لا | 100 حرف؛ الشركة المصنعة |
| `Device.Model` | نعم | 150 حرفًا؛ طراز الجهاز |
| `Device.OSVersion` | نعم | 50 حرفًا؛ إصدار نظام التشغيل |
| `Device.MACID` | لا | عنوان MAC إن كان متاحًا فعلًا؛ وإلا `null` أو حذف الحقل |

ينشئ التطبيق `DeviceID` مرة واحدة عند أول تشغيل ويحفظه محليًا ليعيد إرساله مع عمليات الدخول اللاحقة من التثبيت نفسه. لا يولّد معرّفًا جديدًا لكل تسجيل دخول. هذا معرّف للتثبيت؛ لا يعني ضمان بقاء المعرّف بعد إزالة التطبيق أو إعادة ضبط الجهاز. يمكن استخدام معرّف المنصة المناسب عند توفره وفق سياسة المنصة.

## MACID

لا يُشترط MAC الحقيقي لنجاح تسجيل الدخول؛ الوصول إليه مقيّد للتطبيقات العادية على Android، وApple وثّقت إرجاع قيمة ثابتة بدل MAC في واجهات النظام. المصادر: [Android: معرّفات المستخدم والجهاز](https://developer.android.com/identity/user-data-ids)، [Apple: Networking في ملاحظات iOS 7](https://developer.apple.com/library/archive/releasenotes/General/RN-iOSSDK-7.0/)، [Apple: identifierForVendor](https://developer.apple.com/documentation/uikit/uidevice/identifierforvendor).

إذا أرسل التطبيق عنوانًا متاحًا فعلًا، تُقبل صيغة `AA:BB:CC:DD:EE:02` أو `AA-BB-CC-DD-EE-02` أو `AABBCCDDEE02`، ويُحفظ بصيغة الأحرف الكبيرة والفواصل النقطية. القيم الوهمية الشائعة `02:00:00:00:00:00` و`00:00:00:00:00:00` و`FF:FF:FF:FF:FF:FF` تتحول إلى `NULL`، ولا تعتبر أجهزة حقيقية مشتركة. عنوان غير صالح يعيد `400 INVALID_REQUEST`.

## الاستجابة

تبقى بيانات الحساب `Data.User` والتوكن `Data.AccessToken` وحقول انتهاء الجلسة الحالية. أضيف `Data.Session` لملخص الجلسة التي تم حفظها:

```json
{
  "Success": true,
  "Data": {
    "User": {
      "ID": 151,
      "Employee_Number": 81004,
      "FullName_Ar": null,
      "Fullname_En": null,
      "User_Image": null,
      "PhoneNumber": null,
      "MobileNumber": null,
      "Email": null,
      "UserName": null,
      "userType": {
        "ID": 4,
        "Title_Ar": "موظف",
        "Title_En": "Employee"
      },
      "brand": {
        "ID": 29,
        "Title_Ar": "بروستو",
        "Title_En": "Prosto"
      },
      "branch": {
        "ID": 12,
        "Title_Ar": "فرع تجريبي",
        "Title_En": "Demo Branch"
      },
      "department": null,
      "jobTitle": null,
      "shift": null,
      "gender": null,
      "nationality": null,
      "BIOID": "<opaque-bio-secret>"
    },
    "AccessToken": "<opaque-token>",
    "TokenType": "Bearer",
    "ExpiresAt": "2026-09-24T18:00:00Z",
    "AbsoluteExpiresAt": "2026-10-24T10:00:00Z",
    "IdleTimeoutMinutes": 480,
    "Session": {
      "UserID": 151,
      "EmployeeNumber": 81004,
      "AppVersion": "1.0.0",
      "AppBuild": "100",
      "DeviceID": "fd292994-2a44-4e40-b84e-037f7d1155c0",
      "DevicePlatform": "Android",
      "DeviceManufacturer": "Samsung",
      "DeviceModel": "SM-A556E",
      "OSVersion": "14",
      "CreatedUtc": "2026-09-24T10:00:00Z",
      "ExpiresAt": "2026-09-24T18:00:00Z",
      "AbsoluteExpiresAt": "2026-10-24T10:00:00Z"
    }
  }
}
```

المثال مختصر في `User`؛ بقية حقول الموظف الموجودة سابقًا ما زالت تُعاد. بيانات الجهاز في الاستجابة مطابقة لنسخة تسجيل الدخول بعد التحقق والتنسيق. لا تعيد الاستجابة بصمة التوكن أو بصمة كلمة المرور.

يرسل التطبيق التوكن لاحقًا بالطريقة الحالية:

```http
Authorization: Bearer <AccessToken>
```

لا حاجة إلى إعادة إرسال بيانات الجهاز أو MAC مع كل استدعاء. الربط بالجهاز محفوظ داخل سجل الجلسة؛ بيانات الجهاز المرسلة ليست عامل مصادقة مستقلًا أو إثباتًا تشفيريًا لملكية الجهاز. التحقق من الوصول يعتمد على التوكن والحساب وصلاحياته كما سبق.

## ما يُحفظ في قاعدة البيانات

أضيفت الحقول إلى جدول `MobileApi_Sessions` نفسه:

- `UserID`: معرّف الموظف الداخلي الموجود أصلًا، مرتبط بالحساب المصادق عليه.
- `EmployeeNumber`: نسخة من الرقم الوظيفي وقت تسجيل الدخول. إذا لم يكن معرفًا في الحساب يبقى `NULL`، ولا يُخمن من معرّف الموظف.
- `DeviceID` و`DevicePlatform` و`DeviceManufacturer` و`DeviceModel` و`OSVersion` و`MACID`.
- `AppVersion` و`AppBuild`.
- `TokenHash` ووقت الإنشاء وآخر استخدام والانتهاء والإلغاء الموجودة أصلًا.

يُحفظ التوكن كبصمة SHA-256 فقط، وليس كنص قابل للاستخدام. تحفظ بيانات الجلسة في معاملة واحدة بعد نجاح التحقق؛ المدخلات الناقصة أو كلمة المرور الخاطئة لا تنشئ جلسة.

لكل تسجيل دخول توكن مستقل وسجل مستقل، حتى عند استخدام الجهاز نفسه أو تحديث التطبيق. لا تُستبدل بيانات جلسة سابقة ببيانات الدخول الجديد. تغيير رقم الموظف لاحقًا لا يغير النسخة المحفوظة في الجلسات السابقة. تسجيل الخروج يلغي التوكن المستخدم فقط؛ تعطيل الحساب أو تغيير كلمة مروره يمنع استخدام جلساته وفق القواعد الحالية.

## الترقية والتوافق

1. بعد `001_Sessions.sql` و`002_Procedures.sql` طبّق `005_DeviceSessions.sql` عبر `Apply-DeviceSessions.ps1`.
2. ابنِ وانشر مشروع API المحدث، وحدث نموذج تسجيل الدخول في تطبيق الهاتف ليرسل الحقول المطلوبة أعلاه.
3. طبّق `006_DeviceAccess.sql` عبر `Apply-DeviceAccess.ps1` واعتمد المرجع الجديد لإدارة الأجهزة. لا تُعد تطبيق002 أو005 منفردين بعد006.

بعد006 يُعتمد أقدم جهاز معروف لكل موظف؛ تُلغى توكنات أجهزته الأخرى والجلسات التي لا تحمل معلومات جهاز. تُحفظ السجلات القديمة دون اختلاق بيانات مفقودة. لا تحتاج بقية استدعاءات الموظفين إلى تغيير، وواجهات تقديم الزبائن المستقلة تبقى دون تسجيل دخول.

ملف Postman العام `Prosto-Mobile.postman_collection.json` وملف شكاوى الموظفين `Prosto-Feedback.postman_collection.json` يحتويان مثال تسجيل الدخول المحدّث. وثيقة OpenAPI لتسجيل الدخول: `Mobile-Login.openapi.json`.

