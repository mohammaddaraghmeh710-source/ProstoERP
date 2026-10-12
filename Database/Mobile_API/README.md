# Mobile API

أرسل `Device.MACID` عند توفره. لا تُعاد `DeviceManufacturer` أو `MACID` أو `AppBuild` في `Session` إذا لم يرسل التطبيق قيمة صالحة لها؛ لا يستنتج الخادم بيانات الجهاز. MAC اختياري، والقيمة الصحيحة تُعاد بالصيغة الموحّدة.

## بيانات الجهاز عند تسجيل الدخول

`POST /api/Users/Login` يتطلب `AppVersion` و`Device` بالإضافة إلى بيانات الدخول. يُحفظ معرّف الموظف ورقمه الوظيفي من الحساب نفسه، ومعلومات الجهاز وMAC عند توفره، في سجل الجلسة المرتبط بالتوكن. يُعتمد الجهاز الأول تلقائيًا؛ الأجهزة الأخرى تحتاج موافقة مدير النظام. المرجع الكامل لواجهات الطلب والاستعلام وخيارات الإدارة الثلاثة: [إدارة اعتماد الأجهزة](Device-Access-Management.md). بعد005 طبّق006 عبر Apply-DeviceAccess.ps1؛ توكنات الأجهزة غير المعتمدة لا تعود صالحة.

## تقديم الزبائن

أضيفت واجهتان مستقلتان تحت `/api/v1/customer-feedback` للخيارات وتقديم الطلب مع الملفات دون تسجيل دخول. التوجيه إلى جميع مديري النظام، وبيانات التواصل والعلامة والفرع تُحفظ داخل جداول الطلبات الحالية بمصدر زبون. المسارات العامة لا تتيح قراءة الطلب أو مرفقاته.

التسليم: [توثيق الزبائن](Customer-Feedback-API.md)، [Postman الزبائن](Prosto-Customer-Feedback.postman_collection.json)، [OpenAPI الزبائن](Customer-Feedback.openapi.json). تطبيق الترقية: `Apply-CustomerFeedback.ps1` بعد ترقيات الموظفين الحالية. اختبارات `Test-FeedbackApi.ps1` تشمل الموظفين والزبائن معًا.

## الشكاوى والاقتراحات

أضيفت ثماني واجهات تحت `/api/v1/feedback` تستخدم جلسة Bearer الحالية، وتطابق الرقم الوظيفي مع صاحب الجلسة. التقديم والإجراءات يستقبلان البيانات والملفات معًا، وفتح التفاصيل يسجّل المشاهدة ويحدّث قراءة الإشعارات. جميع قواعد العمل والصلاحيات والحفظ والتدقيق داخل الخادم.

تسليم مطور الهاتف: [التوثيق الكامل](Feedback-API.md)، [Postman](Prosto-Feedback.postman_collection.json)، [OpenAPI](Feedback.openapi.json). ترقية قاعدة البيانات: `003_Feedback.sql` أو `Apply-Feedback.ps1` بعد متطلبات الشكاوى الحالية. اختبارات الشكاوى: `Test-FeedbackApi.ps1`.

## التشغيل

`GET /api/Get_InfoPages` يعرض الصفحات المرتبطة بعلامة الحساب الحالية فقط، مع صلاحيات النوع والنشر والجدولة. الصفحة تدعم عدة علامات؛ الحساب بلا علامة أو بعلامة موقوفة لا يحصل على صفحات. لا يقبل العميل اختيار علامة أو تجاوزها بمعامل URL، ولا تتغير بنية الاستجابة. قبل تثبيت إجراءات الهاتف طبّق ترقية Information_Pages الحالية بما فيها `Information_Page_Brands` و`Information_Pages_ForBrand`. ترقية الصفحات تحدّث إجراء الهاتف المتأثر تلقائيًا إذا كان موجودًا، دون المساس بجلسات الدخول.

1. اضبط اتصال `Prosto_ERP_ConnectionConnection` في مشروع `Prosto_ERP_API` على قاعدة النظام المطلوبة.
2. نفّذ `001_Sessions.sql` ثم `002_Procedures.sql` ثم `005_DeviceSessions.sql` ثم `006_DeviceAccess.sql` على تلك القاعدة. تعتمد الصفحات على مخطط `Information_Pages` وصلاحياته الحالي. عند تشغيل الشكاوى والزبائن تطبق ترقياتها أيضًا وفق توثيقها.
3. ابنِ مشروع `Prosto_ERP_API` وانشره على HTTPS. لا تقبل المسارات الجديدة اتصال HTTP، ولا تثق بترويسة `X-Forwarded-Proto` من العميل. عند وجود reverse proxy يجب أن يصل الاتصال إلى تطبيق ASP.NET عبر HTTPS أيضًا.
4. اضبط `MobileApi.AssetBaseUrl` على عنوان HTTPS لخادم الملفات. الإعداد المحلي الافتراضي يستخدم نفس نطاق الملفات الموجود سابقًا.

