# Mobile authentication

The Authentication Swagger module is `/swagger?module=authentication`, with JSON
at `/swagger/docs/authentication-v1`. All new endpoints use the existing mobile
`Success`, `Data` and `Error` envelopes and omit empty response properties.
Use HTTPS. Development HTTP is enabled only by the existing local configuration.
No shared integration/Basic secret is needed by these new mobile endpoints.

## Endpoints

All routes below start with `/api/v1/auth` and use POST.

| Route | Authentication | Request / result |
| --- | --- | --- |
| `/register` | ERP username/password | Login request with device metadata; sends email activation OTP |
| `/devices/replace` | ERP username/password | Same request; sends email OTP for replacement |
| `/verify-otp` | Single-use challenge + OTP | Purpose-specific verification; activation result or reset token |
| `/login` | ERP username/password + registered device | Employee profile and Bearer session |
| `/logout` | Bearer | Revokes sessions for the registered device and clears its push token |
| `/forgot-password` | Employee number | Generic email-recovery acknowledgement and challenge ID |
| `/reset-password` | Reset token from verified OTP | Changes password and invalidates sessions/biometric access |
| `/devices/current` | Bearer | Refreshes current device metadata and FCM token |
| `/biometric/enroll` | Bearer + password reauthentication | Registers RSA public key and returns credential GUID |
| `/biometric/challenge` | Credential GUID + device context | Returns a short-lived one-time challenge |
| `/biometric/login` | Device-key signature + device context | Verifies proof and issues Bearer session |

Registration activates an existing active ERP employee. It never creates an ERP
account or accepts a caller-selected recovery email, user ID, brand or role.
Codes go only to the employee email already stored in ERP, through its brand's
configured Gmail sender (or the local inbox configured below). OTP is required for activation, recovery and replacement;
ordinary password login does not request another OTP.

## Local email and Swagger

With the existing local SQL Server running, run from the repository root:

```sh
python3 scripts/setup_local_email.py
```

