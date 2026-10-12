# BioTime attendance API: deployment and Postman contract

## Implementation inventory

Created:
- `Prosto_ERP_API/Controllers/AttendanceController.cs`: protected POST route, guarded existing Basic authentication, input checks, clean PascalCase responses, no-store caching and sanitized logging; clears model credential references after processing.
- `Prosto_ERP_API/Attendance/AttendanceTransactionsRequest.cs`: five input properties, strict date validation and unknown-field rejection.
- `Prosto_ERP_API/Attendance/BioTimeAttendanceService.cs`: request-local JWT authentication, encoded transaction filters, all-page retrieval, bounded retry, safe pagination and clean integration errors.
- `Database/BioTime/BioTime.IntegrationTests.cs`, `Test-BioTime.ps1`: isolated fake HTTP upstream tests and in-memory Web API route tests; no SQL or real BioTime mutation. Test configuration copies only runtime assembly redirects, never application credentials/connection strings.
- `Database/BioTime/README.md`: client contract and deployment instructions.

Modified: API `.csproj` registers the three new source files; workspace `docs/FEATURE-MAP.md` registers F23 and `docs/ARCHITECTURE.md` describes the new shared outbound HTTP pattern. The Portal extension below adds UI, shared storage and SQL migration; no packages or hosting changes.

## Postman

Method: **POST**

URL: `http://92.253.126.181:1098/api/attendance/transactions`

Authorization tab: **Basic Auth**, using the selected brand attendance API credentials after settings are saved. Saved brand credentials are required; there is no attendance fallback when settings/procedures are absent. Legacy ERP/training/non-token news retain the original fixed integration authentication; employee mobile login does not require ERP Basic. These are separate from the BioTime credentials. Do not place BioTime credentials in the Authorization header. Obtain existing API credentials from the administrator; this document does not copy them.

Headers: `Content-Type: application/json`, `Accept: application/json`.

Body tab: raw / JSON:

```json
{
  "username": "YOUR_BIOTIME_USERNAME",
  "password": "YOUR_BIOTIME_PASSWORD",
  "employeeCode": "1001",
  "fromDate": "2026-10-01",
  "toDate": "2026-10-06"
}
```

All five fields are required and nonblank; employeeCode is limited to 200 characters. Dates must be valid calendar dates in exactly `yyyy-MM-dd`, with fromDate <= toDate. Unknown body fields and deserialization/model-state errors are rejected before BioTime calls. Dates are BioTime local wall-clock dates; no UTC conversion is applied. Passwords are not trimmed or normalized. Employee codes are strings and URL-encoded, including leading zeros/special characters. The caller cannot choose a target, endpoint, pagination URL or token.

## Response examples

Examples are illustrative, not evidence of live server results. Top-level casing follows existing API conventions; transaction keys preserve BioTime casing and useful fields, including unknown transaction fields. Credential-like fields in unexpected upstream transaction objects are removed recursively.

200 with transactions:

```json
{"Success":true,"EmployeeCode":"1001","FromDate":"2026-10-01","ToDate":"2026-10-06","Count":1,"Data":[{"id":12345,"emp_code":"1001","first_name":"Mohammad","punch_time":"2026-10-01 08:03:22","punch_state":"0","verify_type":1,"terminal_sn":"ABC123"}]}
```

200 without transactions for an allowed employee (configured brand credentials reject unknown/foreign employees with 403 EMPLOYEE_FORBIDDEN):

```json
{"Success":true,"EmployeeCode":"1001","FromDate":"2026-10-01","ToDate":"2026-10-06","Count":0,"Data":[]}
```

401 invalid BioTime credentials:

```json
{"Success":false,"Code":"BIOTIME_INVALID_CREDENTIALS","Message":"BioTime credentials were rejected."}
```

400 invalid input:

```json
{"Success":false,"Code":"VALIDATION_ERROR","Message":"username, password and employeeCode are required; fromDate and toDate must use yyyy-MM-dd with fromDate <= toDate. Additional fields are not allowed."}
```

503 BioTime unavailable / refused connection:

```json
{"Success":false,"Code":"BIOTIME_UNAVAILABLE","Message":"BioTime is unavailable."}
```

Other errors: 503 `API_UNAVAILABLE` for attendance authentication database failures; 500 `API_UNAVAILABLE` for unexpected authentication infrastructure failures; 403 `EMPLOYEE_FORBIDDEN` for configured-brand employee scope failures; 401 `API_UNAUTHORIZED` for missing/invalid public API authentication; 401 `BIOTIME_UNAUTHORIZED` after the single retry; 403 `BIOTIME_FORBIDDEN`; 502 `BIOTIME_NOT_FOUND`, `BIOTIME_HTTP_ERROR` (other upstream HTTP failures), `BIOTIME_INVALID_RESPONSE`, `BIOTIME_PAGINATION_ERROR`; 504 `BIOTIME_TIMEOUT`; 500 `INTERNAL_ERROR`. Upstream response bodies and exception details are never relayed. No partial success is returned on pagination failure.

