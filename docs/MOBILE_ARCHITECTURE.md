# Mobile backend structure

The mobile backend now separates HTTP handling, application workflows, shared
contracts, and infrastructure adapters. It retains Web API 2/.NET Framework and
the existing business behavior. No test projects or tests were added.

| Concern | Location |
| --- | --- |
| Request models and stable response contracts | `src/ProstoERP.Contracts/Features/<feature>` |
| Login, devices, content and session authentication | `src/ProstoERP.Application/Features/EmployeeAccess` |
| Feedback, correspondence, circulars and customer workflows | `src/ProstoERP.Application/Features/<feature>` |
| Application ports, request metadata and upload/file results | `src/ProstoERP.Application/Abstractions` |
| Named persistence operations and row mapping | `src/ProstoERP.Application/Data` |
| SQL definitions, execution, tokens, settings, SMTP and password reset | `src/ProstoERP.Infrastructure.Mobile` |
| Existing VB LINQ-to-SQL model and attendance integration | `src/ProstoERP.Infrastructure` |
| Controllers, authorization, multipart HTTP adapters and response rendering | `src/ProstoERP.Api` |
| Dependency wiring | `src/ProstoERP.Api/Composition` |

## Dependencies

```text
API -> Application -> Contracts
API -> Infrastructure.Mobile -> Application + Contracts
Infrastructure.Mobile -> existing VB Infrastructure + Encryptor
Portal -> existing VB Infrastructure + Encryptor
```

Application does not reference either Infrastructure project or ASP.NET. The
previous training catalog dependency was inverted: the Application service uses
an interface, and Infrastructure.Mobile contains the unchanged LINQ projections.
Contracts and Application target .NET Framework 4.7.2. The new server adapter
targets .NET Framework 4.8, matching the API and its existing MailKit assembly.
No package versions or application target frameworks were upgraded.

The separate C# adapter is intentional: the existing Infrastructure project is
VB and owns generated database code. Keeping it intact avoids translating its
generated model or introducing custom mixed-language build targets.

## Six cleanup areas

1. **Response contracts.** Login/profile/lookups, session/device status, news,
   information pages, feedback options/routing/details, correspondence envelopes,
   customer login/session, password reset, and pagination have named contracts.
   Swagger actions describe the stable response boundaries. Existing `Success`,
   `Data`, `Error`, `Count`, `Session`, `Total`, `TotalItems`, and root password-reset
   `Message` shapes remain distinct. Dynamic database-row dictionaries and session
   extension fields remain where the existing API returns arbitrary procedure
   columns; they have not been silently narrowed or renamed.
2. **Thin controllers.** Employee access/content, circulars, employee feedback,
   correspondence, public customer feedback and customer portal controllers
   delegate workflows. HTTP authorization, binding, multipart parsing, response
   formatting and file headers stay in the API. Application receives request
   metadata and uploads through interfaces, without HttpRequestMessage or MVC types.
3. **Infrastructure persistence.** Connection ownership, command construction,
   query execution and transaction disposal live in Infrastructure.Mobile.
   Feedback/correspondence/customer workflows use named `MobileStatement` values;
   their 76 SQL/procedure definitions live beside the matching infrastructure
   features. Existing parameter order, result tables, SQL text, command kinds,
   timeouts, transaction calls and attachment commit/rollback ordering are retained.
   DataSet-based adapters are kept for legacy result-set compatibility.
4. **Focused dependencies.** Options, token generation/hash validation, password
   encryption, asset URLs, SQL queries and data sessions have separate components.
   MobileBackend wires them, and MobileDependencyResolver supplies controllers.
   Request workflows and their retry state are created per controller/request;
   database connections are never shared between requests. MobileApiSupport is a
   small compatibility facade for token validation, transport and HTTP responses.
5. **Shared validation and errors.** MobileValidation owns common model, paging
   and event/time validation. MobileErrorHandler owns feature-specific mappings,
   including password-reset SMTP failures. Original statuses, codes, Arabic/English
   messages, Bearer/Basic challenges, Retry-After and no-cache behavior are retained.
   Feature-specific bounds and authorization checks remain at their existing stages.
6. **Deployment preparation.** Basic credentials now come from ignored Web.config
   settings rather than compiled source. The existing local values were migrated
   unchanged. Release staging uses sanitized settings and records remaining
   production requirements. See [API deployment](API_DEPLOYMENT.md).

The existing empty-value JSON handler still omits nulls, empty strings and empty
collections recursively, while retaining false, zero, list elements and ordering.
No SQL migration, production deployment, framework migration or namespace-wide
rename is part of this cleanup. Public WebForms paths remain unchanged.

## Working on a mobile feature

Add request and response DTOs to Contracts, workflow code to Application, named
SQL statements or typed stores to Infrastructure.Mobile, and route/authentication
metadata to its API controller. Wire dependencies through Composition. Reuse the
existing feature's error mapping and JSON envelope. Preserve SQL transaction
boundaries and idempotency/file ownership when editing upload workflows.

Legacy ERP integration endpoints outside the Mobile Swagger module retain their
existing structure. Further typing of dynamic SQL rows should be a deliberate
contract review against the actual database, rather than guessing its columns.

Build checks and local Swagger/HTTP checks can be run without invoking the
existing database setup or feature verification tools. Successful database write,
SMTP and multipart attachment flows require the appropriate environment and have
not been exercised as part of this structural cleanup.
