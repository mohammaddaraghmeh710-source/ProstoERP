# ProstoERP

ASP.NET ERP solution. Open `ERP_Prosto.sln` in Visual Studio and restore NuGet packages before building.

## Local configuration

Copy these example files before building or running, then supply your local configuration:

- `Portal/Web.config.example` to `Portal/Web.config`
- `Prosto_ERP_API/Web.config.example` to `Prosto_ERP_API/Web.config`
- `Prosto_ERP_ClassLibrary/app.config.example` to `Prosto_ERP_ClassLibrary/app.config`

Set database connections, integration credentials, PasswordReset.HashKey, URLs, and storage paths for your environment. Local configurations, build outputs, downloaded packages, and the BioTime integration test containing local database credentials are excluded from Git.

Database scripts and test tools are in `Database/`. Review each module's README before running them against a database.

## Additional local templates

Some source, test, and documentation files also contained local credentials. Their originals remain on the original workstation and are ignored; sanitized `.example` versions are published instead. On a fresh clone, copy each `*.example` file to the same path with the `.example` suffix removed and replace the placeholders with your environment values before building. This includes `AuthenticationAttribute.cs` and `My Project/Settings.Designer.vb`. Do not commit the restored local files.

Runtime attachments under Portal/App_Data and Portal/FileManager, and the local employee allocation CSV, are excluded. Recreate storage folders with the permissions required by your deployment.
