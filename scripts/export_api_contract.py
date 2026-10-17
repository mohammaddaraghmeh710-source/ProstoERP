#!/usr/bin/env python3
"""Export the running API's Swagger contract for mobile client generation."""
import argparse
import json
from pathlib import Path
from urllib.request import urlopen

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--url", default="http://127.0.0.1:3001/swagger/docs/v1")
    parser.add_argument("--output", type=Path,
                        default=ROOT / "artifacts/contracts/prosto-erp-v1.openapi.json")
    args = parser.parse_args()
    with urlopen(args.url, timeout=30) as response:
        document = json.load(response)
    if document.get("swagger") != "2.0" or not isinstance(document.get("paths"), dict):
        raise ValueError("The endpoint did not return a Swagger 2.0 API contract.")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(document, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    methods = {"get", "post", "put", "patch", "delete", "head", "options"}
    operations = sum(method in methods for path in document["paths"].values() for method in path)
    print(f"Exported {len(document['paths'])} paths and {operations} operations to {args.output}")


if __name__ == "__main__":
    main()
