# صفحة المراسلات

المسار: `/Modules/Correspondence/ManageCorrespondence.aspx`، والإنشاء في `AddCorrespondence.aspx`. أزيلت صفحة
`Inbox.aspx`؛ توجد صفحة إدارة واحدة فقط.

## Mobile API (008)

`008_MobileApi.sql` / `ApplyMobileApi.ps1` add authenticated application support after 007. Shared portal mutation
procedures remain authoritative. The adapter adds identity checks, paging and atomic operation deduplication. See
`MOBILE-API.md` and `Correspondence.postman_collection.json` for the developer contract. Configure the API's
`MobileApi.CorrespondenceStoragePath` to the portal's shared FileManager directory; direct attachment URLs are
unchanged. Catalog administration remains in the portal. `Test-MobileApi.ps1` runs real in-memory Web API requests with
isolated SQL/users/files and cleans its fixtures.

## Configurable priorities and closure reasons (007)

Apply `ApplyCatalogs.ps1` after 006 and deploy all correspondence pages (including `Catalogs.aspx`) with the rebuilt
Portal assembly. This section supersedes the fixed priorities in 006. The migration is atomic and repeatable; existing
defaults seed only on first creation. Do not reapply older overrides afterward.

System administrators manage shared options across brands from the correspondence navigation: add/edit, display rank,
priority emphasis, activation and deletion of unused options. Used options can be deactivated but cannot be deleted. SQL
validates the active administrator, optimistic row version and current option state, including stale submission
attempts. Changes are audited. Thread priority labels/rank/emphasis and closure labels/behavior are snapshots; catalog
edits do not rewrite history. Closure reasons select normal closure or task-only transfer behavior; free-text
explanation remains required for transfer. If no active choices remain, selection shows a clear message and
sending/closure is rejected. Disabled priorities remain in search filters.

Run `TestGovernance.ps1 -TestDatabase <fresh isolated name>` then `TestCatalogs.ps1 -TestDatabase <same name>`. Catalog
tests apply 007 and cover authorization, snapshots, duplicate names, stale edits, activation, deletion and transfer,
then run the existing participant regression suite. Never run the older migration chain against an already upgraded
application database.

## Current governance behavior (006)

This section supersedes older behavior described below. Apply `ApplyGovernance.ps1` after 005, then deploy the rebuilt
Portal assembly and both correspondence pages. The migration is transactional and repeatable. Existing mapped mutation
signatures retain optional defaults. Do not reapply older procedure scripts after 006. No mobile routes, shared master
code, attachment storage or direct file URLs change.

- `RequiresCompletion=1` identifies a task; otherwise the thread is ordinary correspondence. New tasks may have a due
  date. Priority is normal (1, including old rows) or urgent (2). Both labels are visible to participants and observers.
- `Correspondence_Parties` captures both parties' names, user types and organization IDs/names at creation, within the
  thread transaction. Existing threads are not backfilled with current organization. Reports identify legacy unknown
  organization separately; filters match either party's stored scope, while summary rows group by the recipient's stored
  brand/branch.
- `scope=all` is an administrator-only oversight view. Opening a supervisory conversation writes an audit event once per
  page visit; automatic refreshes do not duplicate it or mark recipient messages read. Administrators who are
  participants use the personal view to reply and acknowledge messages. The latest 100 administrative events are
  displayed; the database retains the full audit.
- New recipients follow current organization. Existing participants retain access after transfer. The creator can close
  a task for transfer with an actual completion outcome and a mandatory reason, then create linked replacement tasks for
  eligible recipients. Transfer closure does not require waiting for a reply; ordinary closure still does. Related links
  are authorization-filtered.
- Only administrators can archive an open thread whose creator is inactive/deleted. A reason is mandatory. Archive
  time/actor/reason are separate; `CloseDate` and completion remain unknown. Replies and normal closure are blocked.
  Inactive recipients trigger follow-up reporting, not administrative takeover of completion.
- The existing master timer refreshes conversation content every 30 seconds without replacing reply text or queued
  uploads. Read acknowledgement during refresh requires a visible tab, participation and personal mode. Closing in
  another session hides reply controls; mutations always recheck SQL authorization/state. The official-channel notice
  explains oversight and retained records.
- Reports follow selected filters: unanswered open threads, overdue tasks, inactive-party follow-up,
  completed/not-completed tasks and administrative archive. Average first reply runs from creation to the first
  other-party message, excluding unanswered threads; reading is separate. Date filters use Jordan calendar days
  converted to UTC, inclusive start/exclusive next-day end.

