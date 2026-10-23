# CRM — إدارة العملاء

النطاق الحالي بعد تحديث 2026-09-13: العملاء وجهات الاتصال والتعريفات الثلاثة وسجل النشاط فقط.

## القائمة والصفحات

- **إدارة النظام:** طرق الدفع، أنواع العقود.
- **إدارة العملاء:** رابط مباشر إلى Overview.aspx دون قائمة فرعية؛ ومنها بطاقات الأعداد وروابط إدارة الأنواع والعملاء وجهات الاتصال. الأنواع متاحة للمدير فقط؛ مسؤول العميل يرى أعداد العملاء وجهات الاتصال المسموحة له. أزيل رابط سجل النشاطات فقط؛ الصفحة والسجل مستمران.
- لكل من التعريفات والعملاء وجهات الاتصال صفحات مستقلة Manage / Add / Edit داخل مجلد يبدأ بـ CRM_.
- أنواع العملاء: بطاقات إجمالي/فعال/موقوف لجميع الأنواع غير المحذوفة مستقلة عن الفلاتر وتتحدث بعد العمليات. البحث بالاسم العربي/الإنجليزي والحالة ضمن حقول تصفية بلا عناوين ظاهرة؛ بحث JavaScript فوري مستقل بجانب زر الإضافة مقابل عدد العناصر فوق الجدول. التصميم والألوان من app-user-list، بخط جدول موحد وإجراءات Font Awesome متقاربة بتلميحات. الإضافة والتعديل من لوحة جانبية داخل ManageCRMAccountTypes؛ الحذف بعد تأكيد Modal من ui-modals مع التحقق من نسخة السجل والصلاحيات والارتباطات. تنبيهات ui-alerts قابلة للإغلاق وبطاقات الصفوف مستمرة على الهاتف. تبقى صفحات Add/Edit القديمة متاحة للرابط المباشر فقط.
- صفحات الإدارة تعرض فلاتر بحث ثم DataTable مع البحث الداخلي والترتيب وعدد الصفوف والترقيم، وبطاقات عند عرض 768px أو أقل.
- جهات الاتصال تدعم البحث بالعميل والاسم والبريد والمسمى الوظيفي والحالة. الحالة في الجدول نص «فعال / موقوف»، والإجراءات: تعديل، تفعيل أو إيقاف، وحذف مع تأكيد. يبقى مربع الحالة في نموذج الإضافة والتعديل.
- نماذج الإدخال مقسمة إلى مجموعات، بعمودين على الشاشات الواسعة وعمود واحد على الهاتف.

## الصلاحيات والسجل

المدير الفعال UsersMembers.Type=1 يدير جميع العملاء والتعريفات. مسؤول العميل يصل إلى العملاء المسندين إليه وجهات اتصالهم فقط. المدير يحدد المسؤول، ولا يوجد بديل مسؤول. الاسم مطلوب، وربط جهة الاتصال بالعميل مطلوب. العلامة التجارية إلزامية عند حفظ العميل، والفرع اختياري ويجب أن يتبع العلامة المختارة؛ بقية الحقول اختيارية. العملاء السابقون بلا علامة يبقون محفوظين ويجب تحديدها عند التعديل. هذا الارتباط لا يغيّر صلاحيات العلامات في بوابة العميل.

تطبق الصلاحيات داخل Stored Procedures أيضًا. يمنع تكرار العميل بالاسم الموحد ورقم التسجيل إذا أدخل، وتمنع Row_Version
الكتابة فوق تعديل أحدث. الإضافة والتعديل والتفعيل والإيقاف تسجل قبل/بعد التغيير في نفس المعاملة. تسجل مشاهدة الصفحات
والبحث في القوائم. سجل النشاط يدعم المستخدم والعميل والقسم والتاريخ من/إلى، ويحتفظ بالسجل التاريخي السابق.

## قاعدة البيانات والتطبيق

الجداول المتبقية:

- CRM_Account_Types
- CRM_Contract_Types
- CRM_Payment_Methods
- CRM_Accounts
- CRM_Contacts
- CRM_Activity_Logs

```powershell
& .\ERP_Prosto\database\migrations\CRM\Apply-CRM.ps1
```

