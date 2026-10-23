# Main integration and architecture ownership

The architecture work was saved in `66733b0` before merging `origin/main` at
`78ab8a8` into `api-implement`. The merge carries incoming functionality into the
existing architecture rather than restoring the old project folders.

| Incoming source | Current owner |
| --- | --- |
| Portal pages, markup and assets | `src/Portal`, retaining web URLs |
| AppCode and PageBase helpers | Portal `Features/<feature>` and `Shared` |
| Mobile HTTP routes and authorization | `src/ProstoERP.Api/Features` |
| Mobile workflows and validation | `src/ProstoERP.Application/Features` |
| Shared mobile DTOs | `src/ProstoERP.Contracts/Features` |
| Circular notification worker, SMTP and SQL adapters | `src/ProstoERP.Infrastructure.Mobile` |
| Generated database model | `src/ProstoERP.Infrastructure/Generated/LinqToSql` |
| Feature SQL and existing operational tools | `database/migrations/<feature>` |

The incoming feedback-transfer rule, customer login failure audit, circular mail
queue worker and customer work-guide API removal are preserved. The eight guide
actions removed upstream are also removed from the service and request contracts.
The mobile Swagger document now has 43 operations across 39 paths; the complete
document has 66 operations across 59 paths. Empty-value JSON handling remains in place.

Both solution build paths (Mono MSBuild and .NET MSBuild) and the native AppHost
build pass. Local mobile/all Swagger pages and the Portal login return HTTP 200.
The existing ActiveDirectorySearcher and Aspire CLI-bundle warnings remain.
No tests were authored or executed; existing upstream verification tools were
retained as part of main's changes. Their feature scenarios were not validated.
No database migrations, email sends, data writes, deployment or push were performed.
New main-branch features require their corresponding reviewed database migrations
and environment configuration before use; compilation and anonymous startup do
not establish compatibility with the limited local development database.
The circular worker remains opt-in through `CircularNotifications.Enabled`, with
`CircularNotifications.PortalBaseUrl` required for mail links.

For future merges, commit local work, fetch main, and merge main into the working
branch. Resolve each incoming change at its current owner, update explicit
project/content entries for added or removed files, and preserve the existing
package upgrades, local config exclusions, public routes and namespace identities.
Verify the solution and AppHost builds before committing the merge. Do not accept
an entire side of a conflict when it would discard upstream behavior or undo the
layer boundaries.