## Authentication and retrieval

For each request the service POSTs only username/password JSON to `jwt-api-token-auth/` on the saved brand BioTime root (legacy default `http://127.0.0.1:8089/`), reads `token`, then GETs `/iclock/api/transactions/` using a per-message `Authorization: JWT <token>` header. There is no global token cache or persistence. A transaction 401 causes one fresh authentication and one retry; at most one such retry occurs across the entire operation.

The service encodes `emp_code`, `start_time=fromDate 00:00:00`, `end_time=toDate 23:59:59`. Each nonempty page contributes its transaction objects until next is null/missing or data is empty. Pagination targets must use the saved BioTime scheme, host and port, the exact transaction path, no user info or fragment and only expected filter/page/page_size query keys. Original filters are reapplied; redirects are not followed. Repeated URLs/pages/transaction IDs fail safely. Safety limits: 10,000 pages, 1,000,000 records, 8MiB per response, 30-second HTTP timeout and two-minute total deadline. Exceeding a pagination bound is a failure, not a truncated success.

Administrators configure independent attendance API and BioTime roots per brand. Request bodies cannot select either target. Optional HR URL/username/password are saved only; no HR calls are implemented. The shared .NET Framework HttpClient disables cookies/proxies/automatic redirects and never sets shared Authorization headers. This project has no existing DI container or managed outbound HttpClient pattern, so no new framework is introduced.

## Deployment

1. Build `ERP_Prosto.sln` in Release with the existing Windows/Visual Studio MSBuild tooling. Publish the existing `Prosto_ERP_API` application using the established deployment process; deploy the new API assembly and normal publish dependencies. Preserve server Web.config values and current IIS bindings. Apply 002_BrandIntegration.sql then 003_IntegrationUrlsAndHR.sql then 004_AdminSecrets.sql before configuring brands; publish Portal/shared library too. No package or IIS migration is required.
2. On the actual Windows Server confirm BioTime listens at the configured brand URL, that the IIS worker can reach it, and that the chosen BioTime account has transaction-read permission. Authentication and transactions paths must match the installed BioTime version.
3. Send the Postman request above using existing public API Basic credentials and real BioTime credentials in the body. HTTP is permitted during this test phase; this change introduces no HTTPS redirect or IIS changes.
4. Compare results with BioTime for the same employee and inclusive dates, including more than one page. Check an empty range/unknown employee, invalid credentials, a restricted account, invalid dates, BioTime stopped/unreachable and timeouts. Observe safe error codes.
5. Verify actual server/IIS/APM/request tracing does not capture request bodies or Authorization headers. Source inspection found no incoming-body logging middleware or outbound HTTP diagnostic logging. Application tests verify safe integration logs, but server-installed tracing is outside this workspace.
6. HTTPS production setup remains a separate deployment task as requested.

## Verification

Run `powershell -File ERP_Prosto/Database/BioTime/Test-BioTime.ps1` from the workspace after building. Tests use synthetic credentials and fake HttpMessageHandler responses; they are not live BioTime integration tests.

55 assertions passed in the simulated-upstream/in-memory route suite. Full Release solution build completed successfully. Existing Portal warning BC42104 in ActiveDirectorySearcher.vb remains unrelated. Tests cover required/invalid fields, dates, unknown proxy fields, authentication body, JWT headers, inclusive filters, multi-page aggregation, field preservation, empty/unknown-employee result, invalid credentials, bounded 401 retry, upstream 403/404/400/500/redirect rejection, unavailable/timeout simulation, malformed JSON/token, unsafe URLs/query parameters, repeated pages/IDs, clean success/error envelopes, cleared model credential references, no-store, no credential/token logging, HTTP routing/authentication and malformed Basic headers.

The local 127.0.0.1:8089 connectivity check failed in this development environment. Real authentication, real attendance/filter/pagination semantics, real account permissions, actual network timeouts and public IIS/Postman deployment tests must be completed on the intended server. No live BioTime success is claimed.

## Portal extension: attendance and brand settings

