#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$PWD/.local-development/tools/bin:/Library/Frameworks/Mono.framework/Versions/Current/Commands:/usr/local/share/dotnet:/usr/local/bin:/opt/homebrew/bin:$PATH"
if [ -S "$HOME/.colima/prosto-erp/docker.sock" ]; then
    export DOCKER_HOST="unix://$HOME/.colima/prosto-erp/docker.sock"
fi
# Stop only servers recorded and owned by our existing local launcher.
python3 scripts/run_local.py stop
exec python3 scripts/run_aspire.py "$@"