ينفذ `005_CRM_Retire_Contracts.sql` ثم `001_CRM_Schema.sql` ثم `002_CRM_Procedures.sql` ثم `006_CRM_Delete.sql` ثم `007_CRM_Organization_Overview.sql` داخل معاملة واحدة. **يتضمن حذف جداول العقود والدفعات والفواتير والسداد والمتابعات والمرفقات والإعدادات وطابور البريد وبياناتها وإجراءاتها وعروضها.** أُجري هذا الحذف بناءً على طلب المستخدم؛ لا تعِد هذه الأجزاء عند تطبيق التحديث على قاعدة أخرى.

احتفظنا قبل الحذف بنسخة بيانات مع مخطط XML وتعريفات SQL وملفات المشروع القديمة في
`C:\Projects\ERPProsto\tmp\crm-retirement-20260913`. النسخة للمراجعة والاسترجاع اليدوي وليست سكربت استعادة تلقائيًا.
أزيلت كذلك مهمة Windows المسماة ERPProsto-CRM-Notifications.

للخمسة كيانات القابلة للإدخال إجراءات CRM_Select_<Entity> وCRM_Save_<Entity>، مع CRM_Set_Active وCRM_Delete
وCRM_Select_Logs وCRM_Select_Options وCRM_CheckUser وCRM_Log_Read. الحفظ يستعمل @Actor_ID و@ID و@Data xml و@Version
binary (8)، ويعيد ID وRow_Version. حقل Is_Active ضمن XML بقيمة 0 أو 1. تعمل الصفحات عبر CRMData بمعاملات معرفة النوع،
دون اعتماد على إعادة توليد Prosto_ERP_ClassLibrary.

## البيانات الافتراضية المتبقية

6 عملاء و12 جهة اتصال و4 أنواع عملاء و5 أنواع عقود و5 طرق دفع من المجموعة التجريبية السابقة. الأسماء موسومة [تجريبي]؛
جرى الحفاظ عليها وسجل النشاط. حذفت بيانات العقود والعمليات المرتبطة بها مع الجداول الملغاة.

## التحقق

- نجاح بناء Portal وASP.NET precompile لصفحات CRM المتبقية وSite.Master؛ تحذير ADUsers القديم فقط.
- Test-CRM-Simple.ps1: الإضافة والتعديل وحالة checkbox والسجل ونطاق المسؤول ومنع غير المدير من تعديل التعريفات والتحقق من غياب الأجزاء الملغاة. تتراجع معاملات الاختبار عن جميع بياناتها.
- تشغيل صفحات ASP.NET في تطبيق اختبار محلي مع جلسة اختبار، ثم فحص HTML الناتج بملفات CSS/JS الفعلية في المتصفح، بما يشمل البحث وبطاقات الهاتف ونماذج الإضافة. لا يشمل ذلك جلسة تسجيل دخول تفاعلية أو تعديل بيانات فعلية عبر المتصفح.
## إجراءات الصفوف — تحديث 2026-09-13

طابقت الصفحات الخمس Manage_HR_Vacations_Types في نص الحالة وألوان أزرار تعديل/إيقاف/تفعيل/حذف. الحذف منطقي عبر
Is_Deleted ويوقف السجل ويحفظ المستخدم والتاريخ وسجل قبل/بعد. يمنع حذف عميل لديه جهات اتصال غير محذوفة أو نوع عميل مرتبط
بعملاء غير محذوفين. يلزم نقل الارتباط أو حذف السجلات التابعة أولًا. يحتفظ السجل المحذوف باسمه ورقم التسجيل لمنع إنشاء
عميل مكرر.

Test-CRM-Actions.ps1 يختبر الوحدات الخمس والتفعيل والإيقاف والحذف واختفاء السجل من القوائم واستمرار السجل التاريخي، ويرفض النسخة القديمة والمستخدم غير المخول وحذف السجلات المرتبطة. تتراجع جميع بيانات الاختبار. نجح البناء وتجميع وتشغيل صفحات الإدارة الخمس داخل ASP.NET.

## Organization and overview deployment

