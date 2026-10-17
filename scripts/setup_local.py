#!/usr/bin/env python3
"""Restore ignored local templates without overwriting existing configuration."""
from pathlib import Path
import shutil


def main():
    root = Path(__file__).resolve().parents[1]
    templates = (
        "src/Portal/Web.config",
        "src/ProstoERP.Api/Web.config",
        "src/ProstoERP.Api/Shared/Authentication/AuthenticationAttribute.cs",
        "src/ProstoERP.Infrastructure/app.config",
        "src/ProstoERP.Infrastructure/My Project/Settings.Designer.vb",
        "src/ProstoERP.Infrastructure/My Project/Settings.settings",
    )
    for name in templates:
        target = root / name
        if target.exists():
            print("Preserved:", name)
        else:
            shutil.copyfile(str(target) + ".example", target)
            print("Created:", name)

    print("Encryptor.dll is now built from the development Encryptor project.")
    print("Configure database connections and credentials before running the applications.")
    print("Template placeholders are not working credentials.")


if __name__ == "__main__":
    main()
