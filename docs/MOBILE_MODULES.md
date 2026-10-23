# Mobile API modules

The mobile backend runs as one Web API 2/.NET Framework host, with feature-owned
controllers, application workflows, contracts and persistence adapters. It uses
the existing database. Modules do not introduce separate servers or deployments.

## Swagger views

Open `/swagger` and use the API module selector, or use a direct link:

| Module | UI query | JSON document |
| --- | --- | --- |
| Authentication | `/swagger?module=authentication` | `/swagger/docs/authentication-v1` |
| Employee access and devices | `/swagger?module=employee-access` | `/swagger/docs/employee-access-v1` |
| Employee content | `/swagger?module=employee-content` | `/swagger/docs/employee-content-v1` |
| Password reset | `/swagger?module=password-reset` | `/swagger/docs/password-reset-v1` |
| Employee feedback | `/swagger?module=feedback` | `/swagger/docs/feedback-v1` |
| Circulars | `/swagger?module=circulars` | `/swagger/docs/circulars-v1` |
| Correspondence | `/swagger?module=correspondence` | `/swagger/docs/correspondence-v1` |
| Customer portal | `/swagger?module=customer-portal` | `/swagger/docs/customer-portal-v1` |
| Customer feedback | `/swagger?module=customer-feedback` | `/swagger/docs/customer-feedback-v1` |
| Learning | `/swagger?module=learning` | `/swagger/docs/learning-v1` |

`/swagger?module=mobile` and `/swagger/docs/mobile-v1` combine these modules.
`/swagger?module=all` and `/swagger/docs/v1` retain the complete API. An unknown
UI module falls back to the mobile aggregate. `Documentation/SwaggerModules.cs`
is the single catalog used by the selector and the document generator.

Feature assignment uses controller types and actions, not CLR namespace changes.
The two UsersController partials retain their identity; password-reset actions
get a separate document. Device status/logout are Employee Access; news and
information pages are Employee Content. The legacy ERPController learning actions
now appear in Learning and the mobile aggregate; its two news actions appear in
Employee Content. Authentication schemes, parameters, operation IDs, response
shapes, schemas and route URLs remain unchanged. Non-mobile integration endpoints
remain available in All APIs. Swagger grouping does not create an authorization
boundary or disable an endpoint.

The Authentication module adds the OTP/device/biometric flows described in
[Mobile authentication](MOBILE_AUTHENTICATION.md). Its policy changes supersede
the older device/BIOID endpoints; see that document before updating clients.

## Persistence ownership

Feedback, Correspondence, Customer Feedback and Customer Portal each own an
`I<Feature>StoreFactory` and `I<Feature>Store` under Application/Features.
Services receive only their own factory. Its `Open()` creates a store that owns
one SQL connection and its existing transaction lifecycle. The store exposes
named operations for that feature, with no general-purpose SQL execution method.

Infrastructure.Mobile implements each factory/store under the matching feature.
Its internal `MobileDataSession` and `MobileStatement` catalog retain SQL execution
and the same 71 statement definitions. `MobileTransactionalStore` forwards Begin,
Commit, rollback confirmation and disposal without changing connection ownership,
query timing, timeouts, SQL parameters or upload/idempotency behavior. Application
shares only `IMobileTransaction` for lifecycle operations.

These legacy adapters deliberately retain DataSet result sets and named parameter
arrays. A fully typed persistence model requires a separate review against the
actual database contracts. Employee Access, content, Circulars and the extracted
Learning catalog already have dedicated store interfaces. The remaining legacy
Learning actions retain their current implementation and are only grouped here.

## Adding a feature

1. Put request/response models in `Contracts/Features/<feature>`.
2. Put the workflow and its persistence interface in `Application/Features/<feature>`.
3. Implement the interface in `Infrastructure.Mobile/Features/<feature>`, keeping SQL there.
4. Add a thin HTTP controller under `Api/Features/<feature>`; wire dependencies in Composition.
5. Register its document and controller/action ownership in SwaggerModules.

Use explicit interfaces for cross-module operations. Do not inject another
module's store, expose SQL execution to workflows, or access another module's
tables directly from a new API controller. Reuse existing HTTP authentication,
response/error handling, validation and empty-value JSON serialization.

The original module separation introduced no application tests, migrations or
framework changes. The later Authentication module adds its own explicit SQL migration. Build and local read-only documentation checks validate the
structure; database write, upload and SMTP scenarios were not exercised.