Use a **Debug** build and start the local API with `python3 scripts/run_local.py start`.
Open [Authentication Swagger](http://127.0.0.1:3001/swagger?module=authentication)
and [Mailpit](http://127.0.0.1:8025). Messages are captured in this local inbox;
no brand Gmail credentials are required. SMTP listens on loopback port 1025 and
the inbox on loopback port 8025. The script reuses a persistent Mailpit container
and volume. Run it again after restarting Docker if the inbox is stopped.

Private, ready-to-copy request bodies are generated in
`.local-development/local-email/swagger-requests.json`. This ignored file contains
the seeded local employee's password; do not commit or share it. The script adds
`localadmin@example.test` only when that seeded employee has no email, and preserves
existing passwords, nonempty email addresses and device registrations. If that
employee already has an approved device, examples reuse its DeviceID and platform.
Keep the same DeviceID in registration and login requests.

1. Send `register_or_login` to `/register`.
2. Copy its ChallengeID into `verify_registration_otp` and call `/verify-otp`.
3. Send the same `register_or_login` body to `/login`.
4. For recovery, send `forgot_password` to `/forgot-password`, then verify its
   ChallengeID with Purpose=`password-reset`. Use the returned ResetToken with
   NewPassword at `/reset-password`. Use that new password for subsequent login.

The setup enables the fixed OTP **12345** for fresh registration, device replacement
and recovery challenges. It works only in Debug binaries with local delivery enabled,
`LocalDevelopment.Enabled=true`, and the marked `Prosto_ERP_Development` database
on loopback. It still requires the correct challenge, purpose, matching stored code,
expiry and unused status. It does not bypass challenge validation. A challenge
created before switching OTP mode retains its original code.

For random six-digit codes delivered to the same inbox, rerun with
`python3 scripts/setup_local_email.py --random-otp`. After changing OTP mode,
restart running local servers with `python3 scripts/run_local.py stop` followed
by `python3 scripts/run_local.py start`. Both `LocalOtp.Enabled` and
`LocalOtp.FixedCode` default to false in the configuration template. Release builds
reject local delivery and five-digit OTPs, and release preparation rejects either
flag being enabled. No external email delivery is configured by this script.

## Login and device metadata

`/register`, `/devices/replace` and `/login` use:

```json
{
  "Username": "employee-username",
  "Password": "employee-password",
  "AppVersion": "1.0.0",
  "AppBuild": "1",
  "Device": {
    "DeviceID": "persistent-app-installation-guid",
    "Platform": "Android",
    "Manufacturer": "manufacturer",
    "Model": "device-model",
    "OSVersion": "os-version",
    "MACID": null,
    "FCMToken": "current-firebase-registration-token"
  }
}
```

Platform is Android or iOS. DeviceID, platform, model, OS version, AppVersion and
FCMToken are required. AppBuild, manufacturer and MACID are optional. MAC privacy
placeholders are normalized to null. FCMToken supports up to 4000 characters;
whitespace and empty tokens are rejected. FCM is push-routing metadata, never an
authentication credential. Refresh it with `/devices/current` after token changes.
The backend stores tokens; it does not introduce a Firebase push sender here.

The registration response contains ChallengeID, Purpose, expiry and resend delay.
Verify using:

```json
{
  "ChallengeID": "server-issued-guid",
  "Purpose": "registration",
  "OTP": "123456"
}
```

Purpose is exactly `registration`, `device-replacement`, or `password-reset`.
Activation verification returns DeviceRegistered and LoginRequired; the client
then signs in with its password and the same DeviceID/platform. Activation does
not return a session or store the password in a challenge.

## One registered device

A filtered unique index allows one approved device per employee. Activation and
replacement lock the employee row and run in a transaction. A different approved
device causes DEVICE_ALREADY_REGISTERED; it cannot be silently enrolled by login.
Replacement OTP is bound to the proposed device metadata, employee, email, brand,
password fingerprint and reset epoch. Successful verification revokes existing
sessions and biometric keys, clears previous push tokens, then approves one device.
Requesting replacement alone leaves the current device active. Verify the returned
ChallengeID with Purpose=`device-replacement`; Purpose=`registration` is rejected.
After verification, log in using the new DeviceID and enroll a new biometric key.
The previous device cannot continue using its old sessions or biometric credential.

DeviceID is an installation identifier. It and OS/MAC metadata are client supplied;
this policy is not hardware attestation and cannot prove physical device identity
against a cloned/compromised client. Biometric login additionally proves possession
of the registered private key. DeviceID must stay stable in private app storage;
an uninstall/reinstall or lost device may require email-verified replacement.

Logout leaves device enrollment and its biometric key available, while revoking
that device's existing sessions and clearing its FCM token. A subsequent biometric
login still requires a fresh signature. Password reset, replacement, key rotation,
credential expiry and administrative revocation invalidate biometric access.

## Password recovery

Call `/forgot-password` with `{"EmployeeNumber":123}`. The response is deliberately
generic and does not expose employee existence or a masked email. For eligible
accounts, verify the emailed code with Purpose=password-reset, then send
`{"ResetToken":"...","NewPassword":"..."}` to `/reset-password`. Password length
is 8–128, with whitespace-only passwords rejected. Reset permission is single-use
and expires after 10 minutes. Existing employee password/encryption compatibility
is retained; see [deployment prerequisites](API_DEPLOYMENT.md).

Account lookup and SMTP delivery run in host-managed background work after the
generic acknowledgement, avoiding account-dependent SMTP delays in the response.
Account/contact and SMTP failures produce the same recovery acknowledgement.
IIS uses host-managed background work. Mono/XSP with local HTTP enabled uses a
development-only background task because XSP lacks that IIS hosting facility.
The background queue is in-process, not a durable mail outbox: a host shutdown may
lose pending delivery, in which case the user must retry. A durable outbox should
replace this dispatcher when delivery guarantees are required.
Operational logs record failure types without codes or credentials. A generic
acknowledgement does not guarantee delivery; administrators must configure and
monitor brand SMTP. Database/rate-limit failures remain actionable errors.

## Biometric login

Biometric samples never go to the server. The client creates an RSA 2048-, 3072-
or 4096-bit key in Android Keystore or the iOS equivalent, with private-key use
gated by strong biometric authentication and invalidation after biometric changes.
Do not export, back up or send the private key. The server cannot verify those
client-side key policies without a separate attestation protocol.

After password login, enroll with the Bearer session, current Password, and JWK
public fields Modulus and Exponent. These are canonical unpadded base64url, with
an unsigned big-endian modulus (no leading sign byte) and Exponent=`AQAB`.
The response CredentialID is a GUID identifying the public-key credential; knowing
it does not grant access. Keys expire after 90 days and can be re-enrolled after
password reauthentication. Enrolling a new key replaces the previous one.

1. Request `/biometric/challenge` with CredentialID, AppVersion, optional AppBuild,
   and the complete Device object including FCMToken.
2. The server returns ChallengeID, Challenge, Algorithm=RS256 and a 120-second TTL.
3. Require a biometric-protected signing operation on the client. Sign the **exact
   UTF-8 bytes of Challenge**, including its newlines, using SHA-256 with RSA
   PKCS#1 v1.5. Do not use RSA-PSS or sign a reserialized JSON object.
4. Call `/biometric/login` with CredentialID, ChallengeID, unpadded base64url
   Signature, and exactly the same app/device metadata as the challenge request.

The challenge binds the credential, challenge ID and normalized app/device metadata
(including FCMToken). A new challenge replaces an older pending challenge. Valid
challenge consumption is atomic and occurs before signature verification; a bad
signature also consumes it. Always request a new challenge after a failed proof.
The database rechecks account, device, password, reset epoch, administrative epoch
and key expiry before issuing a session. A GUID or local `biometricSucceeded=true`
flag alone is never accepted.

## Abuse controls

OTP uses cryptographic randomness, purpose-bound HMAC hashes, ten-minute expiry,
five guesses and single-use consumption. Activation resend delay is 60 seconds.
Database rate limits serialize account/source checks: five activation attempts
per account in 15 minutes, ten attempts for other scopes per account in 15 minutes,
and 60 total authentication attempts per source address in 15 minutes. The existing
password-reset-specific limits also apply. Limits count successful attempts too.
The API uses the server-observed client address and does not trust arbitrary
X-Forwarded-For headers; configure trusted proxy handling before deployment behind
an ingress. Responses contain no credentials or OTPs in errors/logs/query strings.

## Database and compatibility

Apply `database/migrations/Mobile_API/009_Authentication.sql` after Mobile_API/008,
Password_Reset/001 and Email_Notification/001. It is included in fresh development
setup. Back up the target database first. It refuses to choose between multiple
approved devices; resolve those explicitly before applying it. Schema/procedure
changes run in one transaction. Existing pre-migration devices need OTP activation
before their old sessions or password login can authenticate.

`/api/Users/Login` remains as a compatibility route, now requiring FCMToken and
OTP activation and using the same rate limiter. Static `/api/Users/LoginViaBIO`
is retired, including its SQL implementation. `/api/Users/AddNewDevices` and
`/api/v1/devices/status` return 410 and direct clients to OTP registration. Legacy
BIOID secrets are no longer issued. Do not reapply Mobile_API/006 or /008 after /009;
that would restore older procedure definitions. Portal's additional-device approval
option cannot override the single-device unique index; administrative approval
alone does not establish a new device's OTP verification.

Local registration and recovery email delivery are verified through Mailpit.
Manual local checks also covered activation, OTP replay rejection, password login,
device restrictions, logout, password recovery verification, password reset,
reset-token replay rejection and session invalidation. The seeded employee's
original password was restored through the recovery API and login verified again.
Additional local checks used an OpenSSL-generated 2048-bit RSA key for biometric
enrollment and signed login, including incorrect password, missing signature,
signature tampering, challenge replay, wrong-device rejection and login after logout.
OTP replacement preserved the old device until verification, then revoked its
sessions and biometric credential. Exactly one OTP-verified device remained approved
through replacement and restoration of the original development device.
Production email delivery still requires configured employee email/brand SMTP;
biometric login requires client key integration. No application test files or
production deployment are introduced.

## Platform references

- [Android device identifiers and MAC restrictions](https://developer.android.com/identity/user-data-ids)
- [Android biometric-protected cryptographic operations](https://developer.android.com/identity/sign-in/biometric-auth)
- [OWASP key access restrictions](https://mas.owasp.org/MASWE/MASVS-CRYPTO/MASWE-0016/)
