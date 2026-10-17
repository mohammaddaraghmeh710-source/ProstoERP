#!/usr/bin/env python3
"""Configure a fresh, isolated local ERP development environment. Never restores production data."""
import argparse
import base64
import hashlib
import json
import os
import platform
from pathlib import Path
import secrets
import shutil
import stat
import subprocess
import sys
import tempfile
import time
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
LOCAL = ROOT / ".local-development"
CONTAINER = "prosto-erp-dev-sql"
DATABASE = "Prosto_ERP_Development"
os.environ["PATH"] = str(LOCAL / "tools/bin") + os.pathsep + os.environ.get("PATH", "")
if (Path.home() / ".colima/prosto-erp/docker.sock").exists():
    os.environ["DOCKER_HOST"] = "unix://" + str(Path.home() / ".colima/prosto-erp/docker.sock")


def run(args, **kwargs):
    return subprocess.run(args, cwd=ROOT, check=True, text=True, **kwargs)


def save_xml(tree, path):
    # .NET configuration rejects namespace declarations on <configuration>.
    # Keep the assembly-binding namespace scoped to its own section.
    text = ET.tostring(tree.getroot(), encoding="unicode")
    text = text.replace(' xmlns:ns0="urn:schemas-microsoft-com:asm.v1"', '')
    text = text.replace('<ns0:assemblyBinding', '<assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1"')
    text = text.replace('ns0:', '')
    text = '<?xml version="1.0" encoding="utf-8"?>\n' + text
    if not path.exists() or path.read_text() != text:
        path.write_text(text)
    if stat.S_IMODE(path.stat().st_mode) != 0o600:
        path.chmod(0o600)


def app_setting(tree, key, value):
    node = tree.find("appSettings")
    if node is None:
        node = ET.SubElement(tree.getroot(), "appSettings")
    entry = node.find("add[@key='" + key + "']")
    if entry is None:
        entry = ET.SubElement(node, "add", key=key)
    entry.set("value", value)