For an existing CRM installation, run `Apply-CRM.ps1 -OrganizationOverviewOnly` to apply only the additive 007 migration. It adds brand/branch foreign keys, updates the account view/save procedure, and installs the administrator-only dashboard counts. No existing customer receives an inferred brand. The full installer retains its existing retirement behavior described above. Reapply 007 after older base scripts that redefine the account view/save procedure.

`Test-CRM-Organization.ps1` verifies required brand, optional branch, brand/branch consistency, inactive/malformed references, owner access, optimistic concurrency, audit, and dashboard counts. It rolls back all test writes. Existing CRM tests now supply a valid brand for new customer fixtures.

`Test-CRM-TypePage.ps1` (Windows PowerShell / built Portal) creates an isolated local SQL database, runs actual ASP.NET GET/POST requests for server search, filter-independent summary counts and mutation refresh, validation, create/edit, duplicate/stale rejection, status, delete modal confirmation/concurrency/replay and admin authorization, then drops that database. Rendered synthetic fixtures are saved under `tmp/crm-type-page-results` for desktop/mobile and JavaScript search QA. No application data is modified.

`Test-CRM-TypePage.ps1 -IncludeManagement` also runs `Test-CRM-ManagementFlows.ps1` against the actual customer/contact Manage pages and existing credential procedures: inline forms, brand/branch filters and locally filtered branch options, optional integrated login, atomic rollback on duplicate/stale login, contact counts/moves, confirmation/dependency/version checks and owner permissions. It sends real multipart uploads to verify image decoding, extension/size rejection, atomic logo rollback, preservation on ordinary edits, protected PNG responses and default/unauthorized handling. The three lists share `assets/css/crm-list.css` and `assets/js/crm-list.js`; customer/contact handlers share `CRMInlineManagePage`. Customer login fields appear only for administrators inside the customer editor; blank password preserves it and unchanged login data preserves sessions.

## Optional customer logos and branch filters

For existing combined CRM/CustomerPortal deployments, use the current Apply-SelfService runner described below. Historical 008/010 consolidate the former logo table before the verified FileManager export; final 012/customer 009 store Logo_Url only. Deploy the matching Portal build and ASPX files together. Apply-CRM -AccountLogosOnly includes the export/finalization after CRM 011 is present. Do not apply 008/010 alone, or use the full installer merely to update logos because its older retirement behavior remains.

Customer filters replace phone/email with brand/branch; contact data fields remain. Both filter/editor branch selects are filtered in JavaScript from registered `data-brand-id` options, clearing a branch when brand changes without PostBack. SQL still validates active brand/branch ownership. Organization comes first in the editor, optional logo precedes the name, and active/login-enabled controls are stacked last (login remains administrator-only).

`CRMAccountLogo` accepts real PNG/JPEG/GIF images up to 2 MiB and 4096px per side, strips metadata by reencoding to a maximum-512px PNG, and saves a GUID file under FileManager/CustomerLogos. The profile/login SQL transaction stores only Logo_Url; failure removes the newly staged file. Audits contain logo metadata only. The list loads scoped logo keys in one query, while `Modules/CRM_Accounts/Logo.aspx` serves bytes only to authorized employees with no-store/nosniff headers; missing logos use `assets/img/illustrations/customer-default.svg`. The application pool needs read/write access to FileManager/CustomerLogos; include its web.config to prevent direct serving.

## Bilingual contacts and customer self-service

`009_CRM_Contact_Names.sql` adds nullable legacy `Name_EN`; create/edit require both Arabic and English names through SQL and all portal editors. Do not infer English translations for existing rows. `Apply-CRM.ps1 -ContactsBilingualOnly` applies 009/011, requiring both names and Arabic/English job titles when saving. Job_Title retains its original Arabic value; Job_Title_EN is nullable for unedited legacy rows.

For an existing customer portal, use `../CustomerPortal/Apply-SelfService.ps1` with its verified full backup and atomic migration. Customers edit their own permitted profile fields/logo and contacts in Dashboard offcanvas editors. They cannot change assignment, ownership, account/login state, contact account IDs, internal notes or audit records. New customer contacts have nullable employee AddedUser; Customer_Portal_Activity retains their real CRM actor, changes and session events. CRM_v_Activity/CRM_Select_Logs combine staff/customer records with source labels, and restrict customer authentication events to administrators. Reapply current CustomerPortal 007 after older deployments that replace shared audit/credential procedures. Keep the CRM table free of image blobs in list/export/audit result projections.

