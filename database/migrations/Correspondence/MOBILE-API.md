# Correspondence API — application developer contract

Implemented source contract, 2026-09-26. Prefix: `https://<API-HOST>/api/v1/correspondence`. Obtain the deployed API host from the deployment owner; the portal/asset host is separate. Local implementation and integration tests do not confirm external deployment.

Import `Correspondence.postman_collection.json` beside this document. Existing login/device contracts remain in `docs/MOBILE-API.md` and `database/migrations/Mobile_API/`. No new login or token format is introduced.

## Authentication and conventions

- Every route requires HTTPS and `Authorization: Bearer <AccessToken>` from existing `POST /api/Users/Login`. Expired/revoked sessions, disabled accounts and unapproved devices are checked by the existing mobile session filter.
- Send the logged-in user's **Employee_Number** as `employeeNumber` in GET queries or `EmployeeNumber` in POST bodies. It is not the internal user ID. The actor is always taken from the token; sending another employee number returns 403.
- Recipient IDs, thread IDs and message IDs are internal IDs returned by this feature. Obtain recipient IDs from `/recipients`; never substitute employee numbers.
- `Accept: application/json`. JSON POSTs use `Content-Type: application/json`; create/reply use multipart even without files.
- Successful responses are HTTP 200: `{"Success":true,"Data":...}`. Errors: `{"Success":false,"Error":{"Code":"...","Message":"..."}}`. Responses use `Cache-Control: private, no-store`.
- Preserve property casing. Response timestamps are UTC ISO 8601 with `Z`; render in the user's local timezone. Send explicit offsets or `Z` for `OccurredAt` and `DueDate`. SQL/server time determines creation, closure and first-read times; device time is audit metadata only.
- Treat all message/name/title/explanation fields as plain text. Database nulls are JSON null, empty arrays are `[]`. Do not infer completion from a read receipt or from an archive.
- Catalogs are shared across brands. System administrators manage them in the portal; the app only consumes available options. Never hard-code IDs, names or urgent styling. New sends/closures revalidate active options, including submissions from stale screens.

## Operation identity and retries

Every JSON mutation and multipart `data` object contains:

```json
{
  "EmployeeNumber": 82004,
  "OperationID": "81b840f8-ddde-493b-a12e-dfdd7b1b7f8a",
  "OccurredAt": "2026-09-26T12:00:00Z"
}
```

Generate a UUID for each new action. Persist it with the original body, original file bytes/names/order and `OccurredAt` until success. On network timeout, 500 or `RETRY_OPERATION`, resend that **same** operation and payload. Do not regenerate the timestamp or UUID on retry. Successful retries return the saved IDs plus `Replayed:true`; first execution returns `Replayed:false`. Reusing an operation with changed data, route or action returns 409 `OPERATION_REUSED`. To change the request after a validation failure, generate a new operation.

Creation, replies, closure, message-read, notification-read and administrative archive are transactional with operation records. Duplicate retries do not create additional messages, files, notifications or completion changes. Operations are scoped to the authenticated actor. Device time must be year 2000 or later and no more than five minutes ahead of server time.

`/open` is a read operation with a visit identifier. Repeating it returns fresh detail. In supervisory mode the same `OperationID` produces only one administrative-view audit record per thread/actor. Generate a new visit UUID when opening a different screen visit, and retain `Data.VisitID` for its message fetches. It does not mark messages or notifications read.

## Route summary

| Method | Path after prefix | Purpose |
|---|---|---|
| GET | `/options` | Current permissions, catalogs, organizational selection options and limits |
| GET | `/recipients` | Allowed recipients, search and pagination |
| GET | `/threads` | Personal/administrative list and filtered counters |
| POST | `/threads` | Create one independent conversation per recipient; multipart |
| POST | `/threads/{id}/open` | Details, historical/current organization, related threads, administrative visit |
| GET | `/threads/{id}/messages` | Paged messages, current permissions and attachment URLs |
| POST | `/threads/{id}/messages` | Reply with text and/or files; multipart |
| POST | `/threads/{id}/read` | Acknowledge explicitly displayed incoming messages |
| POST | `/threads/{id}/close` | Creator selects outcome and closure reason |
| GET | `/notifications` | Personal notices and distinct unread counters |
| POST | `/notifications/{id}/read` | Acknowledge one owned notification |
| POST | `/threads/{id}/archive` | System administrator archives when creator account is inactive |

