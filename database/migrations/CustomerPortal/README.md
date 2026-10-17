# Customer portal deployment

Requires the existing CRM, work-guide access/roles, and employee feedback migrations through
`Employee_Feedback/009_CustomerSupport.sql`. Apply `001_Accounts.sql`, `002_Services.sql`, `003_Portal.sql`,
`005_WorkGuideIntegration.sql`, then `004_MobileApi.sql` in one transaction. `Apply.ps1` performs this against the local
Portal configuration and saves the previous shared feedback and guide review/list procedures and retired account
statuses under workspace `tmp/`.

Deploy the Portal assembly together with `Login.aspx`, `Customer.Master`, `CustomerPortal/*.aspx`, CRM customer
list/access pages, the existing `WorkGuide_User_Category_Roles` and request-management pages, and the changed employee
pages. The project file includes the new code and markup. Do not deploy test scripts, staging authentication helpers, or
synthetic data. Reapply CustomerPortal services after any older feedback migration that replaces
`Insert_Customer_Feedback_Request`; its optional output/result parameters preserve the existing public API call
contract.

System administrators open **Customers → Customer account** to create one login for a CRM account, reset its password,
or disable access. Grant categories from multiple brands through the existing work-guide permission administration, now
linked to CRM customers. Credentials are separate from employee credentials; existing external employees are disabled,
not converted. Existing employee grants, requests, and activity remain as historical records. Customer grants must be
created explicitly. CRM account deactivation/deletion blocks customer access immediately; credential changes invalidate
current customer sessions.

Customer access is exposed through the web portal and `/api/v1/customer`; see `MOBILE-API.md` and its Postman
collection. Configure the API portal root and shared feedback storage as documented. Guide grants reuse existing roles,
nearest-category inheritance, optional dates, active ancestors, and document download restrictions. Customers can
request unavailable categories; the existing administrator request review supports approval/rejection and role
selection. Customer activity is available in the account administration page, with explicit complaint/suggestion
submission labels. Customer complaints/suggestions use the shared feedback workflow and notify active system
administrators; request ownership is linked to CRM without assigning an employee ID. Customers can open their own
original request details and initial attachments; internal workflow notes are not exposed. Existing unauthenticated
public customer API intake remains independent.

Run `Test-CustomerPortal.ps1 -ApiBuildDirectory <API build directory>` against local SQL Server to include real HTTP
route integration checks. It creates an isolated schema with synthetic fixtures, checks migration/auth/grants/feedback
integration, and removes the database. `-KeepDatabase` retains a successful test database and writes an isolated staging
configuration for browser verification. Build Portal and compile changed ASPX pages before deployment. Browser checks
should cover employee/customer selection, multi-brand listing, PDF view/download restrictions, feedback submission,
admin grant edits and responsive layouts. Unknown SQL outcomes retain newly uploaded files to avoid deleting attachments
from a possibly committed request; reconcile unreferenced files operationally when investigating failed submissions.
