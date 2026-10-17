# ProstoERP

ASP.NET ERP solution. Open `ERP_Prosto.sln` in Visual Studio and restore NuGet packages before building.

The solution groups applications, libraries, database scripts, development tools,
and documentation into navigation folders. See [Project structure](docs/PROJECT_STRUCTURE.md)
for responsibilities and build-tool details. Application projects live under
`src/`, Aspire under `orchestration/`, and database scripts under `database/`.
Page URLs and legacy assembly names remain unchanged.

For mobile backend development, see [Mobile backend foundation](docs/MOBILE_BACKEND.md)
for the shared contracts, response handler, empty-value JSON policy, contract
export command, and preparation for later deployment.

## Fresh local development on macOS

The solution includes a source-built development replacement for the unavailable
`Encryptor.dll`. It retains the existing API (`Echo.Encrptor.TripleDesEncryptor`)
using a versioned AES/HMAC format. It **cannot read original production passwords**.
It requires `LocalDevelopment.Enabled=true` and a generated local key. Use the
original DLL and database for a production-compatible deployment.

This Mac has Mono/MSBuild and project-local official Colima/Lima/Docker binaries.
On another Mac, install Mono and the container tools first. The tool binaries,
credentials, SQL volume and generated output are not committed.

From the repository directory:

```sh
export PATH="$PWD/.local-development/tools/bin:$PATH"
colima start prosto-erp --vm-type vz --cpu 2 --memory 4 --disk 30 --runtime docker
python3 scripts/setup_development.py --build --database
python3 scripts/run_local.py start
python3 scripts/verify_development.py
```

The SQL Server 2022 Developer container listens only on `127.0.0.1:14333` and uses
its own `prosto-erp-dev-sql-data` volume. Database initialization targets only
`Prosto_ERP_Development`; it refuses an unmarked existing database or a changed
local encryption key. It seeds a `localadmin` account and a development brand.
It preserves configuration and credentials on repeated runs.

Open Portal at <http://127.0.0.1:52219/login.aspx> and API at
<http://127.0.0.1:3001/>. Find the generated login and database passwords in
`.local-development/credentials.txt`. Preserve `.local-development/settings.json`
with the database volume: its encryption key is needed to read local passwords.
Do not commit or deploy these local credentials.

In Rider, select **Local ERP** in the run configuration dropdown and click Run.
It builds the solution, starts both local web servers, and opens the Portal login
page in the default browser when it is ready. SQL Server must already be running.
The web servers continue running after the launcher exits; stop them with the
command below. From a terminal, use `python3 scripts/run_local.py start --open-browser`.

Swagger UI is available at <http://127.0.0.1:3001/swagger>, with the generated
Swagger 2.0 document at `/swagger/docs/v1`. The API navigation includes a Swagger
link. Swagger uses Swashbuckle.Core 5.6.0 for Web API 2 and locally hosted Swagger
UI 5.33.3 (upstream license and notice are included beside its assets).
For employee/customer session endpoints, click **Authorize** and enter
`Bearer <access token>` under `bearer` after logging in. For integration or
attendance endpoints, use the corresponding credentials under `basic`.
Credentials are not prefilled or persisted across page reloads. **Try it out**
calls the actual API and can change data; the existing endpoint authentication
and permissions apply.

### Aspire orchestration on this Mac

Select **ERP Aspire (native)** in Rider and click Run. AppHost is a real project
under `orchestration`, with `IsAspireHost=true` for native Aspire discovery.
Its preparation task builds the Framework solution with Mono and AppHost with
.NET 10, then stops web servers owned by `run_local.py`. Rider launches AppHost
through its Aspire integration. The existing **ERP Aspire** shell configuration
and `bash scripts/run_aspire.sh` remain available as alternatives.
The dashboard base address is <http://127.0.0.1:15888>; use the generated login
link in the Run output when prompted. Keep that link private.

The dashboard shows `erp-database`, `api`, and `portal`, their health checks,
web-service console logs, and links to Swagger and Portal login. The database
check tests TCP availability on port 14333; it does not validate the schema or
SQL credentials. API startup waits for that check, and Portal waits for the API.
Portal remains on 52219 and API on 3001, so existing local URLs still work.

Start the existing Colima VM and SQL container before running Aspire:

```sh
export PATH="$PWD/.local-development/tools/bin:$PATH"
colima start prosto-erp --vm-type vz --cpu 2 --memory 4 --disk 30 --runtime docker
export DOCKER_HOST="unix://$HOME/.colima/prosto-erp/docker.sock"
docker start prosto-erp-dev-sql
bash scripts/run_aspire.sh
```

Click Stop in Rider or press Ctrl+C in the terminal to shut down Aspire and its
web servers. The existing SQL container stays running for DBeaver. Do not run **Local ERP** and **ERP Aspire**
simultaneously. Use `--no-browser` with the shell
launcher when you do not want a browser window.

