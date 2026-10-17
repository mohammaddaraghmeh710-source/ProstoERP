#!/usr/bin/env python3
"""Run Aspire in the foreground and open its authenticated local dashboard."""
import argparse
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import webbrowser

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--no-browser", action="store_true")
    args = parser.parse_args()
    process = subprocess.Popen(
        ["dotnet", "run", "--project", "orchestration/ProstoERP.AppHost/ProstoERP.AppHost.csproj"],
        cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
        start_new_session=True)

    def stop(signum, frame):
        if process.poll() is None:
            os.killpg(process.pid, signal.SIGTERM)

    signal.signal(signal.SIGINT, stop)
    signal.signal(signal.SIGTERM, stop)
    opened = False
    try:
        for line in process.stdout:
            print(line, end="", flush=True)
            if not opened and not args.no_browser and "Login to the dashboard at" in line:
                match = re.search(r"http://127\.0\.0\.1:15888/login\?t=[A-Za-z0-9_\-]+", line)
                if match:
                    opened = webbrowser.open(match.group(0))
        return process.wait()
    finally:
        if process.poll() is None:
            os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=20)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait(timeout=10)


if __name__ == "__main__":
    sys.exit(main())
