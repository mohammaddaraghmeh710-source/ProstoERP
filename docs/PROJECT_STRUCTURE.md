# Project structure

The repository uses the following physical layout. Solution references, launchers,
NuGet package paths, configuration helpers, and database tools follow these paths.
WebForms URLs, API routes, legacy namespaces, and legacy assembly names are retained.

```text
src/
  Portal/
  ProstoERP.Api/
  ProstoERP.Application/
  ProstoERP.Infrastructure/
  Encryptor/
orchestration/
  ProstoERP.AppHost/
database/
  migrations/
  development/
tests/
  Unit/
  Integration/
scripts/
build/
docs/
```

`ProstoERP.Infrastructure` contains the existing VB shared library, including its
LINQ-to-SQL mappings and attendance integration. It continues to produce
`Prosto_ERP_ClassLibrary.dll`, and the API continues to produce `Prosto_ERP_API.dll`.
Preserving these identities avoids changing the existing configuration and types.
The new `ProstoERP.Application` project targets .NET Framework 4.7.2 and references
Infrastructure; the Web API references Application.

The Unit and Integration directories contain placeholders only. Existing feature
verification tools are retained beside their feature migrations, with relative
paths adjusted for the new layout. No test projects or new tests are introduced.

| Solution folder | Contents |
| --- | --- |
| src | Portal, ProstoERP.Api, ProstoERP.Application, ProstoERP.Infrastructure, Encryptor |
| orchestration / ProstoERP.AppHost | Separate .NET 10 AppHost source and launch settings |
| database / migrations | Existing feature SQL scripts and associated documentation |
| database / development | Limited local baseline, migration selection manifest, and trial tooling |
| tests / Unit, Integration | Empty placeholders; no test projects |
| scripts | Local configuration, schema generation, and web-service launchers |
| build | Classic web-project package paths, compiler imports, and Content manifests |
| Run configurations | Shared Rider launch configurations |
| docs | Repository overview, editor settings, and this guide |

## Build and run

`ERP_Prosto.sln` builds the Framework applications with Mono MSBuild on macOS.
The Aspire AppHost is a native SDK project, excluded from the default solution
Build selection so Mono does not attempt to build .NET 10. It uses a separate
`dotnet build orchestration/ProstoERP.AppHost/ProstoERP.AppHost.csproj` build.
The **ERP Aspire (native)** Rider configuration prepares both toolchains before
launching through Rider's Aspire integration. The existing **ERP Aspire** shell
launcher remains available.
See the root README for setup, credentials, local database limitations, and
the **Local ERP** alternative.

## Where changes belong

- WebForms pages remain under `src/Portal/Modules` or `src/Portal/CustomerPortal`.
  Moving pages changes their URLs and must be treated as a functional change.
- API business endpoints and their supporting code live under
  `src/ProstoERP.Api/Features/<feature>`. Each feature contains its controller
  and the relevant `Models`, `Data`, `Services`, `Authentication`, or `Storage`
  files. Cross-feature authentication and mobile plumbing live under `Shared`.
  MVC Home/Swagger and the existing Values sample remain under `Controllers`.
- Portal supporting code lives under `src/Portal/Features/<feature>`, with
  `Data`, `Presentation`, `Storage`, `Models`, `Configuration`, `Exports`, or
  supporting `Web` classes grouped alongside each other as appropriate.
  Cross-feature configuration, utilities, encryption, upload handling, and the
  common page base live under `src/Portal/Shared`.
- Folder names organize source only. Existing CLR namespaces, VB root namespaces,
  public types, assembly names, and source contents are retained. WebForms pages
  stay under their original web-relative `Modules` and `CustomerPortal` paths.
- The AppHost's SQL availability check lives under
  `orchestration/ProstoERP.AppHost/HealthChecks`; orchestration stays in `AppHost.cs`.
