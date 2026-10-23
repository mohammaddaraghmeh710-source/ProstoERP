#!/usr/bin/env python3
"""Build and stage an API release for review, without copying local settings or deploying."""
import argparse
import hashlib
import json
import ntpath
from pathlib import Path
import shutil
import subprocess
import xml.etree.ElementTree as ET
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[1]
API = ROOT / "src/ProstoERP.Api"
NS = {"m": "http://schemas.microsoft.com/developer/msbuild/2003"}


def write_web_config(tree, path):
    # .NET configuration rejects namespace declarations on its root element.
    value = ET.tostring(tree.getroot(), encoding="unicode")
    value = value.replace(' xmlns:ns0="urn:schemas-microsoft-com:asm.v1"', '')
    value = value.replace('<ns0:assemblyBinding', '<assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1"')
    value = value.replace('ns0:', '')
    path.write_text('<?xml version="1.0" encoding="utf-8"?>\n' + value)


def validate_config(path):
    tree = ET.parse(path)
    settings = {node.get("key"): node.get("value", "") for node in tree.findall("appSettings/add")}
    issues = []
    required = ("Integration.BasicUsername", "Integration.BasicPassword", "PasswordReset.HashKey",
                "MobileApi.AssetBaseUrl", "MobileApi.FeedbackStoragePath",
                "MobileApi.CorrespondenceStoragePath", "CustomerApi.PortalRoot")
    for key in required:
        value = settings.get(key, "")
        if not value or "REPLACE_WITH" in value:
            issues.append("Configure " + key)
    if settings.get("MobileApi.AllowHttp", "false").lower() != "false":
        issues.append("Disable MobileApi.AllowHttp")
    if any(settings.get(key, "false").lower() != "false" for key in ("LocalOtp.Enabled", "LocalOtp.FixedCode")):
        issues.append("Disable LocalOtp.Enabled and LocalOtp.FixedCode")
    if any(key.startswith("LocalDevelopment.") for key in settings):
        issues.append("Remove LocalDevelopment.* settings")
    if not settings.get("MobileApi.AssetBaseUrl", "").startswith("https://"):
        issues.append("MobileApi.AssetBaseUrl must use HTTPS")
    for key in ("MobileApi.FeedbackStoragePath", "MobileApi.CorrespondenceStoragePath", "CustomerApi.PortalRoot"):
        value = settings.get(key, "")
        if value and not (Path(value).is_absolute() or ntpath.isabs(value)):
            issues.append(key + " must be an absolute server path")
    entry = tree.find("connectionStrings/add[@name='Prosto_ERP_ConnectionConnection']")
    connection = "" if entry is None else entry.get("connectionString", "")
    if not connection or any(marker in connection for marker in ("YOUR_SERVER", "YOUR_DATABASE", "REPLACE_WITH")):
        issues.append("Configure Prosto_ERP_ConnectionConnection")
    compilation = tree.find("system.web/compilation")
    if compilation is not None and compilation.get("debug", "false").lower() == "true":
        issues.append("Disable compilation debug")
    return issues


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, help="New or empty staging directory")
    parser.add_argument("--validate-config", type=Path, help="Check deployment settings without building or staging")
    args = parser.parse_args()
    if args.validate_config:
        issues = validate_config(args.validate_config)
        for issue in issues:
            print(issue)
        print("Configuration structure checked; credentials and server access were not verified.")
        return 1 if issues else 0
    output = args.output or ROOT / "artifacts/api-release" / datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    output = output.resolve()
    if output == ROOT or ROOT.is_relative_to(output) or output.is_relative_to(ROOT / "src"):
        parser.error("Choose a staging directory outside source folders")
    if output.exists() and any(output.iterdir()):
        parser.error("The staging directory must be new or empty; existing files are preserved")
    subprocess.run(["msbuild", str(API / "ProstoERP.Api.csproj"), "/t:Build", "/p:Configuration=Release",
                    "/m:1", "/nr:false", "/p:UseSharedCompilation=false", "/verbosity:minimal", "/nologo"],
                   cwd=ROOT, check=True)
    output.mkdir(parents=True, exist_ok=True)
    # Explicit project content only: omit the ignored application config and all transforms/templates.
    content = ET.parse(ROOT / "build/Api.Content.props")
    for item in content.findall(".//m:Content", NS):
        relative = Path(item.get("Include").replace("\\", "/"))
        if relative.name in ("Web.config", "Web.Debug.config", "Web.Release.config") and len(relative.parts) == 1:
            continue
        source = API / relative
        if source.is_file():
            target = output / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)
    # Root *.config files in bin may contain local connection strings; the root Web.config owns settings.
    for source in (API / "bin").rglob("*"):
        if not source.is_file():
            continue
        relative = source.relative_to(API / "bin")
        if len(relative.parts) == 1 and source.suffix.lower() == ".config":
            continue
        target = output / "bin" / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
    tree = ET.parse(API / "Web.config.example")
    settings = tree.find("appSettings")
    for item in settings.findall("add"):
        if item.get("key") == "MobileApi.AllowHttp":
            item.set("value", "false")
    tree.find("system.web/compilation").set("debug", "false")
    write_web_config(tree, output / "Web.config")
    blockers = [
        "Configure the staged Web.config with server-specific settings and secrets.",
        "Replace the development-only Encryptor implementation with the original production-compatible implementation.",
        "Review generated Infrastructure settings and rebuild against production configuration before deployment.",
        "Provision IIS with .NET Framework 4.8, HTTPS, SQL schema/migrations, and persistent storage permissions.",
    ]
    manifest = {"purpose": "deployment preparation only", "deployed": False, "productionReady": False,
                "configuration": "Release", "blockers": blockers,
                "files": {str(p.relative_to(output)): hashlib.sha256(p.read_bytes()).hexdigest()
                          for p in sorted(output.rglob("*")) if p.is_file()}}
    (output / "release-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print("API release staged for review:", output)
    print("No deployment performed. Resolve release-manifest.json blockers before publishing.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