## Current file-logo and activity deployment

Run current `../CustomerPortal/Apply-SelfService.ps1` for an existing combined installation. It verifies a full COPY_ONLY/CHECKSUM backup, applies CRM 009/008/010/011 and customer 006/007/008, exports and SHA-256 verifies existing logos, then applies CRM 012/customer 009 in one transaction. New file paths replace Logo_Data; the binary column and old logo table are absent afterward. Failures roll back SQL and remove newly exported files. Do not apply historical 008/010 alone afterward. `Apply-FileLogos.ps1` is the targeted URL-storage runner after CRM 011; it also verifies a full backup. The SQL-only 012 migration deliberately refuses unexported images. Back up/restore `Portal/FileManager/CustomerLogos` together with SQL; grant the application pool read/write access, retain folder web.config, and keep replaced files for recovery.

Overview links to the unified activity browser. Customer, executor, source, section and inclusive date filters retain owner/admin restrictions; employee/customer executor IDs cannot collide. Before/after fields are labeled, HTML-encoded and differences highlighted. Authentication events remain administrator-only. `Test-CRM-TypePage.ps1 -IncludeManagement` includes `Test-CRM-ActivityFlows.ps1` plus actual multipart file/rollback and bilingual field checks.

## CRM work-guide library and catalog navigation

For the current CRM installation, build Portal and run `Apply-CRM.ps1 -WorkGuideOnly` using Windows PowerShell. The additive 013–016 migrations verify a full COPY_ONLY/CHECKSUM backup first and create the library, grants, formatted details and protected read/write procedures plus Overview counts. They are idempotent and do not run financial/legacy-guide retirement or logo conversion. The full installer also finishes with 016. This is a new library; do not restore retired WorkGuide tables/routes.

Deploy the matching Portal DLL, CRM Manage pages/Overview/Site.Master, CRM catalog base, guide assets and both `Modules/CRM_WorkGuide/web.config` and `FileManager/CRMWorkGuide/web.config`. The module allows 12 MiB requests for multipart overhead while file validation remains 10 MiB. Grant the app pool read/write access to the document folder and back it up/restore it with SQL. Direct FileManager requests are denied; administrator-only File.aspx returns attachments. Replaced/soft-deleted files are retained for recovery.

Customer types, contract types and payment methods share the same catalog inline editor, statistics/filter/table/action styling and modal confirmation. Contract types/payment methods appear only in CRM Overview, not System Management. Library administration is shared and administrator-only; customer access is controlled by the exact category grants described below. Names/summaries/categories are bilingual, category links are many-to-many, and tree cycles/linked deletes/stale writes are rejected. All mutations preserve before/after audit including classification/file metadata; document bytes are absent from SQL/audit.

`Test-CRM-TypePage.ps1 -IncludeManagement` now runs the work-guide SQL and real ASP.NET category/document/catalog tests in an isolated database; optional `-DatabaseOnly` skips the UI lifecycle. Tests include tree cycles/reparenting, bilingual required fields, multi-category/descendant search, PDF/Word upload/type/size validation, failed-save file cleanup, download authorization, row versions, status, modal deletion and replay denial.


## Customer work-guide permissions and local viewing

Apply `Apply-CRM.ps1 -WorkGuideAccessOnly` to an existing 013 deployment with current CustomerPortal 007+ identity/audit services. The runner verifies a full backup and atomically applies 014/015/016; the full/WorkGuideOnly paths include it as well. No existing customer receives grants automatically. Deploy matching Portal DLL, Customer.Master, Permissions.aspx, CustomerPortal/WorkGuide.aspx and WorkGuideFile.aspx, customer-workguide.js, customer-guide-details.js, crm-guide-permissions.js and crm-workguide.css.

Administrators reach permissions from the library toolbar or a customer's shield icon. Each category independently allows none/view/download/both. Parent grants exclude descendants. A guide linked to multiple classifications is always opened/downloaded in the selected classification; no rights are combined. Grant saves use a per-customer row version and audited before/after XML. Customer lists expose granted categories and active guides; their tree additionally includes disabled ancestor labels for context only. Each file request rechecks the current CRM/login/security stamp, category link and required right; successful access is audited. Detail responses independently require the exact category view grant.