### Governance validation

`TestGovernance.ps1` creates a fresh `Prosto_Correspondence_Governance_Test*` database with empty copies of required
source table shapes, applies the procedure chain, and checks snapshots, transfer, oversight/audit, priority, links and
archive with rolled-back fixtures. It does not create test conversations in the application database. Databases remain
for inspection; use a new `-TestDatabase` suffix for another fresh run. Build Portal with classic MSBuild and compile
ASPX with `aspnet_compiler`. Verify the timer with an unsent draft, oversight, creator-only outcome and responsive
layouts in an isolated web session.

الواجهة تستخدم نفس بطاقات وجداول وأزرار بقية Modules، وصفحات ASPX مع code-behind وdesigner ترث PageBase. تعرض
ManageCorrespondence قائمة المراسلات، والبحث والتصفية وعدد الرسائل وحالتها. يفتح زر «فتح المحادثة» التفاصيل والسجل والرد
ضمن الصفحة نفسها، مع زر للعودة للقائمة. صفحة AddCorrespondence خاصة بالإنشاء كما في نمط Add/Manage الموجود.

لا توجد ملفات CSS أو JS مخصصة للمراسلات ولا تنسيقات أو سكربتات بديلة مضمنة في الصفحات. يُستخدم Bootstrap وSelect2
وform-layouts.js المحملة من Site.Master. يعتمد رفع المرفقات على AjaxControlToolkit.AjaxFileUpload نفسه المستخدم في
AddUsers وEditUsers، مع FileAttribute في Session ضمن مفتاح خاص بمسودة المحادثة لتجنب اختلاط ملفات الصفحات الأخرى. تُنقل
الملفات إلى FileManager/Correspondence عند الإرسال فقط، ويمكن مسح الملفات المنتظرة. لا توجد إعدادات Web.config خاصة بهذه
الجزئية.

ترتبط البيانات عبر Prosto_ERP_DataClassesDataContext والإجراءات المسماة المستقلة. يظهر عداد المحادثات غير المقروءة في
القائمة ويتحدث بمؤقت Site.Master المشترك كل 30 ثانية. يُحدّث سجل المحادثة المفتوحة بالمؤقت المشترك، دون إعادة إنشاء
عناصر مسودة الرد. تعرض الأوقات بتوقيت الأردن ويحول الموعد إلى UTC على الخادم. تعتمد القائمة جدول ERPTable وملفي
table-script.js وtable-style.css المشتركين؛ يتحول إلى بطاقات على الهاتف، ويقسم النتائج في المتصفح. البحث باسم الشخص
مستقل عن عنوان المحادثة، ويُطبَّق الحقلان معًا عند تعبئتهما.

## قاعدة البيانات

- `001_Approved_Fields_And_Relationships.sql`: الحقول والعلاقات المتفق عليها سابقًا، عبر `Apply.ps1`.
- `002_Page_Operations.sql`: وظيفة المستلمين `Correspondence_AllowedRecipients` والإجراء `Correspondence_Page`، عبر
  `ApplyPage.ps1`. لا يغير بنية الجداول أو البيانات الموجودة.
- `003_Module_Procedures.sql`: مرحلة ربط الإجراءات المسماة عبر LINQ-to-SQL، عبر `ApplyModule.ps1` بعد 002.
- `004_Independent_Procedures.sql`: المرحلة النهائية، عبر `ApplyIndependent.ps1` بعد 003. ينقل منطق الإنشاء والرد
  والقراءة والإغلاق إلى الإجراءات الأربعة نفسها، ويحذف `Correspondence_Page` بعد التحقق من غياب الاعتمادات عليه. يحسن
  استعلام القائمة والعداد والتحقق من صلاحية القراءة، ويضيف فهارس مساعدة للرسائل. لا يحذف محادثات أو يعدل محتواها.
- الترتيب للتثبيت الجديد: 001 ثم 002 ثم 003 ثم 004 ثم 005 ثم 006 ثم 007. لا تعِد تطبيق 002 أو 003 منفرداً بعد 004 لأنها
  تعيد النسخة السابقة.
- `MeasurePerformance.ps1`: قياس قراءة فقط للقائمة والعداد للمستخدم المحدد، خمس عينات لكل إجراء.
- `TestListPerformance.ps1`: يتحقق من العد والترقيم بعينة 36 محادثة و180 رسالة داخل معاملة يتم التراجع عنها. الخيار
  `-Large` مخصص لبيئة اختبار منفصلة ذات ذاكرة كافية.
