#!/usr/bin/env python3
import argparse
import json
import re
from pathlib import Path

ERROR_RE = re.compile(r"^(?P<path>.*?\.swift):(?P<line>\d+):(?P<col>\d+):\s+error:\s+(?P<msg>.*)$")
TEST_FAIL_RE = re.compile(r"Test Case '-\[(?P<class>[^ ]+)\s+(?P<method>[^\]]+)\]' failed")
GENERIC_TEST_FAIL_RE = re.compile(r"\bfail(ed|ure)\b", re.IGNORECASE)


def parse_build_log(log_path: Path):
    errors = []
    tests_failed = []
    if not log_path.exists():
        return {"errors": errors, "tests_failed": tests_failed, "log_missing": True}
    with log_path.open("r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            line = line.rstrip("\n")
            m = ERROR_RE.match(line)
            if m:
                d = m.groupdict()
                errors.append({
                    "path": d["path"],
                    "line": int(d["line"]),
                    "col": int(d["col"]),
                    "message": d["msg"].strip(),
                })
                continue
            t = TEST_FAIL_RE.search(line)
            if t:
                tests_failed.append(f"{t.group('class')}.{t.group('method')}")
            else:
                # Heuristic: capture lines in test logs mentioning failure
                if "Test Case" in line and GENERIC_TEST_FAIL_RE.search(line):
                    tests_failed.append(line.strip())
    return {"errors": errors, "tests_failed": tests_failed, "log_missing": False}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--log", default="build.log", help="Path to xcodebuild log (default: build.log)")
    args = ap.parse_args()
    result = parse_build_log(Path(args.log))
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