- The attendance integration lives under
  `src/ProstoERP.Infrastructure/Features/Attendance`. Shared database mappings
  live under `src/ProstoERP.Infrastructure/Generated/LinqToSql` because they span
  multiple features. Keep handwritten additions separate from generated declarations;
  see [generated code ownership](GENERATED_CODE.md).
- Database changes remain in the matching `database/migrations/<feature>` directory.
  The local development manifest selects supported scripts explicitly; solution
  folder order does not define migration order.
- Local credentials, downloads, SQL data, and generated output stay out of Git.
  `packages`, `bin`, and `obj` are restored or generated directories.

## Cleanup scope

This cleanup adds navigation groups and editor defaults, removes the empty
`Class1` scaffold, and removes unused WPF/EntityDataSource assembly references.
It also separates existing request models, the Feedback SQL helper and exception,
and attendance authentication from controller files, and removes empty project
item groups. These are file organization changes; declaration bodies are retained
verbatim and controller behavior is unchanged.
The same separation is applied to the remaining API controllers and session
filters, Portal model/page-base declarations, and the AppHost health check.
Portal helper files are relocated with their bytes unchanged, except for files
where declarations are extracted verbatim into dedicated files. Project Compile
entries and documentation references track the new source paths.
It adds no tests and preserves business rules. Existing test files are retained.
HTML templates, experimental pages, and vendor assets remain in place until
their usage can be established.

## Step 2: controller services

The first extraction is `TrainingCatalogService` in
`src/ProstoERP.Application/Features/Learning`. `ERPController` delegates the existing
`GetVideosStatus`, `GetLevelsStatus`, and `GetLevelTypes` queries to this service.
The same stored procedures, projections, image URL prefix, success envelopes,
and materialization are used. The controller retains its route attributes,
authentication attributes, HTTP response handling, and existing error messages.
All other ERP actions remain in the controller for subsequent extractions.

The service currently uses the existing Infrastructure DataContext directly.
This is an incremental boundary around legacy queries, rather than a replacement
for the existing database contracts. Future service extractions should preserve
their contracts and follow the dependency direction Api → Application → Infrastructure.

## Step 3: presentation and storage helpers

Portal formatting and control-binding implementations live under each feature's
`Presentation` directory in `src/Portal/Features`. These include feedback cards, date formatting,
status labels and CSS classes, HTML encoding, display URLs, lookup binding, and
existing user-facing error messages. Feature-specific classes keep the original
format strings, labels, encoding calls, and logging behavior.

File processing lives under each feature's `Storage` directory:

- `EmployeeFeedbackAttachments`: queued employee-feedback attachments.
- `CorrespondenceAttachments`: queued/uploaded correspondence attachments and cleanup.
- `CircularsDocuments`: existing PDF input validation and reading.

The file limits, validation rules, image processing, filenames, storage locations,
and cleanup behavior are retained. Public limit constants on the old helpers
alias the storage constants so existing compiled callers see the same values.

Existing `*Data` and catalog method signatures remain as compatibility forwarders.
This keeps page markup, code-behind, and existing callers unchanged. New UI code
can use presentation helpers directly, and new file-handling code can use storage
helpers. The old helpers temporarily remain compatibility facades rather than
pure data-only APIs; removing those aliases is a separate migration.

SQL queries stay in the data helpers. Correspondence dropdown lookup uses a data
method containing the same query and parameters; placeholder/query/binding order
is retained. News control binding stays inside the original DataContext lifetime,
with prompt insertion afterward. Input validation, information-page HTML
sanitization, business status calculations, session checks, and authorization
remain in their existing implementations.

Validation for this step consists of source comparisons and a solution build.
No tests or test projects were added or run.

## Step 4: business feature organization

Related code is grouped within each project rather than moving business features
into separate assemblies. A typical feature looks like this:

```text
Features/
  Feedback/
    FeedbackController.cs       # API project
    Models/
    Data/
    Presentation/               # Portal project
    Storage/
    Web/                        # Portal supporting page classes
```

These directories exist where the project has corresponding code; they are not
empty scaffolding folders or additional projects.