## 1. Options and recipients

`GET /options?employeeNumber=82004&task=false&brandID=0`

`task` defaults false. Use true when selecting closure reasons for a task; ordinary correspondence excludes reasons with transfer behavior. `brandID` defaults 0; for an administrator refresh options after choosing a brand. Other roles are constrained to their current organization regardless of this filter.

Response `Data`:

| Field | Meaning |
|---|---|
| `Identity` | `{UserID,UserType}` from current active account |
| `Permissions` | `CanCreate`, `CanCreateTask`, `CanBroadcast`, `CanSupervise` |
| `Priorities`, `ClosureReasons` | Active choices only |
| `PriorityFilters` | Includes inactive choices for historical searching |
| Catalog item | `{ID,Title,SortOrder,IsUrgent,Behavior,IsActive}`; descending SortOrder; Behavior is `normal` or `transfer` |
| `Brands` | Current active brand choices `{ID,Title}`, administrator only |
| `RecipientBranches`, `RecipientShifts` | `{ID,Title}` represented among currently allowed recipients for the chosen brand |
| `HistoricalOrganization` | `{Kind,ID,Title,ParentID}` snapshot brand/branch choices for oversight search; distinct from current recipient options |
| `FileRules` | `MaxFiles=5`, `MaxFileBytes=10485760`, allowed extensions |
| `Limits` | Title 200, brief 2000, body 4000, reason 1000 characters; recipients 1 for employee, up to 100 for authorized managers |
| `PollIntervalSeconds` | 30; polling recommendation, not push delivery |

If an active options array is empty, show an explanation and disable the related submission; refer the user to the administrator. `PriorityFilters` is for searching only, not new sends. Use the thread's snapshot `PriorityName`/`PriorityUrgent` for display, not today's catalog label.

`GET /recipients?employeeNumber=82004&brandID=0&branchID=0&shiftID=0&search=&page=1&pageSize=30`

All filters optional except employeeNumber. Search max 200 characters. Pages start at 1, maximum 100000; pageSize 1–100. Default pageSize 30. Administrator must choose a brand (`brandID>0`) to obtain recipients. Response:

```json
{"Success":true,"Data":{"TotalItems":1,"Page":1,"PageSize":30,"Items":[{"ID":2,"FullName_Ar":"مدير الفرع","Type":2,"Brand_ID":29,"Branch_ID":25,"Shif_ID":1}]}}
```

IDs/types/scope follow the portal's recipient rules. Type 4 employees select one permitted branch/shift manager. Managers can select multiple permitted recipients; each gets an independent conversation. Moving an employee changes these choices, while participation in existing conversations remains.

## 2. Thread list and counters

`GET /threads?employeeNumber=82004&page=1&pageSize=20&supervisory=false`

Optional filters: `title`, `person` (max 200 characters each), `filter`, `kind`, `priorityID`, `brandID`, `branchID`, `from`, `to`.

- `filter`: `all` (default), `active`, `overdue`, `closed`, `archived`, `unread`, `noReply`, `followup`, `legacy`.
- `kind`: 0 all, 1 ordinary correspondence, 2 task. IDs default 0 for all.
- `from` inclusive / `to` exclusive filter creation time. Send URL-encoded ISO timestamps with explicit offset; convert a local date range to instants in the app. `from` must precede `to`.
- Brand/branch filters use organizational **snapshots**, not current employee assignment. `legacy` identifies old threads whose organizational snapshot was never recorded.
- `supervisory=true` is system-administrator-only across brands. Default false returns only conversations in which the actor participates, even for an administrator.
- Sort: stored priority rank descending, last message time descending, ID descending. pageSize defaults 20, allowed 1–100. Reconcile refreshed lists by ID because new activity can move rows between pages.