The AppHost reads the existing local API `Web.config`; it does not replace the
database, change credentials, or require changes to the Framework applications.
AppHost appears as a native project under **orchestration**. It is excluded from
the solution's default Build selection so the existing `msbuild ERP_Prosto.sln`
command continues to build the Framework applications with Mono. Build AppHost
with `dotnet build orchestration/ProstoERP.AppHost/ProstoERP.AppHost.csproj`.
For native Aspire launching, Rider must use .NET 10 MSBuild under **Settings →
Build, Execution, Deployment → Toolset and Build**. The local solution setting
selects the installed SDK on this Mac. `build/MonoFramework.props` supplies Mono's
Framework reference assemblies and classic web targets when modern MSBuild loads
the Framework projects on macOS. It does not affect Windows or Mono MSBuild.
Aspire 13.6.0
uses the NuGet-provided orchestrator/dashboard binaries here; CLI-bundle-only
features are unavailable (build warning ASPIRE010). MessagePack is pinned to
the compatible 2.5.303 security patch. The dashboard uses token authentication
over loopback HTTP; these settings are for local development. Distributed
traces and metrics require additional application instrumentation.

```sh
python3 scripts/run_local.py status
python3 scripts/run_local.py stop
colima stop prosto-erp
```

Rebuild before starting the servers after source changes. Mono/XSP may exit when
`Web.config` or `bin` changes; run the start command again. The local hosting
bridge uses the existing Roslyn compiler for Web Forms VB markup on macOS.

### Database coverage and limits

The repository has 342 mapped routine signatures but no original core database
DDL or stored-procedure bodies. `database/development/001_Core.sql` is a **new, limited development baseline**,
generated from those contracts. It provides
10 core tables and 69 CRUD procedures for users/types, brands, branches,
departments, job titles, shifts, genders, nationalities and news. The exact list is
in `database/development/supported-procedures.txt`; regenerate it with
`python3 scripts/generate_development_schema.py`.

`database/development/migrations.json` lists the existing module migrations
applied on top. This is not a reconstruction of all production business rules.
Modules depending on absent legacy tables/procedures (including work guides,
legacy statistics/evaluations and correspondence) still need the original schema.
Unsupported business procedures are not replaced with successful empty stubs.
Windows-only DPAPI/Active Directory/Office integration and Mono's async Web Forms
limitations also remain; use Windows/IIS for those features.

### Windows build

Install Visual Studio's ASP.NET and web development workload and .NET Framework
4.8 and 4.7.2 targeting packs. Restore the local templates and NuGet packages,
configure a suitable development database and encryption key, then build from a
Developer Command Prompt:

```text
py -3 scripts/setup_local.py
nuget restore ERP_Prosto.sln
msbuild ERP_Prosto.sln /p:Configuration=Debug
```

The .NET 10 SDK's `dotnet build` does not supply the classic ASP.NET web targets.
CKEditor.NET, Roslyn and Newtonsoft.Json are pinned in `src/Portal/packages.config`.

### Package security updates

Rider's reported package vulnerabilities were addressed by updating Newtonsoft.Json
to 13.0.4, jQuery to 3.7.1, Bootstrap to 5.3.8 and
Microsoft.CodeDom.Providers.DotNetCompilerPlatform to 4.1.0. Assembly hint paths,
binding redirects and compiler build imports use the updated versions. The API
home-page navigation uses Bootstrap 5 markup and serves the supplied minified
assets directly, avoiding the legacy bundle minifier's modern CSS/JS limitations.

The solution build, encryption checks, Portal administrator login, API bearer
sessions/logout and database CRUD verification pass with these versions. Rider
reported no package security findings after the updates.

## Local configuration

Copy these example files before building or running, then supply your local configuration:

- `src/Portal/Web.config.example` to `src/Portal/Web.config`
- `src/ProstoERP.Api/Web.config.example` to `src/ProstoERP.Api/Web.config`
- `src/ProstoERP.Infrastructure/app.config.example` to `src/ProstoERP.Infrastructure/app.config`

Set database connections, integration credentials, PasswordReset.HashKey, URLs, and storage paths for your environment.
Local configurations, build outputs, downloaded packages, and the BioTime integration test containing local database
credentials are excluded from Git.

Database scripts and test tools are in `database/migrations/`. Review each module's README before running them against a
database.

## Additional local templates

Some source, test, and documentation files also contained local credentials. Their originals remain on the original
workstation and are ignored; sanitized `.example` versions are published instead. On a fresh clone, copy each
`*.example` file to the same path with the `.example` suffix removed and replace the placeholders with your environment
values before building. This includes `AuthenticationAttribute.cs` and `My Project/Settings.Designer.vb`. Do not commit
the restored local files.

Runtime attachments under src/Portal/App_Data and src/Portal/FileManager, and the local employee allocation CSV, are
excluded. Recreate storage folders with the permissions required by your deployment.
