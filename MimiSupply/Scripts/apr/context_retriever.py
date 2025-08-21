#!/usr/bin/env python3
import argparse
import fnmatch
import json
import os
from pathlib import Path
from typing import Dict, List, Set

CONFIG_DEFAULT = "apr.config.json"


def load_config(repo_root: Path, config_path: str = CONFIG_DEFAULT) -> dict:
    cfg_path = repo_root / config_path
    with cfg_path.open("r", encoding="utf-8") as f:
        return json.load(f)


def list_scoped_files(repo_root: Path, scopes: List[str], excludes: List[str]) -> List[Path]:
    files: Set[Path] = set()
    for pattern in scopes:
        for p in repo_root.glob(pattern):
            if p.is_file():
                files.add(p)
    # apply excludes
    filtered = []
    for p in files:
        rel = p.relative_to(repo_root).as_posix()
        if any(fnmatch.fnmatch(rel, ex) for ex in excludes):
            continue
        filtered.append(p)
    return sorted(filtered)


def read_files(paths: List[Path], max_files: int = 200, max_bytes: int = 250_000) -> Dict[str, str]:
    contents = {}
    for p in paths[:max_files]:
        try:
            data = p.read_bytes()
            if len(data) > max_bytes:
                data = data[:max_bytes]
            contents[p.as_posix()] = data.decode("utf-8", errors="ignore")
        except Exception as e:
            contents[p.as_posix()] = f"<READ_ERROR: {e}>"
    return contents


def compute_focus(failures: dict, repo_root: Path) -> List[Path]:
    focus: List[Path] = []
    for err in failures.get("errors", []):
        p = Path(err.get("path", ""))
        if not p.is_absolute():
            p = (repo_root / err.get("path", "")).resolve()
        if p.exists():
            focus.append(p)
    return focus


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", default=str(Path(__file__).resolve().parents[2]), help="Repository root (default: project root)")
    ap.add_argument("--config", default=CONFIG_DEFAULT)
    ap.add_argument("--failures_json", help="Path to failures JSON (from failure_parser)")
    args = ap.parse_args()

    repo_root = Path(args.repo).resolve()
    cfg = load_config(repo_root, args.config)

    failures = {"errors": [], "tests_failed": []}
    if args.failures_json:
        failures = json.loads(Path(args.failures_json).read_text(encoding="utf-8"))

    focus_paths = compute_focus(failures, repo_root)

    # Candidate set = focus + file_scopes
    scoped = list_scoped_files(repo_root, cfg.get("file_scopes", []), cfg.get("excludes", []))
    candidates = list(dict.fromkeys(focus_paths + scoped))
    contents = read_files(candidates)

    out = {
        "focus": [p.as_posix() for p in focus_paths],
        "candidates": [p.as_posix() for p in candidates],
        "contexts": contents,
    }
    print(json.dumps(out, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