`Data` is `{TotalItems,Counts,Page,PageSize,Items}`. Counts cover all matching rows before pagination: `TotalThreads`, `NoReply`, `OverdueTasks`, `FollowUp`, `Completed`, `NotCompleted`, `Archived`.

Important thread fields (additional stored fields may be returned):

| Fields | Meaning |
|---|---|
| `ID`, `Title`, `Brief`, `SenderID`, `ReceiverID`, `CreatedBy` | Identity/content; creator controls completion |
| `RequiresCompletion`, `DueDate`, `IsCompleted` | Task flag; nullable due date and outcome. Ordinary correspondence has null outcome |
| `Priority`, `PriorityName`, `PriorityRank`, `PriorityUrgent` | Catalog ID plus immutable display snapshot |
| `State` | `active`, `overdue`, `closed`, `archived`; prefer this over legacy numeric Status |
| `CreatedDate`, `LastMessageDate`, `FirstReplyDate`, `CloseDate`, `ArchivedAt` | UTC/null timestamps |
| `MessageCount`, `UnreadCount` | Thread counts; UnreadCount belongs to the authenticated actor |
| `SenderName`, `ReceiverName`, `OtherName` | Counterparty/display names |
| `SenderImage`, `ReceiverImage`, `OtherImage` | Absolute asset URLs or null |
| `ClosureReasonID`, `ClosureReasonName`, `ClosureKind`, `CloseReason` | Selected reason snapshot, stable behavior, free-text explanation |
| `RelatedThreadID`, `IsBroadcast`, `BroadcastID` | Replacement link and independent bulk-send grouping |
| `LegacyOrganization`, `InactiveParty`, `InactiveCreator` | Follow-up/report indicators |
| `SenderBrandID/Name`, `SenderBranchID/Name`, receiver equivalents | Historical scope when available |
| `IsParticipant`, `IsAdmin` | Access flags, not a substitute for current action permissions |

## 3. Create a thread

`POST /threads` with `multipart/form-data`:

- Exactly one text part named `data` containing JSON (max 64 KiB).
- Zero to five file parts named `files` with filenames. Let the HTTP library generate the multipart boundary.
- Do not send URLs, stored filenames or arbitrary attachment IDs as substitutes for uploads.

Example `data`:

```json
{
  "EmployeeNumber": 82002,
  "OperationID": "85e1deaf-9adc-4ffd-86ae-5966bfc7ab58",
  "OccurredAt": "2026-09-26T12:00:00Z",
  "RecipientIDs": [4,5],
  "BrandID": 0,
  "Title": "متابعة تجهيز الفرع",
  "Brief": "متابعة الوردية المسائية",
  "Body": "يرجى مراجعة التجهيزات وإرسال النتيجة.",
  "PriorityID": 2,
  "RequiresCompletion": true,
  "DueDate": "2026-09-27T15:00:00+03:00",
  "RelatedThreadID": null
}
```

Required feature fields: nonblank Title, PriorityID, unique RecipientIDs. Brief/Body/DueDate/RelatedThreadID nullable. Body may be empty only when files exist. RequiresCompletion defaults false, BrandID defaults 0. A due date must be in the future and belongs to a task. Type 4 cannot create tasks or specify a due date. The administrator must specify the selected BrandID.

Response: `{"Success":true,"Data":{"ThreadIDs":[101,102],"Replayed":false}}`. One thread per recipient; if any recipient is invalid, the entire operation fails. Returned IDs do not imply order matching the supplied recipient array; fetch each thread to identify its receiver.

## 4. Open and fetch messages

`POST /threads/101/open`, JSON operation fields plus `"Supervisory":false` (default).

Response: `{Thread,Organization,Related,VisitID,Audit}`. Thread includes `CanReply`, `CanClose`, `CanArchive` calculated from current state. Organization contains both parties' saved IDs/names/type and current names/organization for comparison; legacy rows can produce an empty array. Related contains only accessible `{ID,Title}` threads. Audit is returned only in supervisory mode (latest 100 administrative events; full database history retained).