def configure():
    run([sys.executable, str(ROOT / "scripts/setup_local.py")], stdout=subprocess.DEVNULL)
    LOCAL.mkdir(mode=0o700, exist_ok=True)
    settings = LOCAL / "settings.json"
    if settings.exists():
        values = json.loads(settings.read_text())
    else:
        values = {
            "encryption_key": base64.b64encode(secrets.token_bytes(32)).decode(),
            "sql_password": "Pr0sto!" + secrets.token_urlsafe(24),
            "admin_username": "localadmin",
            "admin_password": "Dev!" + secrets.token_urlsafe(18),
            "basic_username": "local-integration",
            "basic_password": secrets.token_urlsafe(24),
            "reset_key": base64.b64encode(secrets.token_bytes(32)).decode(),
        }
        settings.write_text(json.dumps(values, indent=2) + "\n")
        settings.chmod(0o600)
    connection = ("Server=127.0.0.1,14333;Database=" + DATABASE + ";User ID=sa;Password="
                  + values["sql_password"] + ";Encrypt=False;TrustServerCertificate=True;")
    for name in ("src/Portal/Web.config", "src/ProstoERP.Api/Web.config", "src/ProstoERP.Infrastructure/app.config"):
        path = ROOT / name
        if not path.exists():
            shutil.copyfile(str(path) + ".example", path)
        tree = ET.parse(path)
        for entry in tree.findall("connectionStrings/add"):
            existing = entry.get("connectionString", "")
            if "YOUR_SERVER" not in existing and "REPLACE_WITH" not in existing and DATABASE not in existing:
                raise RuntimeError("Refusing to replace non-development configuration: " + name)
            entry.set("connectionString", connection)
        if name.endswith("Web.config"):
            app_setting(tree, "LocalDevelopment.Enabled", "true")
            app_setting(tree, "LocalDevelopment.EncryptionKey", values["encryption_key"])
            if name.startswith("src/Portal/"):
                app_setting(tree, "PasswordReset.ApiBaseUrl", "http://127.0.0.1:3001/")
                app_setting(tree, "PasswordReset.BasicUsername", values["basic_username"])
                app_setting(tree, "PasswordReset.BasicPassword", values["basic_password"])
                app_setting(tree, "AttendanceApi.BaseUrl", "http://127.0.0.1:3001/")
                tree.find("system.web/authentication").set("mode", "None")
                if platform.system() != "Windows":
                    # Mono ASP.NET reads this older section for VB page compilation.
                    compilation = tree.find("system.web/compilation")
                    # Do not let an unsupported async page poison compilation of
                    # unrelated master pages in the same directory under Mono.
                    compilation.set("batch", "false")
                    compilers = compilation.find("compilers")
                    if compilers is None:
                        compilers = ET.SubElement(compilation, "compilers")
                    if compilers.find("compiler[@language='vb;vbs;visualbasic;vbscript']") is None:
                        ET.SubElement(compilers, "compiler", language="vb;vbs;visualbasic;vbscript", extension=".vb",
                                      type="Prosto.Development.MonoVisualBasicCodeProvider, Prosto.Development.Hosting",
                                      compilerOptions="/langversion:default /optionInfer+")
            else:
                app_setting(tree, "PasswordReset.HashKey", values["reset_key"])
                app_setting(tree, "MobileApi.AllowHttp", "true")
                app_setting(tree, "MobileApi.AssetBaseUrl", "http://127.0.0.1:52219/")
                for key, folder in (("MobileApi.CorrespondenceStoragePath", "Correspondence"),
                                    ("MobileApi.FeedbackStoragePath", "Feedback")):
                    directory = ROOT / "src/Portal/App_Data" / folder
                    directory.mkdir(parents=True, exist_ok=True)
                    app_setting(tree, key, str(directory))
                app_setting(tree, "CustomerApi.PortalRoot", str(ROOT / "src/Portal"))
        save_xml(tree, path)
    # The legacy template compiles fixed credentials into this ignored local source.
    path = ROOT / "src/ProstoERP.Api/Shared/Authentication/AuthenticationAttribute.cs"
    template = Path(str(path) + ".example").read_text()
    if path.exists() and path.read_text() not in (template, template.replace("REPLACE_WITH_LOCAL_USERNAME", values["basic_username"]).replace("REPLACE_WITH_LOCAL_SECRET", values["basic_password"])):
        raise RuntimeError("Refusing to replace custom integration authentication source.")
    source = template.replace("REPLACE_WITH_LOCAL_USERNAME", values["basic_username"]).replace("REPLACE_WITH_LOCAL_SECRET", values["basic_password"])
    if not path.exists() or path.read_text() != source:
        path.write_text(source)
    if stat.S_IMODE(path.stat().st_mode) != 0o600:
        path.chmod(0o600)
    for folder in ("src/Portal/Uploads", "src/Portal/FileManager", "src/Portal/App_Data"):
        (ROOT / folder).mkdir(parents=True, exist_ok=True)
    config = ET.ElementTree(ET.Element("configuration"))
    app_setting(config, "LocalDevelopment.Enabled", "true")
    app_setting(config, "LocalDevelopment.EncryptionKey", values["encryption_key"])
    save_xml(config, LOCAL / "DevelopmentTools.exe.config")
    (LOCAL / "sql.env").write_text("ACCEPT_EULA=Y\nMSSQL_PID=Developer\nMSSQL_SA_PASSWORD=" + values["sql_password"] + "\n")
    (LOCAL / "sql.env").chmod(0o600)
    (LOCAL / "credentials.txt").write_text(
        "Development only. New encryption format; do not connect to a production database.\n"
        "Portal: http://127.0.0.1:52219/Login.aspx\nAPI: http://127.0.0.1:3001/\n"
        "Username: " + values["admin_username"] + "\nPassword: " + values["admin_password"] +
        "\nSQL Server: 127.0.0.1,14333\nDatabase: " + DATABASE + "\nSQL username: sa\nSQL password: " + values["sql_password"] + "\n")
    (LOCAL / "credentials.txt").chmod(0o600)
    print("Development configuration ready. Credentials:", LOCAL / "credentials.txt", flush=True)
    return values


def build():
    run(["msbuild", "ERP_Prosto.sln", "/m:1", "/nr:false", "/p:UseSharedCompilation=false", "/p:Configuration=Debug", "/verbosity:minimal", "/nologo"])
    run(["mcs", "-sdk:4.7.2", "-r:System.Configuration", "-r:src/Encryptor/bin/Debug/Encryptor.dll",
         "-out:" + str(LOCAL / "DevelopmentTools.exe"), "scripts/DevelopmentTools.cs"])
    shutil.copyfile(ROOT / "src/Encryptor/bin/Debug/Encryptor.dll", LOCAL / "Encryptor.dll")
    run(["mono", str(LOCAL / "DevelopmentTools.exe")])
    test_key_guards()
    if platform.system() != "Windows":
        run(["mcs", "-sdk:4.7.2", "-target:library", "-r:Microsoft.VisualBasic",
             "-out:src/Portal/bin/Prosto.Development.Hosting.dll", "scripts/MonoVisualBasicCodeProvider.cs"])