PDF renders in the protected local PDF.js canvas viewer without print/download controls for view-only access. Word view downloads the original DOC/DOCX and requires the exact category download grant; it does not convert to PDF. Original documents are backed up with SQL. Rendering is not DRM.

Current guide viewing requires no Word converter, Office server or external viewer service. Existing conversion tooling/cache is not invoked by the customer file endpoint.

`Test-CRM-TypePage.ps1 -IncludeManagement` includes database and real ASP.NET customer permission/viewer/file tests. All test writes use a disposable database. SQL-only checks use `-DatabaseOnly`; focused permission/portal checks use `-IncludeManagement -AccessOnly`. No customer guide mobile APIs are added.


## Work-guide brand ownership

Existing installations through 014 apply `Apply-CRM.ps1 -WorkGuideBrandsOnly` (015) with the same verified-backup/atomic transaction policy. Full/WorkGuideOnly/WorkGuideAccessOnly runners also finish with 016. Deploy the matching ManageCRMWorkGuide ASPX/DLL, Permissions.aspx/DLL and current work-guide scripts/styles. The initial brand migration requires an empty unassigned library; if existing category/guide rows lack brand ownership it aborts and requires a reviewed explicit mapping rather than assigning a default brand. No file content is rewritten.

Categories, guides and classification links carry required Brand_ID values. Composite foreign keys enforce same-brand parent/child and guide/category relationships, including direct database writes. Category/guide duplicate-name rules are scoped per brand; category brand stays fixed. Guide brand edits atomically replace all classifications within the new brand and preserve the original file pointer when no upload is supplied. Brand_ID is included in audit snapshots.

The administrator selects brand first in the guide editor; its checkbox tree updates locally and clears previous-brand selections without PostBack, preserving the selected file. Category management selects its brand before showing that tree/parent choices, and resets the editor when switching brands. The management table adds brand filtering/labels. Permission management groups all active assigned brands; every submitted category must match an assigned active membership. Customer category/guide/file procedures independently enforce the current account brand, and immediately before returning file/detail content. A customer’s previous-brand grants become inaccessible immediately after an account-brand change; saving a fresh grant set replaces the old set. Parent grants remain exact, and rights from different categories remain independent.

`Tests-WorkGuideBrands.sql` verifies required ownership, duplicate names across brands, database/procedure integrity, forged grants, portal access after account-brand changes, atomic guide moves/file preservation and audit. `Test-CRM-WorkGuideBrandFlows.ps1` covers the real Web Forms brand-first editors, scoped parent choices, rejected foreign classifications, filters/counts, permission editor and protected portal download. Run through the existing disposable `Test-CRM-TypePage.ps1 -IncludeManagement` harness. Add `-DatabaseOnly` for SQL checks, `-GuideOnly` for library CRUD plus portal/brand flows, or `-AccessOnly` for portal/brand flows without the older library CRUD suite.


## Formatted guide details and permission trees

Existing installations through 015 run `Apply-CRM.ps1 -WorkGuideContentOnly` for 016, using the verified full backup and atomic deployment transaction. Deploy the matching Portal DLL, both guide/permission pages, customer guide/detail/file pages and referenced local scripts/styles together. Full and targeted work-guide runners finish with 016. Existing guides retain empty details; no automatic translation or file-content import occurs. Optional Details_AR/Details_EN must be supplied together and are limited to 100,000 characters per language; omitted XML fields preserve existing content. Summaries remain separate.

The editor reuses local CKEditor and InformationPagesData’s server HTML allowlist. Both save and detail-response paths sanitize HTML. Before/after audit includes formatted content; Overview displays its plain text. Customer global search examines names, summaries and authorized detail text, never raw markup or details under a download-only category. Details open on CustomerPortal/WorkGuideDetail.aspx, a dedicated page with Arabic/English tabs, copied all-guide search, yellow highlights and next-match controls. Each direct page request revalidates exact-category view rights, current brand and session/stamp and records the existing details audit. The return link restores list search/category. The prior session/stamp/CSRF-protected JSON details operation remains available for compatibility.