For administrative inspection, send `Supervisory:true`, then use `supervisory=true&visitID=<Data.VisitID>` on message fetches. This records oversight without changing recipient read status. Personal mode requires actual participation; an administrator cannot implicitly read a nonparticipant thread in personal mode.

`GET /threads/101/messages?employeeNumber=82004&pageSize=30&afterID=0&beforeID=0`

- Default fetch returns the latest page. `beforeID=<OldestID>` fetches older history; `afterID=<LatestID>` fetches newly arriving messages. Never supply both positive cursors.
- Items are always returned oldest-to-newest within the selected page. `HasMore` refers to the requested direction. pageSize 1–100 (default 30).
- `Data` is `{Thread,Items,Attachments,HasMore,OldestID,LatestID}`. Empty pages have null cursor IDs; retain your existing cursors rather than resetting them.
- Message fields: `ID,ThreadID,SenderID,ReceivedID,Body,CreatedDate,IsRead,ReadDate,SenderName`.
- Attachment fields: `ID,MessageID,FileName,File_Type,FileSize,Url`. Associate by MessageID. Only files for this page's messages are returned.
- GET/open never marks messages read. While the screen is visible, acknowledge displayed incoming IDs explicitly. Polling for new IDs alone does not update receipts on old messages: also refresh the displayed message page to refresh `IsRead`/`ReadDate` and current action permissions. Pause read acknowledgement when the app is backgrounded.

## 5. Reply and acknowledge reads

`POST /threads/101/messages`: same multipart format as create. `data` has operation fields and optional `Body` (max 4000). A body or attachment is required. Only participants can reply to an open thread.

Response: `{ThreadID:101,MessageID:501,Replayed:false}`.

`POST /threads/101/read`: JSON operation fields plus `"MessageIDs":[501,502]` (1–100 unique positive IDs). Every ID must belong to this thread and be an incoming message for this actor. Already-read IDs are valid; the original server `ReadDate` remains unchanged. Response `{ThreadID,MessageIDs,Replayed}`. This does not mark notifications read and does not indicate work completion.

## 6. Close and transfer responsibility

`POST /threads/101/close`:

```json
{
  "EmployeeNumber":82002,
  "OperationID":"1f56f5c8-4eaf-40f6-8919-8d0a9b0a5351",
  "OccurredAt":"2026-09-26T13:00:00Z",
  "ClosureReasonID":3,
  "IsCompleted":true,
  "Explanation":"تم التحقق من الإنجاز"
}
```

Only the creator can close. A task requires explicit true/false IsCompleted; ordinary correspondence stores null. Normal closure requires a reply from the other participant. A transfer-behavior reason is task-only, requires nonblank Explanation and an explicit outcome, and may be selected before the first reply. `CanClose` means the closure screen is available; individual reason rules still apply.

ClosureReasonID comes from active options; Explanation is separate and limited to 1000 characters. Response `{ThreadID,Replayed}`. Closed threads and their files remain readable and reject further replies/closure.

Transfer workflow: close with a reason whose Behavior is `transfer`, then create a new task with `RelatedThreadID` equal to the closed task's ID and a newly chosen allowed recipient. Use a new OperationID for the new task. These are two deliberate actions; original participants/history are preserved. The creator may start linked replacement tasks, and Related returns links visible to the current viewer.

## 7. Notifications

`GET /notifications?employeeNumber=82004&page=1&pageSize=20&unreadOnly=false`

Response `{TotalItems,UnreadNotifications,UnreadThreads,Page,PageSize,Items}`. TotalItems follows unreadOnly; counters cover all owned accessible notices/threads. Sort ID descending. Each item: `{ID,ThreadID,MessageID,SendDate,IsRead,Title}`. MessageID is nullable (closure notification).

`POST /notifications/601/read`: JSON operation fields only. Response `{NotificationID,Replayed}`. Only the notification owner can acknowledge it. This changes no message read receipt. There is no FCM/APNs delivery in this change; use polling and the existing session/device flow.

## 8. Administrative archive