- `TestPage.ps1`: اختبارات داخل معاملات يتم التراجع عنها؛ تغطي الصلاحيات والخصوصية والقراءة والعداد والإغلاق والإرسال
  الجماعي.

الحالات معرفة في `src/Portal/Features/Correspondence/Data/CorrespondenceData.vb`: فعالة = 1، متأخرة = 2، منتهية = 3.
التخزين يبدأ بـ1 وينتهي بـ3؛ التأخير يحسب وقت العرض من `DueDate` وغياب `CloseDate`، فلا يحتاج مهمة مجدولة. جميع أوقات
الوظيفة UTC وتُعرض بتوقيت الأردن.

## السلوك المعتمد

- مدير النظام يختار علامة تجارية ثم يستطيع تصفية المستلمين بالفرع والوردية. لا يظهر مديرو النظام ضمن المستلمين لبدء
  محادثة.
- مدير الفرع يراسل موظفي ومديري ورديات فرعه ومديري الفروع الآخرين في العلامة نفسها.
- مدير الوردية يراسل مدير فرعه وموظفي ورديته في الفرع نفسه.
- الموظف يراسل مدير فرعه أو مدير ورديته؛ مستلم واحد فقط، دون تحديد الإنجاز أو موعد.
- للمستخدمين الآخرين الرد على المحادثات الواردة إليهم، ولا يُعرض زر الإنشاء إذا لم يكن دورهم من الأدوار أعلاه.
- المحادثات متاحة لطرفيها، مع عرض إشرافي منفصل لمدير النظام فقط؛ يسجل الاطلاع ولا يغير قراءة المستلم.
- كل مستلم في إرسال جماعي يحصل على Thread مستقل، مع BroadcastID واحد للمجموعة. يمكن تكرار العنوان والشخص نفسه في محادثات
  جديدة.
- الملخص مستقل عن الرسالة الأولى. الرسالة يمكن أن تكون نصًا أو مرفقات فقط.
- قراءة المحادثة تسجل أول قراءة للرسائل الواردة المحملة فقط؛ لا يشمل ذلك رسائل تصل بعد التحميل. إشعارات القراءة مستقلة
  ولا تُعلّم كمشاهدة تلقائيًا.
- الإغلاق لمنشئ المحادثة بعد وصول رد من الطرف الآخر. اختيار النتيجة إلزامي إذا كانت RequiresCompletion مفعلة. بعد
  الإغلاق تُمنع الردود وإعادة الإغلاق، وتبقى القراءة متاحة. الإغلاق بعد DueDate يُعرض صراحة.

## الملفات والتشغيل

المرفقات تحفظ بأسماء GUID داخل `src/Portal/FileManager/Correspondence` دون إضافة صلاحيات ملفات، وفق الطلب. في الواجهة
تظهر «مرفق 1» و«مرفق 2». الحد خمسة ملفات للرسالة و10 MiB لكل ملف. المدعوم PDF، DOC، DOCX، XLS، XLSX، JPG، JPEG، PNG،
GIF. الصور تُعاد كتابتها PNG، وتُفحص تواقيع الملفات وبنية مستندات Office الحديثة. الملفات الفاشلة تُحذف إذا رفضت قاعدة
البيانات الإرسال. يلزم منح حساب تشغيل الموقع إمكانية الكتابة داخل هذا المجلد.

حُذفت ملفات correspondence.css وcorrespondence.js، وأزيلت إضافة location الخاصة بالمراسلات من Web.config الرئيسي. بقيت
إعدادات المشروع الأصلية، ويستخدم AjaxFileUpload التجزئة المدمجة فيه لرفع الملفات. الروابط ثابتة ضمن FileManager كما
طُلب.

هوية المستخدم من SessionManager فقط، مع ViewStateUserKey على صفحات الإدخال. إجراءات قاعدة البيانات تتحقق من المشاركين
والصلاحيات والإنجاز والإغلاق، ولا تعتمد على إخفاء الأزرار في المتصفح.

هذه المرحلة تخص صفحة الويب. يمكن استخدام الإجراءات وقواعد العمل نفسها عند تجهيز API تطبيق الهاتف؛ صفحات Web Forms ليست
عقد API للهاتف.

ملفات Master والصفحة وVB محفوظة بـUTF-8 مع BOM للمحافظة على ظهور العربية. يلزم بناء مشروع Portal وتحديث `bin/CRM.dll` و
`bin/Prosto_ERP_ClassLibrary.dll` بعد تعديل طبقة AppCode أو ربط DBML.