Permission management renders every category as an expanded jsTree node with independent Web Forms view/download checkboxes, local name search and no inheritance/pagination. Search never removes controls from the form. Customer trees expose granted nodes plus disabled ancestor context only; selecting a context ancestor cannot list its guides. All-category listing preserves separate rows/actions for each explicitly authorized category rather than combining rights across categories.

`Test-CRM-WorkGuideContentFlows.ps1` runs in the existing disposable ASP.NET/SQL harness and covers bilingual sanitation/save/edit/audit, five-level trees, independent rights, structural ancestors, all-guide rich-text search, protected details, CSRF and revocation. The access suite covers Word originals/download denial instead of conversion. Browser checks use actual rendered fixture pages for bilingual tabs, search highlighting and responsive interaction verification.


## Supplier accounts and tool migration

Deploy the matching Portal/ClassLibrary binaries, CRM account/editor markup and supplier scripts, then run `Apply-Suppliers.ps1` locally. It takes and verifies a full copy-only backup and applies 017–019 in one CRM-write transaction. It creates or designates the exact `موردين` type with stable `System_Code=SUPPLIER`, migrates legacy supplier identities conservatively, checks every tool link and removes only the retired supplier table/column and six supplier-only procedures after all shared tool readers/writers use CRM accounts. Ambiguous existing names cause a full rollback. Every migrated supplier keeps an audit snapshot of its old row; no login or password is provisioned. Archive the reported backup path with deployment records. General CRM and self-service upgrades preserve the installed supplier contracts.

`CRM_Account_Brands` now supplies canonical membership for suppliers and ordinary customers. `CRM_Supplier_Brands` is maintained only as a compatibility projection; scalar principal fields no longer authorize portal content. Current supplier/type activation is required for new assignments; existing paused links are retained. Removing coverage used by an existing tool, retyping a referenced supplier and deleting it are rejected. Brand coverage does not automatically include all brands or grant portal content permissions. Migration infers coverage only from existing tool organization links. A legacy supplier with no tools remains unassigned until an administrator explicitly selects its assigned brands.

Run `Test-Suppliers.ps1` for synthetic migration/rollback/idempotence, multi-brand eligibility, historical links, role/version/audit and shared-reader checks; `Test-CRM-TypePage.ps1 -IncludeManagement` exercises actual inline supplier saves and ordinary account/contact regressions. `database/migrations/SystemAdministration/Test.ps1` validates the retired menu and typed tool editors against the same new contracts. These tests copy schema definitions only and insert generated fixtures; optional retained test databases must be cleaned after browser QA.

## Multiple customer brands and branches

Run `Apply-AccountOrganization.ps1` after CRM 017–019 and the current customer/content migrations. It takes and verifies a full COPY_ONLY backup, then applies 020–022 under the shared write lock in one transaction. Existing scalar brand/branch assignments and former supplier coverage become canonical memberships; missing assignments remain unassigned. No login, category grant or inferred branch is created. `AccountOrganizationMigration.ps1` reasserts current contracts after older feature deployment runners, without reseeding removed membership. Deploy matching Portal DLL, account forms, guide permission/customer pages and scripts together.

`CRM_Save_Accounts` accepts `<Account_Brands><Brand ID="1"/></Account_Brands>` and `<Account_Branches><Branch ID="10"/></Account_Branches>`. At least one brand is required; branches are optional. Server checks active new assignments, branch hierarchy, account version, owner/admin scope and tools that still reference supplier brands. Profile/login/logo saves remain atomic. Customers see all eligible assigned-brand news, information pages, circulars and guides together; news/circular/guide filters run locally. Guides still require exact independent category rights. Brand removal revokes direct links/files immediately and does not duplicate notifications or mail recipients.

Checks: `Test-CRM-TypePage.ps1 -IncludeManagement -MultiBrandOnly` and `../CustomerPortal/Test-CustomerPortal.ps1 -MultiBrandOnly` use schema-only synthetic SQL databases and real ASP.NET hosts. Use Windows PowerShell 5.1 for the .NET Framework hosts. SQL checks include hierarchy FKs, many-brand/many-branch saves, optional branches, concurrency/audit, category rights, inactive/membership revocation, information grants and circular notice/mail eligibility.
