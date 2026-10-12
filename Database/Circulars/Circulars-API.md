# APIs التعاميم لتطبيق الهاتف

ملف Postman المرفق يولّد EventID جديدًا لكل تشغيل ويحفظه في `last_event_id`. لإعادة محاولة العملية نفسها فقط، انسخ القيمة إلى متغير المجموعة `event_id`، ثم أفرغه قبل أي عملية جديدة أو تغيير نوع الإجراء.

الخادم يحدد المستهدفين والصلاحية وحالة القراءة والسماح بالتنزيل ويسجّل العمليات تلقائيًا. لا توجد API عامة لإرسال logs أو تعليم التعميم مقروءًا.

جميع الطلبات عبرHTTPS وبالتوكن الحالي:

```http
Authorization: Bearer <AccessToken>
```

الرقم الوظيفي EmployeeNumber يجب أن يطابق صاحب التوكن. إلغاء الجهاز أو الجلسة يمنع جميع هذه الواجهات. واجهات إدارة التعاميم والسجلات غير متاحة لتطبيق الهاتف.

## 1. قائمة التعاميم الفعالة

```http
GET /api/v1/circulars?employeeNumber=901002&page=1&pageSize=20&search=&unreadOnly=false
```

page يبدأ من1، وpageSize من1 إلى100. search حتى250 حرفًا ويبحث في العنوان والملخص. unreadOnly اختياري.

```json
{
  "Success": true,
  "Data": {
    "Counts": {"Total": 3, "Unread": 2, "Active": 3},
    "TotalItems": 3,
    "Page": 1,
    "PageSize": 20,
    "Items": [{
      "ID": 10,
      "Title": "تعميم إجراءات الدوام",
      "Summary": "ملخص التعميم",
      "CircularDate": "2026-09-24",
      "StartUtc": "2026-09-24T06:00:00Z",
      "EndUtc": "2026-10-01T06:00:00Z",
      "IsEnabled": true,
      "AllowDownload": false,
      "Audience": "organization",
      "FileName": "circular.pdf",
      "FileSizeBytes": 125000,
      "Version": 1,
      "ModifiedUtc": "2026-09-24T05:00:00Z",
      "IsRead": false,
      "FirstReadUtc": null,
      "LastReadUtc": null,
      "Status": "active",
      "FileEndpoint": "/api/v1/circulars/10/file"
    }]
  }
}
```

Counts تتبع البحث قبل مرشح غير المقروء، وTotalItems يتبعه بعد المرشح. لا يتلقى التطبيق التعاميم غير المستهدفة أو المنتهية أو المستقبلية أو المعطلة. عرض هذه القائمة لا يسجل قراءة.

## 2. تفاصيل التعميم

```http
GET /api/v1/circulars/10?employeeNumber=901002
```

يعيد Success وData وفيها بيانات عنصر التعميم السابقة مع CreatedUtc. لا يعيد الملف نفسه أو المستهدفين أو السجلات، ولا يسجل قراءة.

## 3. مشاهدة الملف أو تنزيله

```http
POST /api/v1/circulars/10/file
Content-Type: application/json
Authorization: Bearer <AccessToken>
```

```json
{
  "EmployeeNumber": 901002,
  "Action": "view",
  "EventID": "ecb514c0-76b9-4bf3-81df-8e15599267f0",
  "OccurredAt": "2026-09-24T09:15:00+03:00"
}
```

- Action: view للمشاهدة أو download للتنزيل.
- EventID: UUID جديد لكل عملية يقصدها المستخدم. أعد استخدامه عند إعادة محاولة العملية نفسها بسبب انقطاع الشبكة؛ لا تُنشئ UUID جديدًا لكل محاولة.
- OccurredAt: اختياري، وقت العملية من الهاتف بصيغةISO8601 معZ أوالإزاحة. يقبل آخر30 يومًا وحتى5 دقائق مستقبلًا؛ وقت الخادم هو المعتمد في فحص الصلاحية والتسجيل.

استجابة النجاح200 هي **بايتات PDF مباشرة، وليست JSON أوBase64**:

```http
Content-Type: application/pdf
Content-Disposition: inline
Cache-Control: no-store, private
X-Circular-Version: 1
```

عند download تصبح Content-Disposition: attachment. اقرأ اسم الملف من FileName في البيانات أوfilename* في الترويسة.

يُجري الخادم معاملة واحدة للتحقق من الصلاحية وتسجيل السجل وتحديث القراءة. سجّل التطبيق حالة مقروء بعد نجاح جلب الملف، واعرض البيانات في عارض PDF. لا يرسل التطبيق اسم الموظف أوDeviceID أوAppVersion للتسجيل؛ يستخرجها الخادم من الحساب والجلسة.

عند AllowDownload=false أخفِ التنزيل والطباعة وأدوات المشاركة والحفظ في العارض، ولا تحتفظ بنسخة دائمة للعمل دون اتصال. الخادم يرفضAction=download حتى لو أظهر التطبيق الزر بالخطأ. لا يمنع ذلك التصوير أو استخراج البيانات من جهاز يسيطر عليه المستخدم.

لا تستدعِ ملف المشاهدة مسبقًا أثناء تحميل القائمة؛ استدعِه استجابة لاختيار المستخدم مشاهدة أو تنزيل.

## الأخطاء

النجاح فيfile فقطPDF؛ الأخطاءJSON بالصيغة الموحدة:

```json
{"Success":false,"Error":{"Code":"DOWNLOAD_NOT_ALLOWED","Message":"تنزيل هذا التعميم غير مسموح."}}
```

| HTTP | Code | التصرف |
|---|---|---|
|400|INVALID_REQUEST|تصحيح المدخلات أو الوقت أوEventID|
|401|SESSION_INVALID|تسجيل الدخول مجددًا|
|403|HTTPS_REQUIRED|استخدامHTTPS|
|403|ACCESS_DENIED|عدم تطابق الرقم الوظيفي أو فقد الصلاحية|
|403|DOWNLOAD_NOT_ALLOWED|إخفاء التنزيل وإتاحة المشاهدة|
|404|CIRCULAR_UNAVAILABLE|إزالة العنصر القديم أو تحديث القائمة؛ انتهى أو أُلغي الاستهداف أو غير موجود|
|409|EVENT_CONFLICT|معرف العملية مرتبط بعملية أو إصدار مختلف؛ حدث التفاصيل ثم استخدم معرفًا جديدًا لعملية جديدة|
|500|SERVER_ERROR|عرض رسالة إعادة المحاولة|

إعادة طلب ملف منتهٍ أو مُعطل تُرفض حتى عند إعادة EventID ناجح سابقًا. ترتيب القائمة: غير المقروء أولًا ثم تاريخ التعميم الأحدث ثمID.

ملفات الاستيراد: [Circulars.openapi.json](Circulars.openapi.json) و[Prosto-Circulars.postman_collection.json](Prosto-Circulars.postman_collection.json).