## تشخيص الأداء — 2026-09-20

قبل التحسين استغرق استعلام القائمة 25031 ms مع محادثة واحدة ورسالتين، بينما كانت تكلفة CPU نحو 2 ms فقط و25 قراءة
منطقية. أظهرت SQL Server حالة RESOURCE_SEMAPHORE: طلب الاستعلام منحة ذاكرة 6432 KB بينما المتاح في حوض التنفيذ نحو 5880
KB، مع إشارة انخفاض الذاكرة المادية على الجهاز (حوالي 526 MB متاحة من 5965 MB).

أصبح الاستعلام يرشح ويعد ويقسم أرقام المحادثات وتواريخها أولاً، ويجلب تفاصيل 30 محادثة كحد أقصى. يُرتّب هذا الجزء
المحدود في code-behind، لتجنب فرز النصوص والصور والملخصات الكبيرة في SQL. عداد القائمة يستخدم EXISTS للرسائل غير
المقروءة مباشرة، والتحقق من المشاركة لا يحتاج حساب ملخص المحادثة. أُلغي مؤقت العداد المكرر داخل ManageCorrespondence،
وعُطّل ViewState لسجل الرسائل مع إعادة ربطه عند الحاجة في postback كامل.

العينات النهائية للقائمة على البيانات الحالية: 72، 32، 50، 27، 24 ms؛ الوسيط 32 ms. هذه أزمنة إجراء قاعدة البيانات وليست
زمن تحميل المتصفح الكامل. اختبار 36 محادثة و180 رسالة: الصفحة الأولى 631 ms والثانية 203 ms. أظهر اختبار أكبر تحت ضغط
الذاكرة تأخر أول تشغيل؛ لذلك تبقى موارد الجهاز عاملاً مؤثراً ولا تمثل هذه القياسات ضماناً لأحجام غير محدودة. لم تتغير
إعدادات ذاكرة SQL Server أو العمليات الأخرى على الجهاز.

اجتازت الإجراءات المستقلة اختبارات الصلاحيات، الإرسال الجماعي، المرفقات دون نص، استقلال قراءة الإشعارات، توقيت أول
قراءة، الإغلاق ونتيجته، ومنع الرد بعده. اجتازت الصفحات أيضاً البناء واختبارات الربط وأحداث الرد والإغلاق الفعلية في
ASP.NET. جميع بيانات الاختبار تراجعت ولم تُرسل رسائل اختبار إلى موظفين فعليين.

## تحقق الواجهة المشتركة

اجتاز البناء وترجمة ASPX واختبار الرد والإغلاق باستخدام عناصر الخادم الجديدة. اختُبر AjaxFileUpload بطلبات HTTP فعلية في
موقع اختبار محلي معزول: رفع PDF، استلامه في Session، التحقق منه وحفظه ثم تنظيف ملفات الاختبار، ومسح المرفقات المنتظرة.
لا تُرسل بيانات الاختبار إلى موظفين حقيقيين.

## تحديث العرض والبحث — 2026-09-20

يضيف 005_Search_Fields.sql إجراء Select_Correspondence_Threads_Search عبر ApplySearch.ps1 بعد 004. يجلب جميع المحادثات
المطابقة للمستخدم لتعمل صفحات الجدول المشترك، ويترك الإجراء السابق ذا الترقيم متاحًا. يجري البحث على اسم الطرف الآخر
وعنوان المحادثة فقط، ولا تُجلب القائمة عند عرض محادثة مفردة أو الرد عليها. قياسات الترقيم السابقة تخص الإجراء السابق،
ولا تمثل تكلفة تحميل جميع النتائج في الجدول الجديد.

أعيد ترتيب ترويسة المحادثة مع أيقونات المعلومات وزر العودة، ثم حُذف زر التحديث حسب الطلب الأخير. الإغلاق يستخدم
ModalPopupExtender المشترك مع تنسيق Bootstrap، ويتحقق من نتيجة الإنجاز داخل النافذة قبل الحفظ. لم تُضف ملفات JS أو CSS
أو إعدادات Web.config.

الترويسة مصغرة مع تاريخ الإنشاء بخلفية success والإغلاق بخلفية danger يسار العنوان على الشاشات الكبيرة، وتلتف على
الهاتف. رابط العودة badge bg-label-secondary، والفعالة success وغير المقروءة warning والمنتهية والمتأخرة danger، وتنبيه
القراءة فقط alert-danger.
