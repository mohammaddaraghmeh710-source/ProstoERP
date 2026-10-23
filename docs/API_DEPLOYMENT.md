# API deployment preparation

The API remains ASP.NET Web API 2 on .NET Framework 4.8. Deploy it to Windows IIS;
the Mono/XSP and Aspire launchers are local development tools. The mobile clients
consume JSON contracts, not the .NET Framework assemblies.

Build and stage a reviewable Release artifact from the repository root:

```sh
python3 scripts/prepare_api_release.py
```

The script builds without running tests, copies explicit web content and runtime
assemblies, and creates a Web.config from the sanitized example. It excludes the
local application Web.config and root bin configuration files. It disables HTTP
mobile transport and compilation debugging in the staged configuration. It does
not publish, run migrations, start servers, or overwrite an existing artifact.
The manifest records file hashes and outstanding deployment prerequisites.

Configure the artifact's Web.config using the target server's secret management
process. Integration.BasicUsername and Integration.BasicPassword now hold the
same Basic credentials previously compiled into AuthenticationAttribute. Keep
Portal's PasswordReset.BasicUsername and PasswordReset.BasicPassword aligned with
the integration account. Source templates contain placeholders only.

```sh
python3 scripts/prepare_api_release.py --validate-config /path/to/staged/Web.config
```

This checks setting presence and configuration structure. It never prints secret
values and does not verify credentials, database compatibility, or server access.

Required configuration includes:

| Setting | Deployment value |
| --- | --- |
| Prosto_ERP_ConnectionConnection | Target SQL Server connection string |
| Integration.BasicUsername / Integration.BasicPassword | Integration credentials |
| PasswordReset.HashKey | Existing stable password-reset signing key |
| MobileApi.AllowHttp | false |
| MobileApi.IdleMinutes / MaximumMinutes | Existing session policy, default 480 / 43200 |
| MobileApi.AssetBaseUrl | Public HTTPS asset URL |
| MobileApi.FeedbackStoragePath | Persistent server attachment directory |
| MobileApi.CorrespondenceStoragePath | Persistent server correspondence directory |
| CustomerApi.PortalRoot | Portal directory used to resolve customer document paths |

Do not rotate existing signing/encryption keys during this cleanup. Supply access
to existing attachments and SQL data; the local inferred development schema is
not a replacement for the real production database. Apply reviewed migrations as
a separate deployment operation, with a backup and rollback plan for that environment.

Before an actual deployment, restore the original production-compatible Encryptor
implementation. The replacement currently in this repository is development-only
and cannot establish compatibility with existing encrypted employee passwords.
The legacy generated Infrastructure settings can also contain local default
connection strings; review/regenerate them for the target environment and rebuild
there. Staging locally is preparation, not a production-ready publishing operation.

On IIS, configure a .NET CLR v4 application pool with the correct bitness, HTTPS,
and directory permissions for its identity. Publish approved application files
while keeping uploaded files in their persistent directories. Verify Swagger,
integration authentication, employee/customer session boundaries, and file access
against the target environment before making the deployment available to clients.

No deployment is performed by this cleanup.