| Feature | Main supporting code |
| --- | --- |
| Attendance | API endpoint, BioTime service, authentication, requests, Portal data/formatting, Infrastructure integration |
| Learning | Legacy ERP endpoint/requests and the Application training catalogue service |
| EmployeeAccess | Employee login/device endpoints, session helpers, user models, Active Directory helpers |
| PasswordReset | Existing partial UsersController implementation, requests, service, exception |
| Feedback | Employee feedback endpoint, models, database helper, presentation, attachments, supporting page base |
| CustomerFeedback | Public customer feedback endpoint and request model |
| CustomerPortal | Customer endpoint, session filter, requests, Portal data/presentation and page base |
| Correspondence | Endpoint, request models, data, formatting, attachments |
| Circulars | Endpoint, event model, Portal data/presentation, PDF processing, page base |
| News | Request model and Portal data/presentation |
| EmailNotifications | Endpoint, request model, email sender |
| CRM | Portal data, definitions/configuration, presentation, page base |
| WorkGuide | Portal data, presentation, exports |
| HRTypes / Contracts | Existing supporting Portal types |

The legacy MobileController still combines several employee-facing routes. It
lives under EmployeeAccess without splitting the class or changing its routes.
The password-reset partial class still shares the original UsersController type.
Feature folders establish navigation boundaries, not new runtime isolation.

Project Compile paths, setup/template paths, documentation links, and the few
existing verification-tool paths that read authentication source follow the new
locations. The local authentication implementation remains ignored by Git under
`src/ProstoERP.Api/Shared/Authentication/AuthenticationAttribute.cs`.

All 91 relocated source/template files were compared byte-for-byte with their
original contents. Existing web page locations, SQL scripts, business logic,
namespaces, and HTTP contracts are unchanged. No tests were added or run.

## Generated code isolation

The LINQ-to-SQL designer, DBML input, and layout are grouped under Infrastructure's
`Generated/LinqToSql` directory. Project references and tools that read the DBML
follow that location. Generated source contents and mapping contents are unchanged.

WebForms designer declarations stay beside their corresponding pages, and VB
application/resource/settings outputs stay in `My Project`, preserving their
generator relationships. Designer Compile entries explicitly identify generated,
design-time code. Editor defaults avoid reformatting generated declarations, and
Git attributes identify these files as generated. The skipped tests step adds
no test projects or tests.

Validation: all 491 captured source and generator-input files remain byte-identical,
accounting for the three relocated mapping files. All explicit Compile paths exist,
and the Framework solution builds successfully. The existing `ADUsers` assignment
warning remains. No tests were added or run.

## Shared build configuration

The Portal and API explicitly import `build/LegacyWeb.props` and
`build/LegacyWeb.targets`. Package-directory paths and the duplicate Roslyn setup
are maintained there, while each project retains its dependencies, framework,
source lists, output locations, and compiler options. Package versions and
configuration templates are unchanged. Aspire keeps its independent SDK setup.
See [build configuration ownership](BUILD_CONFIGURATION.md) for details.

## Web content organization

The main Portal and API project files retain source and dependency declarations.
Their existing Content lists are imported from `build/Portal.Content.props` and
`build/Api.Content.props`, respectively. Portal's large asset inventory is now
separate from the application Compile entries. The manifests also retain page,
view, and configuration entries with their existing metadata.

No application files are moved or edited. Public web-relative paths, explicit
file lists, existing wildcard patterns, and configuration transform relationships
remain unchanged. When adding a page, place its Content declaration in the
matching manifest and its code-behind/designer Compile declarations in the
main project file.

## Namespace compatibility

Directories organize code without redefining existing CLR namespaces. Keep
WebForms markup `Inherits` values, code-behind/designer partial classes, the two
UsersController partial implementations, and generated DataContext identities
consistent. A solution-wide namespace synchronization introduced reserved-word
VB namespaces and split partial classes; the affected source and view identities
were restored from the working baseline. Do not use folder synchronization to
rename these legacy types as part of organizational cleanup.
