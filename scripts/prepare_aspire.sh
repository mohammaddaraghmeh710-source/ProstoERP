#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$PWD/.local-development/tools/bin:/Library/Frameworks/Mono.framework/Versions/Current/Commands:/usr/local/share/dotnet:/usr/local/bin:/opt/homebrew/bin:$PATH"

# Use the existing toolchain for each project; do not invoke setup verification.
msbuild ERP_Prosto.sln /t:Build /p:Configuration=Debug /m:1 /nr:false /p:UseSharedCompilation=false /verbosity:minimal /nologo
dotnet build orchestration/ProstoERP.AppHost/ProstoERP.AppHost.csproj --nologo

# Release only web servers recorded and owned by our local launcher.
python3 scripts/run_local.py stop
