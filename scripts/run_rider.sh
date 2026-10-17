#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="/Library/Frameworks/Mono.framework/Versions/Current/Commands:/usr/local/bin:/opt/homebrew/bin:$PATH"
exec python3 scripts/run_local.py start --open-browser
