#!/usr/bin/env python3
"""Start loopback-only Mailpit and configure OTP delivery for the existing local ERP database. No tests."""
import argparse
import json
import subprocess
import sys
import uuid
from pathlib import Path
import xml.etree.ElementTree as ET
import setup_development as dev

ROOT = dev.ROOT
LOCAL = dev.LOCAL / "local-email"
NAME = "prosto-erp-dev-mail"
IMAGE = "axllent/mailpit:v1.27.4"
LABEL = "com.prosto.local-email"


def docker(*args, check=True):
    result = subprocess.run(["docker", *args], capture_output=True, text=True)
    if check and result.returncode:
        raise RuntimeError(result.stderr.strip() or "Docker command failed")
    return result


def literal(value):
    return "N'" + str(value).replace("'", "''") + "'"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--random-otp", action="store_true", help="Use random six-digit OTPs instead of the Debug-only 12345")
    args = parser.parse_args()
    LOCAL.mkdir(parents=True, exist_ok=True, mode=0o700)
    values = json.loads((dev.LOCAL / "settings.json").read_text())
    api = ROOT / "src/ProstoERP.Api/Web.config"
    tree = ET.parse(api)
    entry = tree.find("connectionStrings/add[@name='Prosto_ERP_ConnectionConnection']")
    connection = {} if entry is None else dict(part.split("=", 1) for part in entry.get("connectionString", "").split(";") if "=" in part)
    connection = {key.strip().lower(): value.strip() for key, value in connection.items()}
    host = connection.get("server", connection.get("data source", "")).split(",")[0].lower()
    database = connection.get("database", connection.get("initial catalog", ""))
    enabled = tree.find("appSettings/add[@key='LocalDevelopment.Enabled']")
    if host not in ("127.0.0.1", "localhost", ".", "(local)") or database != dev.DATABASE or enabled is None or enabled.get("value", "").lower() != "true":
        raise RuntimeError("Refusing to enable local OTP on a non-development API configuration.")
    # Never initialize or reset a database, credentials, device registrations or sessions here.
    guard = "IF DB_NAME()<>N'Prosto_ERP_Development' OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ProstoLocalDevelopment' AND CONVERT(nvarchar(10),value)=N'1') THROW 51000,'Not a marked local development database.',1;"
    result = dev.sql(guard, dev.DATABASE, quiet=True)
    if result.returncode:
        raise RuntimeError("Start the existing local SQL Server before configuring local email.")
    docker("info")
    existing = docker("inspect", NAME, check=False)
    if existing.returncode == 0:
        container = json.loads(existing.stdout)[0]
        if container.get("Config", {}).get("Labels", {}).get(LABEL) != "true":
            raise RuntimeError("Refusing to modify an unmanaged container named " + NAME)
        if not container.get("State", {}).get("Running"):
            docker("start", NAME)
    else:
        print("Starting local Mailpit inbox...", flush=True)
        docker("run", "-d", "--name", NAME, "--label", LABEL + "=true", "--restart", "unless-stopped",
               "-p", "127.0.0.1:8025:8025", "-p", "127.0.0.1:1025:1025",
               "-v", "prosto-erp-dev-mail:/data", "-e", "MP_DATABASE=/data/mailpit.db",
               "-e", "MP_MAX_MESSAGES=500", IMAGE)
    # Add an email only to the existing seeded employee when it has none. Preserve all real addresses.
    result = dev.sql(guard + " UPDATE dbo.UsersMembers SET Email=N'localadmin@example.test' WHERE UserName=" + literal(values["admin_username"]) + " AND NULLIF(LTRIM(RTRIM(Email)),N'') IS NULL;", dev.DATABASE, quiet=True)
    if result.returncode:
        raise RuntimeError("Could not configure the seeded employee email.")
    dev.app_setting(tree, "LocalOtp.Enabled", "true")
    dev.app_setting(tree, "LocalOtp.FixedCode", "false" if args.random_otp else "true")
    dev.save_xml(tree, api)
    state = LOCAL / "device.json"
    device = json.loads(state.read_text()) if state.exists() else {
        "DeviceID": str(uuid.uuid4()), "Platform": "Android", "Manufacturer": "Local development",
        "Model": "Swagger", "OSVersion": "14", "MACID": None, "FCMToken": "local-swagger-no-real-push-token"
    }
    result = dev.sql("SET NOCOUNT ON; SELECT N'LOCAL_DEVICE_JSON:'+(SELECT d.DeviceID,d.DevicePlatform AS Platform FROM dbo.MobileApi_Devices d JOIN dbo.UsersMembers u ON u.ID=d.UserID WHERE d.IsApproved=1 AND u.UserName=" + literal(values["admin_username"]) + " FOR JSON PATH) AS DeviceJson;", dev.DATABASE, quiet=True)
    if result.returncode:
        raise RuntimeError("Could not read the seeded employee's existing device.")
    import re
    match = re.search(r"LOCAL_DEVICE_JSON:(\[.*\])", result.stdout)
    if match is None:
        raise RuntimeError("Could not read local device metadata.")
    registered = json.loads(match.group(1))
    if len(registered) > 1:
        raise RuntimeError("Resolve multiple approved devices before using local authentication.")
    if registered:
        device.update(registered[0])
    state.write_text(json.dumps(device, indent=2) + "\n"); state.chmod(0o600)
    result = dev.sql("SET NOCOUNT ON; SELECT Employee_Number FROM dbo.UsersMembers WHERE UserName=" + literal(values["admin_username"]) + ";", dev.DATABASE, quiet=True)
    numbers = re.findall(r"(?m)^\s*(\d+)\s*$", result.stdout)
    if result.returncode or len(numbers) != 1:
        raise RuntimeError("The seeded employee must have one employee number.")
    login = {"Username": values["admin_username"], "Password": values["admin_password"], "AppVersion": "1.0.0", "AppBuild": "local-swagger", "Device": device}
    examples = {"register_or_login": login, "forgot_password": {"EmployeeNumber": int(numbers[0])},
                "verify_registration_otp": {"ChallengeID": "COPY_FROM_REGISTER_RESPONSE", "Purpose": "registration", "OTP": "12345" if not args.random_otp else "COPY_FROM_LOCAL_EMAIL"},
                "verify_recovery_otp": {"ChallengeID": "COPY_FROM_FORGOT_PASSWORD_RESPONSE", "Purpose": "password-reset", "OTP": "12345" if not args.random_otp else "COPY_FROM_LOCAL_EMAIL"}}
    path = LOCAL / "swagger-requests.json"
    path.write_text(json.dumps(examples, indent=2) + "\n"); path.chmod(0o600)
    print("Local inbox: http://127.0.0.1:8025")
    print("Authentication: http://127.0.0.1:3001/swagger?module=authentication")
    print("Private Swagger request examples:", path)
    print("OTP mode:", "random six digits" if args.random_otp else "Debug-only fixed code 12345")
    print("Use a Debug build. No tests, password resets, device activation or real email delivery were performed.")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError) as error:
        print(str(error), file=sys.stderr)
        raise SystemExit(1)