def test_key_guards():
    original = ET.parse(LOCAL / "DevelopmentTools.exe.config")
    cipher = run(["mono", str(LOCAL / "DevelopmentTools.exe"), "encrypt"], input="local test", capture_output=True).stdout
    with tempfile.TemporaryDirectory(dir=LOCAL) as directory:
        folder = Path(directory)
        for name in ("DevelopmentTools.exe", "Encryptor.dll"):
            shutil.copyfile(LOCAL / name, folder / name)
        path = folder / "DevelopmentTools.exe.config"
        app_setting(original, "LocalDevelopment.Enabled", "false")
        save_xml(original, path)
        process = subprocess.run(["mono", str(folder / "DevelopmentTools.exe")], capture_output=True, text=True)
        assert process.returncode != 0 and "restricted" in process.stderr
        app_setting(original, "LocalDevelopment.Enabled", "true")
        app_setting(original, "LocalDevelopment.EncryptionKey", "invalid")
        save_xml(original, path)
        process = subprocess.run(["mono", str(folder / "DevelopmentTools.exe")], capture_output=True, text=True)
        assert process.returncode != 0 and "base64" in process.stderr
        app_setting(original, "LocalDevelopment.EncryptionKey", base64.b64encode(secrets.token_bytes(32)).decode())
        save_xml(original, path)
        process = subprocess.run(["mono", str(folder / "DevelopmentTools.exe"), "decrypt"], input=cipher, capture_output=True, text=True)
        assert process.returncode != 0 and "authentication failed" in process.stderr
    print("Encryptor: disabled mode, malformed key and wrong-key rejection passed.")


def sql(text, database="master", quiet=False):
    command = 'SQLCMDPASSWORD="$MSSQL_SA_PASSWORD" exec /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C -I -b -d ' + database
    text = ("SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; "
            "SET CONCAT_NULL_YIELDS_NULL ON; SET ARITHABORT ON; SET NUMERIC_ROUNDABORT OFF;\nGO\n" + text)
    result = subprocess.run(["docker", "exec", "-i", CONTAINER, "/bin/bash", "-c", command],
                            input=text, text=True, capture_output=True)
    if result.returncode and not quiet:
        raise RuntimeError("Local SQL command failed:\n" + result.stdout + result.stderr)
    return result