- `/Modules/Employees/MyProfile.aspx?EmployeeID=<database-ID>` shows Jordan-date punches to the owner/system administrator and links “عرض سجل الدوام”. EmployeeID is the account database ID; Employee_Number is BioTime emp_code.
- `/Modules/Employees/AttendanceHistory.aspx?EmployeeID=<database-ID>` supports inclusive dates. Owners are locked to their own identity; administrators select brand/job number, including duplicate numbers across brands. “حركات دوام الموظفين” is linked from Users/ManageUsers.
- `/Modules/Attendance_Integration/ManageAttendanceIntegration.aspx` is linked as “إعدادات API” under system administration. Select a brand, enter attendance API and BioTime URL/username/password, plus optional HR URL/username/password, and save. Blank edit passwords preserve existing values; enable/disable is per brand. Conflicting edits require selecting/reloading the brand again.
- Admin settings alone persist credentials; the POST endpoint still accepts dynamic BioTime credentials without writing them. DPAPI encrypts reusable secrets, while API verification uses salted PBKDF2-SHA256/150,000 iterations. Saved passwords are rendered masked only to SQL-revalidated administrators, with eye buttons; password controls disable ViewState and responses disable caching. Actor/UTC modification time and rowversion are recorded, without a general historical audit system.
- After any settings row exists, attendance accepts only configured enabled/active brand Basic credentials. Legacy credentials no longer bypass brand scoping. Unconfigured brands must be configured; unrelated legacy ERP authentication is unchanged.

Additional files: Portal/AppCode/AttendanceData.vb, Portal/Modules/Employees/AttendanceHistory.aspx (+ code-behind/designer), Portal/Modules/Attendance_Integration/ManageAttendanceIntegration.aspx (+ code-behind/designer), Prosto_ERP_ClassLibrary/AttendanceIntegration.vb, Database/BioTime/002_BrandIntegration.sql, BrandIntegrationTests.cs and Test-BrandIntegration.ps1. Profile, employee management, Site.Master, Portal Web.config (AttendanceApi.BaseUrl and aspnet:UseTaskFriendlySynchronizationContext), Portal/shared-library project registrations, attendance controller/model and knowledge references are updated.

### Extension deployment

1. Apply 002_BrandIntegration.sql then 003_IntegrationUrlsAndHR.sql then 004_AdminSecrets.sql to the shared Portal/API database. Existing credentials are preserved; URL defaults retain previous behavior. It is additive/rerunnable and contains no credentials. Test-BrandIntegration.ps1 -ApplyLocalMigration applies 002/003/004 only to configured localhost SQL. It was applied to the current local database without inserting brand settings/secrets.
2. Publish Portal, API and shared library together, preserving server connection strings. Both applications require the shared database; only the Portal decrypts secrets on the Windows host where they were saved. Do not copy DPAPI-encrypted development settings to another host: enter credentials on the destination. Include DPAPI machine keys and SQL access controls in server backup/recovery planning.
3. Optional Portal appSetting AttendanceApi.BaseUrl defaults to http://92.253.126.181:1098/. If the development API uses another port, configure that trusted API root URL (ending in /) in Portal Web.config. This supplies the initial form default; saved brand ApiUrl controls subsequent attendance calls. Portal Web.config adds AttendanceApi.BaseUrl using the existing public API URL. Preserve/adjust this trusted value during deployment. Set each brand BioTime root in the administrator form; localhost:8089 is the legacy default.
4. Sign in as administrator, configure each brand under “إعدادات API”, then test employee profile/history. Public URL/body are unchanged; Basic uses the relevant brand settings. API 403 EMPLOYEE_FORBIDDEN indicates an inactive/unknown/foreign employee for that brand.

### Extension verification

Release solution build succeeded with the existing unrelated BC42104 warning. 55 simulated-upstream/HTTP assertions and 45 real SQL/authentication assertions passed in a disposable database, subsequently removed. SQL cases include DPAPI roundtrip, distinct brands, wrong passwords, metadata secrecy, admin restrictions, current employee scope, blank edits, optimistic conflicts, rotation, disable/re-enable, duplicate job numbers, foreign-brand access, inactive/retired actors. Test credentials were synthetic.

Test-BrandIntegration.ps1 creates an isolated SQL fixture and calls Test-BioTime.ps1. It does not modify live employees/brand credentials. SQL tests succeeded with local SQL access outside the restricted sandbox. Anonymous browser checks of profile/history/settings redirected to login without ASPX compilation errors. An authenticated browser session was unavailable; final desktop/mobile visuals and admin/employee postbacks remain unverified. Development BioTime localhost:8089 is unavailable, so real punches and actual server/IIS/API connectivity still require the intended server.
The Portal requires appSetting aspnet:UseTaskFriendlySynchronizationContext=true for Task-returning PageAsyncTask callbacks. Deploy the updated Portal Web.config with the pages; compilation targetFramework=4.8 alone does not enable this runtime behavior. The existing httpRuntime limits and compatibility target are retained.

Rollback validation: Release API build succeeded; 55 BioTime HTTP assertions, 42 brand/settings SQL assertions and 88 mobile HTTP/SQL assertions passed (185 total). Attendance credentials, brand scoping, URLs, HR storage, device approvals and sessions remain covered. Authenticated browser visuals and live external connections remain unverified.

API controllers are directly under Controllers. Attendance retains database-backed per-brand credentials and employee scoping; ERP/mobile authentication has its previous contract. HR settings remain storage only.