تم تطبيق الإضافة على قاعدة `Prosto_Live` المحلية. النشر على خادم خارجي عملية منفصلة. لا تحتوي هذه الإضافة على تغييرات لمسارات التدريب القديمة.

## الجلسة

| إعداد Web.config | القيمة الافتراضية | المعنى |
|---|---:|---|
| `MobileApi.IdleMinutes` | 480 | ثماني ساعات من آخر طلب موثّق |
| `MobileApi.MaximumMinutes` | 43200 | ثلاثون يومًا من تسجيل الدخول، حتى مع الاستخدام |
| `MobileApi.AssetBaseUrl` | عنوان ملفات HTTPS | بناء روابط الصور النسبية |

كل طلب يحمل رمزًا صالحًا إلى الأخبار أو الصفحات أو تسجيل الخروج يجدّد مهلة الخمول على الخادم قبل تنفيذ العملية. لا يمكن تجديد رمز انتهى بالفعل. تغيير إعداد مهلة الخمول يسري على التجديدات التالية؛ الحد الأقصى يُحفظ عند إنشاء الجلسة ويسري تغييره على الجلسات الجديدة.

الرمز عشوائي بطول 256 bit، ويُخزّن في قاعدة البيانات كـ SHA-256 فقط. لا يُخزّن الرمز الخام، ولا يحتاج العميل إلى فهم محتواه. تُقرأ حالة الحساب وصلاحياته من القاعدة؛ الحساب المعطّل أو المحذوف لا يستطيع الدخول أو استخدام الجلسة، وتغيير كلمة المرور يجعل الجلسات المرتبطة بكلمة المرور السابقة غير صالحة. تسجيل الخروج يبطل جلسة الجهاز الحالي فقط. يمكن وجود جلسات متعددة للموظف.

يحفظ مطوّر الهاتف الرمز في Keychain/Keystore، ويرسله في `Authorization: Bearer <AccessToken>`. لا يُحفظ اسم المستخدم وكلمة المرور بغرض إعادة إرسالهما مع كل طلب. عند `401` يُحذف الرمز وتظهر شاشة تسجيل الدخول. لا يوجد Refresh Token أو استدعاء تجديد منفصل؛ استخدام الرمز نفسه يجدّد الجلسة تلقائيًا. حذف الرمز من الهاتف وحده لا يبطل نسخته على الخادم؛ استدعِ `Logout` أولًا عندما تتوفر الشبكة.

## المسارات

المسارات التالية نسبية إلى عنوان تطبيق الـ API، مثل `https://api.example.com`. يُرسل `Accept: application/json`، ولتسجيل الدخول أيضًا `Content-Type: application/json`.

### POST /api/Users/Login

لا يتطلب Authorization. جسم الطلب:

```json
{
  "Username": "employee",
  "Password": "employee-password",
  "AppVersion": "1.0.0",
  "Device": {
    "DeviceID": "app-installation-uuid",
    "Platform": "Android",
    "Model": "SM-A556E",
    "OSVersion": "14",
    "MACID": "AA:BB:CC:DD:EE:01"
  }
}
```

النجاح `200`:

```json
{
  "Success": true,
  "Data": {
    "User": {
      "ID": 125,
      "Employee_Number": null,
      "FullName_Ar": "اسم الموظف",
      "Fullname_En": null,
      "User_Image": null,
      "PhoneNumber": null,
      "MobileNumber": null,
      "Email": null,
      "UserName": null,
      "userType": {
        "ID": 4,
        "Title_Ar": null,
        "Title_En": null
      },
      "brand": null,
      "branch": null,
      "department": null,
      "jobTitle": null,
      "shift": null,
      "gender": null,
      "nationality": null
    },
    "AccessToken": "<opaque-token>",
    "TokenType": "Bearer",
    "ExpiresAt": "2026-09-22T08:00:00Z",
    "AbsoluteExpiresAt": "2026-10-22T00:00:00Z",
    "IdleTimeoutMinutes": 480
  }
}
```

`Data.User` يعيد بيانات الموظف العامة فقط: المعرّف والرقم الوظيفي والاسمين والصورة وأرقام الاتصال والبريد واسم الدخول. كائنات Lookup: `userType` و`brand` و`branch` و`department` و`jobTitle` و`shift` و`gender` و`nationality`؛ كل كائن يضم `ID` و`Title_Ar` و`Title_En` أو يكون `null` إذا لم تُعيّن العلاقة. أُزيلت حقول التدقيق والحالة وترتيب العرض والمعرّفات والأسماء المكررة المسطحة. بيانات التوكن والجلسة مستقلة كما كانت.

### GET /api/Get_News

يتطلب Bearer. لا يتطلب جسم طلب. يعيد فقط `IsActive=1` و`IsDeleted=0` أو `NULL`، حسب اصطلاح الحذف في النظام. الترتيب: `Item_Order` تصاعديًا، ثم `Date` و`PID` تنازليًا.

```json
{"Success":true,"Count":0,"Data":[],"Session":{"UserID":125,"ExpiresAt":"2026-09-22T08:01:00Z","AbsoluteExpiresAt":"2026-10-22T00:00:00Z"}}
```