def database(values):
    run(["docker", "info"], stdout=subprocess.DEVNULL)
    inspection = subprocess.run(["docker", "container", "inspect", CONTAINER], capture_output=True, text=True)
    exists = inspection.returncode == 0
    if exists:
        labels = json.loads(inspection.stdout)[0].get("Config", {}).get("Labels", {}) or {}
        if labels.get("prosto.local-development") != "true":
            raise RuntimeError("Refusing to use an existing container without the project's development label.")
        run(["docker", "start", CONTAINER], stdout=subprocess.DEVNULL)
    else:
        run(["docker", "run", "-d", "--name", CONTAINER, "--restart", "unless-stopped",
             "--label", "prosto.local-development=true", "--env-file", str(LOCAL / "sql.env"),
             "-p", "127.0.0.1:14333:1433", "-v", "prosto-erp-dev-sql-data:/var/opt/mssql",
             "mcr.microsoft.com/mssql/server:2022-latest"])
    for _ in range(120):
        if sql("SELECT 1;", quiet=True).returncode == 0:
            break
        time.sleep(2)
    else:
        raise RuntimeError("SQL Server did not become ready; inspect docker logs " + CONTAINER)
    sql("""IF DB_ID('Prosto_ERP_Development') IS NULL
BEGIN
 CREATE DATABASE Prosto_ERP_Development;
END
GO
USE Prosto_ERP_Development;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name='ProstoLocalDevelopment')
BEGIN
 IF EXISTS(SELECT 1 FROM sys.tables) THROW 51000, 'Refusing to initialize an unmarked existing database.', 1;
 EXEC sys.sp_addextendedproperty @name=N'ProstoLocalDevelopment',@value=N'1';
END
GO
""")
    fingerprint = hashlib.sha256(base64.b64decode(values["encryption_key"])).hexdigest()
    sql("IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ProstoDevEncryptionKey' AND CONVERT(nvarchar(100),value)<>N'" + fingerprint + "') THROW 51001, 'Local encryption key does not match this database. Restore .local-development/settings.json.', 1;\n"
        "IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ProstoDevEncryptionKey') EXEC sys.sp_addextendedproperty @name=N'ProstoDevEncryptionKey',@value=N'" + fingerprint + "';", DATABASE)
    sql((ROOT / "database/development/001_Core.sql").read_text(), DATABASE)
    encrypted = run(["mono", str(LOCAL / "DevelopmentTools.exe"), "encrypt"],
                    input=values["admin_password"], capture_output=True).stdout
    quote = lambda value: "N'" + value.replace("'", "''") + "'"
    sql("""IF NOT EXISTS(SELECT 1 FROM dbo.Users_Types WHERE ID=1)
BEGIN
 SET IDENTITY_INSERT dbo.Users_Types ON;
 INSERT dbo.Users_Types(ID,Title_Ar,Title_En,Item_Order) VALUES(1,N'مدير النظام',N'System administrator',1);
 SET IDENTITY_INSERT dbo.Users_Types OFF;
END;
IF NOT EXISTS(SELECT 1 FROM dbo.Brands WHERE ID=1)
BEGIN
 SET IDENTITY_INSERT dbo.Brands ON;
 INSERT dbo.Brands(ID,Title_Ar,Title_En) VALUES(1,N'علامة تجريبية',N'Development brand');
 SET IDENTITY_INSERT dbo.Brands OFF;
END;
IF NOT EXISTS(SELECT 1 FROM dbo.Branches WHERE ID=1)
BEGIN
 SET IDENTITY_INSERT dbo.Branches ON;
 INSERT dbo.Branches(ID,BrandID,Title_Ar,Title_En) VALUES(1,1,N'فرع تجريبي',N'Development branch');
 SET IDENTITY_INSERT dbo.Branches OFF;
END;
IF NOT EXISTS(SELECT 1 FROM dbo.Departments WHERE ID=1)
BEGIN
 SET IDENTITY_INSERT dbo.Departments ON;
 INSERT dbo.Departments(ID,BranchID,Title_Ar,Title_En) VALUES(1,1,N'قسم تجريبي',N'Development department');
 SET IDENTITY_INSERT dbo.Departments OFF;
END;
IF NOT EXISTS(SELECT 1 FROM dbo.JobTitles WHERE ID=1)
BEGIN
 SET IDENTITY_INSERT dbo.JobTitles ON;
 INSERT dbo.JobTitles(ID,DepartmentID,Title_Ar,Title_En) VALUES(1,1,N'مدير',N'Manager');
 SET IDENTITY_INSERT dbo.JobTitles OFF;
END;
IF NOT EXISTS(SELECT 1 FROM dbo.Shift WHERE ID=1)
BEGIN
 SET IDENTITY_INSERT dbo.Shift ON;
 INSERT dbo.Shift(ID,Title_Ar,Title_En,Start_Time,End_Time) VALUES(1,N'وردية تجريبية',N'Development shift','00:00','23:59:59');
 SET IDENTITY_INSERT dbo.Shift OFF;
END;
""" + "IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE UserName=" + quote(values["admin_username"]) + ")\n" +
        "INSERT dbo.UsersMembers(Type,Employee_Number,FullName_Ar,Fullname_En,UserName,Password,Brand_ID,Branch_ID,Department_ID,JobTitle_ID,Shif_ID,Status,Item_Order) VALUES(1,1,N'مدير محلي',N'Local administrator'," +
        quote(values["admin_username"]) + "," + quote(encrypted) + ",1,1,1,1,1,1,1);", DATABASE)
    for name in json.loads((ROOT / "database/development/migrations.json").read_text()):
        marker = "ProstoDev:" + name
        seen = sql("SET NOCOUNT ON; SELECT COUNT(*) FROM sys.extended_properties WHERE class=0 AND name=" + quote(marker) + ";", DATABASE)
        if "1" in seen.stdout.split():
            continue
        print("Applying", name, flush=True)
        result = sql((ROOT / "database/migrations" / name).read_text(encoding="utf-8-sig"), DATABASE, quiet=True)
        if result.returncode:
            raise RuntimeError("Migration failed: " + name + "\n" + result.stdout + result.stderr)
        sql("EXEC sys.sp_addextendedproperty @name=" + quote(marker) + ",@value=N'1';", DATABASE)
    print("SQL Server ready at 127.0.0.1,14333; database:", DATABASE, flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--database", action="store_true", help="Start Docker SQL Server and apply the development baseline")
    parser.add_argument("--build", action="store_true", help="Build with Mono, compile local hosting tools and test Encryptor")
    args = parser.parse_args()
    values = configure()
    if args.build or (args.database and not (LOCAL / "DevelopmentTools.exe").exists()):
        build()
    if args.database:
        database(values)


if __name__ == "__main__":
    main()
