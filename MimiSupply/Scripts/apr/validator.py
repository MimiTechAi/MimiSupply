#!/usr/bin/env python3
import argparse
import json
import shutil
import subprocess
from pathlib import Path
from typing import Dict, List

CONFIG_DEFAULT = "apr.config.json"


def load_config(repo_root: Path, config_path: str = CONFIG_DEFAULT) -> dict:
    cfg_path = repo_root / config_path
    with cfg_path.open("r", encoding="utf-8") as f:
        return json.load(f)


def run_cmd(cmd: List[str], cwd: Path) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, cwd=str(cwd), capture_output=True, text=True)


def run_swiftlint(repo_root: Path) -> Dict:
    if shutil.which("swiftlint") is None:
        return {"skipped": True, "reason": "swiftlint_not_found"}
    r = run_cmd(["swiftlint"], repo_root)
    return {"skipped": False, "returncode": r.returncode, "stdout": r.stdout, "stderr": r.stderr}


def run_swiftformat(repo_root: Path) -> Dict:
    if shutil.which("swiftformat") is None:
        return {"skipped": True, "reason": "swiftformat_not_found"}
    r = run_cmd(["swiftformat", "."], repo_root)
    return {"skipped": False, "returncode": r.returncode, "stdout": r.stdout, "stderr": r.stderr}


def run_tests(repo_root: Path, cfg: dict) -> Dict:
    xcfg = cfg.get("xcode", {})
    project_kind = xcfg.get("project_kind", "xcodeproj")
    project_path = xcfg.get("project_path")
    scheme = xcfg.get("scheme")
    destination = xcfg.get("destination")
    add_args = xcfg.get("additional_args", [])

    cmd = ["xcodebuild", "test"]
    if project_kind == "xcodeproj":
        cmd += ["-project", project_path]
    elif project_kind == "xcworkspace":
        cmd += ["-workspace", project_path]
    if scheme:
        cmd += ["-scheme", scheme]
    if destination:
        cmd += ["-destination", destination]
    cmd += add_args

    r = run_cmd(cmd, repo_root)

    # Write build log
    build_log = cfg.get("paths", {}).get("build_log", "build.log")
    (repo_root / build_log).write_text(r.stdout + "\n" + r.stderr, encoding="utf-8")

    return {
        "returncode": r.returncode,
        "passed": r.returncode == 0,
        "cmd": cmd,
        "log_path": build_log,
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", default=str(Path(__file__).resolve().parents[2]))
    ap.add_argument("--config", default=CONFIG_DEFAULT)
    ap.add_argument("--lint", action="store_true")
    ap.add_argument("--test", action="store_true")
    args = ap.parse_args()

    repo_root = Path(args.repo).resolve()
    cfg = load_config(repo_root, args.config)

    result = {"lint": {}, "test": {}}

    if args.lint and cfg.get("lint", {}).get("swiftlint", False):
        result["lint"]["swiftlint"] = run_swiftlint(repo_root)
    if args.lint and cfg.get("lint", {}).get("swiftformat", False):
        result["lint"]["swiftformat"] = run_swiftformat(repo_root)

    if args.test:
        result["test"] = run_tests(repo_root, cfg)

    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