`POST /threads/101/archive`: operation fields plus required nonblank `Explanation` (max 1000). Active system administrator only; the thread must be open and its creator inactive/deleted. This is administrative retention, not a completion verdict. Response `{ThreadID,Replayed}`. ArchivedAt is set, IsCompleted stays null, replies and closure are blocked.

## Files

Storage and direct links remain the portal's existing `FileManager/Correspondence` behavior. Each file max 10 MiB; at most five files, request body max 51 MiB. Extensions: pdf, doc, docx, xls, xlsx, png, jpg, jpeg, gif. Signatures/Office structure are validated as in the portal; macro-containing OOXML is rejected. Images are limited to 20 million pixels and normalized to PNG. File_Type is a MIME type; stored filenames are generated, not original device paths.

Use returned absolute Url as-is. It is an asset-host URL, not a Bearer-protected API download endpoint. Do not forward the API token to that host. The existing direct-link protection policy was intentionally preserved. Message/file discovery still requires authorized thread access.

## Errors and client handling

| HTTP | Code | Handling |
|---|---|---|
| 400 | `INVALID_REQUEST`, `BUSINESS_RULE` | Correct fields or refresh current options/thread; show Message. Business rules include inactive catalogs, unsupported supervision and missing task outcome |
| 400 | `FILE_TYPE`, `INVALID_FILE` | Replace the attachment |
| 401 | `SESSION_INVALID` | Use existing login/device recovery; no refresh-token API |
| 403 | `HTTPS_REQUIRED` | Correct API transport configuration |
| 403 | `EMPLOYEE_MISMATCH` | Use employee number from this token's login profile |
| 403 | `ACTION_NOT_ALLOWED`, `RECIPIENT_NOT_ALLOWED` | Refresh permissions/recipients; do not use IDs from unrelated accounts |
| 403 | `OPEN_REQUIRED` | Open the administrative visit and pass its VisitID |
| 404 | `NOT_FOUND` | Resource is unavailable in this scope or belongs to another user |
| 409 | `THREAD_CLOSED`, `CANNOT_CLOSE` | Refresh detail; do not present a successful outcome |
| 409 | `OPERATION_REUSED` | Same UUID was used with a different action/payload; reconcile before creating a genuinely new action |
| 409 | `RETRY_OPERATION` | Retry unchanged request with the same UUID |
| 413 | `UPLOAD_LIMIT` | Reduce attachment size/count |
| 415 | `MULTIPART_REQUIRED` | Use multipart with one data part |
| 500 | `SERVER_ERROR` | Retry unchanged operation; report repeated failures |

IIS may reject an oversized request before the controller; this host-level response is not guaranteed to use the JSON envelope. Keep uploads below FileRules before sending.

## Deployment and verification

1. Use the existing mobile sessions/device migrations through `Mobile_API/006_DeviceAccess.sql`, and correspondence migrations through 007.
2. Apply `ApplyMobileApi.ps1` (008), transactionally and repeatably. It creates the operation table, identity check and paginated readers; it does not replace shared portal mutation procedures.
3. Build/deploy `Prosto_ERP_API`, including `CorrespondenceController.cs`, `CorrespondenceFiles.cs` and the System.IO.Compression reference. Existing MobileApi/FeedbackDb infrastructure is reused.
4. Configure `MobileApi.CorrespondenceStoragePath` to the **same absolute shared directory** the portal uses for `FileManager/Correspondence`. Give the API process the necessary write access. `MobileApi.AssetBaseUrl` must be the HTTPS host/path that serves that directory. Do not assume a local development path exists on another server.
5. Existing request limits are 52224 KiB at ASP.NET and 53477376 bytes at IIS. Preserve appropriate limits at the reverse proxy too.
6. Run `Test-MobileApi.ps1 -BuildDirectory <compiled API directory>`: an isolated SQL database, synthetic accounts, in-memory HTTPS Web API host, real Bearer authentication, controllers, transactions and files. Test databases and files are cleaned by the test runner. No test messages are sent to actual employees.

The app's screens, actual device behavior, external HTTPS deployment and asset-host accessibility must be verified by the application/deployment team against its environment.
