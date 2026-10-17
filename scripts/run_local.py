#!/usr/bin/env python3
"""Start/stop the two local Mono/XSP development servers on loopback only."""
import argparse
import json
import os
from pathlib import Path
import signal
import socket
import subprocess
import time
import urllib.error
import urllib.request
import webbrowser

ROOT = Path(__file__).resolve().parents[1]
LOCAL = ROOT / ".local-development"
PROJECTS = (("src/Portal", 52219, "portal"), ("src/ProstoERP.Api", 3001, "api"))


def owned(pid, project):
    result = subprocess.run(["ps", "-p", str(pid), "-o", "command="], text=True, capture_output=True)
    return result.returncode == 0 and "xsp4" in result.stdout and str(ROOT / project) in result.stdout


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("start", "stop", "status"), default="start", nargs="?")
    parser.add_argument("--open-browser", action="store_true", help="Open the Portal login page after startup")
    args = parser.parse_args()
    if args.open_browser and args.action != "start":
        parser.error("--open-browser requires start")
    LOCAL.mkdir(exist_ok=True)
    state = LOCAL / "servers.json"
    pids = json.loads(state.read_text()) if state.exists() else {}
    for project, port, name in PROJECTS:
        pid = pids.get(name)
        alive = bool(pid and owned(pid, project))
        if args.action == "stop":
            if alive:
                os.kill(pid, signal.SIGTERM)
                print("Stopped", name)
            pids.pop(name, None)
        elif args.action == "start" and not alive:
            with socket.socket() as sock:
                if sock.connect_ex(("127.0.0.1", port)) == 0:
                    raise RuntimeError(f"Port {port} is already occupied; no existing process was stopped.")
            with (LOCAL / (name + ".log")).open("a") as log:
                process = subprocess.Popen(["xsp4", "--nonstop", "--address=127.0.0.1", "--port=" + str(port),
                                            "--applications=/:" + str(ROOT / project)], cwd=ROOT / project,
                                           stdin=subprocess.DEVNULL, stdout=log, stderr=subprocess.STDOUT,
                                           start_new_session=True)
            pids[name] = process.pid
            state.write_text(json.dumps(pids))
            time.sleep(1)
            if process.poll() is not None:
                raise RuntimeError("Server failed to start; inspect " + str(LOCAL / (name + ".log")))
            print(name, "started at http://127.0.0.1:" + str(port) + "/")
        else:
            print(name, "running" if alive else "stopped")
    state.write_text(json.dumps(pids))
    if args.open_browser:
        url = "http://127.0.0.1:52219/login.aspx"
        deadline = time.monotonic() + 60
        while True:
            try:
                with urllib.request.urlopen(url, timeout=5) as response:
                    response.read(1)
                break
            except (urllib.error.URLError, TimeoutError, OSError):
                if time.monotonic() >= deadline:
                    raise RuntimeError("Portal did not become ready; inspect " + str(LOCAL / "portal.log"))
                time.sleep(1)
        if not webbrowser.open(url):
            raise RuntimeError("Could not open the browser. Open " + url)
        print("Opened", url)


if __name__ == "__main__":
    main()
