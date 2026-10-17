# Mobile backend foundation

The API is ASP.NET Web API 2 on .NET Framework 4.8. It is not the ASP.NET Core
host used by MOE. The contracts project follows MOE's separation of shared DTOs
from controllers and persistence, while retaining this API's existing wire format.

## Response handling

Before this extraction, mobile responses were mostly anonymous objects created
in controllers. `MobileApiSupport.Error` supplied the common error envelope and
several controllers had their own success/no-cache helpers. Other legacy and
integration endpoints have different response shapes. They are not all rewritten
into a new envelope in this step.

The shared response contracts now live under
`src/ProstoERP.Contracts/Common`:

- `BaseResponse`: `Success` and optional `Error`.
- `BaseResponse<T>`: the same envelope with typed `Data` on success.
- `ApiError`: machine-readable `Code` and user-facing `Message`.

`src/ProstoERP.Api/Shared/Responses/ApiResponseHandler.cs` creates typed success
and error HTTP responses. It retains the existing no-store/private cache policy
and Bearer challenge for unauthorized mobile responses. `MobileApiSupport.Error`
delegates to it, so existing mobile authentication and validation failures share
the contracts without changing their status codes or messages. Login and device
access use the typed success envelope; their existing payload projections remain
unchanged. Logout uses the no-payload success contract. Existing list responses retain top-level fields such
as `Count` and `Session`; existing endpoint-specific and integration envelopes
retain their field names and nesting.

MOE's `Code`, `HasError`, and `Description` envelope is intentionally not copied
over this API's `Success`, `Data`, and `Error` fields. That would break existing
mobile consumers. The reusable contracts/handler pattern is shared with MOE;
the current API's field names remain its own.

## Empty JSON values

`OmitEmptyJsonValuesHandler`, registered in `WebApiConfig`, omits object properties
whose serialized values are null, empty strings (`""`), empty arrays, or empty
objects/dictionaries. It works recursively, including dictionary values from SQL
rows and properties inside array items. If all children disappear, the now-empty
parent property disappears too.

For example:

```json
{"Success":true,"Data":{"Name":"","Optional":null,"Items":[],"Active":false,"Count":0}}
```

becomes:

```json
{"Success":true,"Data":{"Active":false,"Count":0}}
```

False, zero, nonempty strings (including whitespace-only strings), dates, record
ordering, and count values are preserved. Array elements are not removed, since
that would change indexes and record counts. A root array remains an array even
when empty; an empty `Data` property inside an envelope is omitted. Mobile code
must treat missing optional properties and missing empty `Data` collections as
absent/empty, rather than assuming every key is returned.

This policy applies to Web API JSON object responses, including mobile auth
errors. It does not modify incoming JSON or required-field validation, XML
responses, binary/file/stream responses, MVC pages, or Swagger's schema document.
Status codes and response headers are retained; content length is recalculated.
The handler buffers the serialized JSON tree to inspect nested values; paginate
large result sets rather than returning unbounded payloads.

## Contracts project

```text
src/ProstoERP.Contracts/
  Common/
  Features/
    Attendance/Models/
    Circulars/Models/
    Correspondence/Models/
    CustomerFeedback/Models/
    CustomerPortal/Models/
    EmailNotifications/Models/
    EmployeeAccess/Models/
    Feedback/Models/
    Learning/Models/
    News/Models/
    PasswordReset/Models/
  Properties/
```

All 12 existing request-model files move unchanged, including DataAnnotations,
login normalization, extension-data checks, and attendance validation. Their
existing namespaces stay intact to preserve Swagger schema identifiers and
avoid mass controller changes. DTOs now compile into `ProstoERP.Contracts.dll`.
Rebuild consumers after the assembly extraction. `InternalsVisibleTo` preserves
the API's access to the existing internal login normalization method.

The project targets .NET Framework 4.7.2 to build with the current Mono and Rider
toolchains. It depends only on framework libraries, DataAnnotations, and the
existing Newtonsoft.Json 13.0.4 package; it has no database or ASP.NET reference.
It is not a .NET 10 or .NET Standard mobile-client library. Android/Kotlin clients
consume the HTTP/OpenAPI contract rather than referencing this DLL. A portable
.NET client library would need a separate target-framework decision.

Keep new endpoint DTOs here, grouped by business feature. Avoid adding SQL,
DataContext entities, HttpRequestMessage, authentication implementations, or
controller dependencies to Contracts. Use concrete response DTOs for new payloads
and document them on actions with Web API's `ResponseType` attribute, for example
`[ResponseType(typeof(BaseResponse<YourResponseDto>))]`. Prefer
`ApiResponseHandler.Success(Request, dto)` and
`ApiResponseHandler.Error(Request, status, code, message)` for new mobile actions.
The envelope's payload remains optional on the wire under the empty-value policy.

Existing endpoints still include anonymous and SQL-derived response payloads.
This project is a foundation, not a complete typed client contract for every
legacy response. Add concrete response DTOs as each mobile feature is developed;
do not expose new database columns automatically.

## Contract export and local workflow

Build without invoking setup, database changes, or tests:

```sh
msbuild ERP_Prosto.sln /t:Build /p:Configuration=Debug /m:1 /nr:false /p:UseSharedCompilation=false /verbosity:minimal /nologo
```

Run **ERP Aspire (native)**, then browse `/swagger` on API port 3001. Export the
running API's actual Swagger 2.0 contract with:

```sh
python3 scripts/export_api_contract.py
```

The export goes to ignored `artifacts/contracts/prosto-erp-v1.openapi.json`.
`--url` and `--output` select another environment or destination. Use this file
for mobile client generation and review endpoint changes alongside the C# DTOs.
Because legacy actions return HttpResponseMessage/anonymous payloads, some existing
response schemas remain generic until those actions receive explicit response DTOs.

## Deployment preparation

Nothing is deployed by this step. Choose the hosting environment before creating
its deployment configuration. The current host requires ASP.NET Web API 2/.NET
Framework hosting, ordinarily Windows/IIS with the matching ASP.NET build tools;
it cannot be deployed as the MOE .NET 10 host unchanged. Local Mono/XSP and Aspire
are the development setup.

Build a release API artifact using the matching classic MSBuild toolchain:

```sh
msbuild src/ProstoERP.Api/ProstoERP.Api.csproj /t:Build /p:Configuration=Release /verbosity:minimal /nologo
```

The contracts DLL is copied into the API's `bin` directory through its project
reference. A deployable web artifact also needs its content/configuration files;
copying the bin directory alone is not a complete deployment. Environment-specific
Web.config values and secrets must be supplied by the chosen release process.
Do not publish local credentials, development keys, or `.local-development` files.

Before a real deployment, resolve these existing environment dependencies:

- The complete ERP schema, stored procedures, and approved migrations; the inferred
  local development database is not a complete production database.
- The compatible production Encryptor implementation/key. The current source-built
  Encryptor is development-only and cannot read original production passwords.
- HTTPS, the intended public API and asset URLs, integration credentials, email
  configuration, upload storage, and the existing mobile transport/session settings.
- A release artifact built with configuration for that environment, with Swagger
  exposure and authentication appropriate to the selected hosting configuration.

No tests or test projects are added by this foundation work.
