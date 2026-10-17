# Build configuration ownership

The classic Portal and API projects share package-location and Roslyn setup in
`build/LegacyWeb.props` and `build/LegacyWeb.targets`.

| File | Responsibility |
| --- | --- |
| `build/LegacyWeb.props` | Repository-local `packages` location and existing CodeDom package directory |
| `build/LegacyWeb.targets` | Existing Roslyn tool path, configuration-registration setting, and package targets import |
| `build/Portal.Content.props` | Portal's existing Content declarations and metadata |
| `build/Api.Content.props` | API's existing Content declarations and metadata |
| Each web project | Assembly references, package versions, source lists, framework, output paths, and Debug/Release compiler options |
| Each `packages.config` | Existing NuGet dependency declarations |
| Aspire AppHost project | Its separate .NET SDK, framework, and package references |

The shared files are imported explicitly. They are not automatic
`Directory.Build.props` or `Directory.Build.targets` imports, so their legacy
web settings do not flow into libraries or the .NET 10 AppHost.

Package HintPaths now use `$(ProstoPackagesRoot)` rather than repeating a relative
path in each reference. The root is based on the shared file's location rather
than the shell's working directory. The CodeDom package remains version 4.1.0;
its reference, tool directory, and build import share `$(ProstoCodeDomPackage)`.
When deliberately upgrading it in the future, also update the web projects'
`packages.config` declarations and review their local configuration templates.

Roslyn configuration registration remains disabled, preserving ownership of the
existing local Web.config files. The API retains its existing missing-package
check. Other references keep their existing package versions and target-framework
assets; this cleanup does not migrate package formats or upgrade dependencies.

Build the Framework solution with Mono MSBuild on macOS or classic MSBuild with
the ASP.NET build tools on Windows:

```sh
msbuild ERP_Prosto.sln /t:Build /p:Configuration=Debug /verbosity:minimal /nologo
```

Build the standalone orchestration project with its own SDK:

```sh
dotnet build orchestration/ProstoERP.AppHost/ProstoERP.AppHost.csproj
```

These build commands do not invoke the repository's verification tools or tests.

## Web content manifests

The Portal and API import their respective Content manifests from `build/`.
These hold the existing page, view, configuration, font, script, stylesheet,
image, and vendor-asset declarations. They are separate from Compile items so
the main project files emphasize source, dependencies, and build settings.

Portal's 2,885 Content declarations live in `Portal.Content.props`, reducing its
main project file from 4,680 to 1,789 lines. The API's 63 declarations live in
`Api.Content.props`, reducing its main project from 397 to 325 lines.

Includes remain relative to the importing web project, not the `build` directory.
No web files move. Existing file lists, wildcard patterns, order, and metadata
are retained; no recursive catch-all glob replaces the explicit lists. Keep
adding Content declarations to the appropriate manifest and Compile declarations
to the main project. Existing configuration transforms retain their nesting.
Local configurations remain ignored, with their existing sanitized templates.
The manifests themselves are build inputs, not additional published content.

After extraction, ordered MSBuild item snapshots match exactly in Debug and
Release for both web projects, including evaluated Content paths and metadata,
Compile items, resources, references, and project references. All 3,659 captured
non-project files remain byte-identical. The full Debug solution build passes
with the existing `ADUsers` warning. No tests were added or run.

## Cleanup validation

Before/after MSBuild snapshots match for Portal and API in both Debug and Release:
resolved references, source lists, resource identities, compiler properties, and
the normalized Roslyn tool path. All 3,659 captured non-project files remain
byte-identical, including application code, configuration, dependency manifests,
database scripts, and existing verification tools.

The full Framework solution builds successfully in Debug. The existing
`ActiveDirectorySearcher.vb` warning about `ADUsers` remains. No tests were added
or run.