كل خبر يحتوي `PID`, `Title_AR`, `Title_En`, `Brief_Ar`, `Brief_En`, `Details`, `Image`, `Date`, `Item_Order` وحقول الإنشاء والتعديل والحالة. الصورة الفارغة `null`، والصورة النسبية تتحول إلى رابط كامل.

### GET /api/Get_InfoPages

يتطلب Bearer. لا ترسل `UserID` أو `UserTypeID`؛ الهوية والصلاحيات تؤخذ من الجلسة وقاعدة البيانات، ولا تغيّرها query parameters.

النتيجة بنفس غلاف الأخبار. الصفحة تظهر إذا كانت منشورة وغير محذوفة، وفي فترة النشر إن كانت مجدولة (`StartUtc <= now < EndUtc`)، ومسموحًا بها لنوع مستخدم الموظف. تُطبّق صلاحية مدير النظام (النوع 1) كما في البوابة، مع بقاء شروط النشر والجدولة والحذف.

الحقول: `ID`, `Title_Ar/En`, `Summary_Ar/En`, `Details_Ar/En`, `Item_Order`, `IsPublished`, `PublishMode`, `StartUtc`, `EndUtc`, `VersionNumber`, `CreatedUtc`, `ModifiedUtc`, `AllUserTypes`, `AccessRevision`, `UserTypeIDs`.

`UserTypeIDs` مصفوفة IDs المسموح بها فعليًا، وتشمل مدير النظام الفعّال. عندما تكون `AllUserTypes=true` يتم توسيعها إلى أنواع المستخدمين الفعّالة وغير المحذوفة الحالية. تغير النوع أو صلاحيات الصفحة يسري عند الطلب التالي. لا تُسجَّل زيارة لكل صفحة عند جلب القائمة دفعة واحدة.

## POST /api/Logout

يتطلب Bearer، بلا جسم طلب. النجاح `200` مع `{"Success":true,"Data":null}`. يُرفض استخدام الرمز لاحقًا بـ `401`.

## الأخطاء والتواريخ

```json
{"Success":false,"Error":{"Code":"SESSION_INVALID","Message":"Sign in again. The session is missing, expired, or revoked."}}
```

| HTTP | Code | الإجراء |
|---|---|---|
| 400 | INVALID_REQUEST | تصحيح حقول تسجيل الدخول |
| 401 | INVALID_CREDENTIALS | بيانات الدخول غير صحيحة أو الحساب غير فعّال |
| 401 | SESSION_INVALID | إعادة تسجيل الدخول |
| 403 | HTTPS_REQUIRED | استخدام HTTPS |
| 500 | SERVER_ERROR | تعذّر إكمال العملية؛ تفاصيل القاعدة لا تعاد للعميل |

الأوقات ذات اللاحقة `Utc` وأوقات انتهاء الجلسة UTC مع `Z`. حقول التاريخ القديمة للموظف والأخبار محفوظة كما هي في النظام دون افتراض منطقة زمنية جديدة. قد تحتوي تفاصيل المحتوى على HTML؛ اعرضه حسب سياسة التطبيق، ولا تنفّذ JavaScript من المحتوى.

تُرجع الاستجابات `Cache-Control: no-store, private`. لا تسجّل رموز الدخول أو كلمات المرور في سجلات تطبيق الهاتف أو أدوات التحليل. المسارات القديمة لا تتحول تلقائيًا إلى المصادقة الجديدة؛ يستخدم مطوّر الهاتف المسارات الموثّقة هنا فقط.

## التحقق

`Test-MobileApi.ps1` ينشئ قاعدة SQL محلية مؤقتة من **المخطط فقط**، ويطبّق الإضافة، ويختبر الـ HTTP pipeline الحقيقي داخل الذاكرة. يحذف القاعدة المؤقتة في النهاية ولا يستخدم حسابات الموظفين الحقيقية. يتطلب صلاحية إنشاء وحذف قاعدة الاختبار المحلية، وملفات مشروع API المبنية في `tmp/mobile-api-build`.

تشمل الاختبارات: بيانات الدخول الناقصة والخاطئة، رفض HTTP والطلبات بلا رمز، منع الحساب المعطّل والمحذوف، استبعاد كلمة المرور من الاستجابة، تصفية الأخبار والصفحات والجدولة، منع تغيير الهوية عبر query parameters، تجديد مهلة الخمول، الحد الأقصى، انتهاء الجلسة، تغير نوع المستخدم وكلمة المرور، وتسجيل الخروج.

## Local IIS testing
`MobileApi.AllowHttp=true` temporarily allows HTTP for local and network clients, for example `http://<IIS-IP>:3001`. Set it to `false` or remove it before production. It does not bypass login, device approval or Bearer authorization.


BIO login: apply `008_BIOLogin.sql` after 006, then deploy the matching API. `Data.User.BIOID` is secret; `POST /api/Users/LoginViaBIO` accepts BIOID-only JSON with current fixed integration Basic credentials. See Device-Login-API.md and Mobile-Login.openapi.json for expiry/revocation/errors. No mobile app code is present in this workspace.
