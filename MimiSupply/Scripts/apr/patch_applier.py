#!/usr/bin/env python3
import argparse
import difflib
import fnmatch
import json
from pathlib import Path
from typing import List, Dict

CONFIG_DEFAULT = "apr.config.json"


def load_config(repo_root: Path, config_path: str = CONFIG_DEFAULT) -> dict:
    cfg_path = repo_root / config_path
    with cfg_path.open("r", encoding="utf-8") as f:
        return json.load(f)


def within_scope(rel_path: str, cfg: dict) -> bool:
    if any(fnmatch.fnmatch(rel_path, ex) for ex in cfg.get("excludes", [])):
        return False
    if not cfg.get("file_scopes"):
        return True
    return any(fnmatch.fnmatch(rel_path, pat) for pat in cfg["file_scopes"])


def count_change_lines(old: str, new: str) -> int:
    diff = list(difflib.ndiff(old.splitlines(True), new.splitlines(True)))
    return sum(1 for d in diff if d and d[0] in "+-")


def apply_changes(repo_root: Path, cfg: dict, patch: dict) -> Dict:
    changes_applied = []
    backups = []
    rejected = []
    total_changed = 0

    for change in patch.get("changes", []):
        path = (repo_root / change["path"]).resolve()
        rel = path.relative_to(repo_root).as_posix()
        if not within_scope(rel, cfg):
            rejected.append({"path": rel, "reason": "out_of_scope"})
            continue
        if not path.exists():
            rejected.append({"path": rel, "reason": "not_found"})
            continue
        old = path.read_text(encoding="utf-8", errors="ignore")
        new = change.get("content", "")
        changed = count_change_lines(old, new)
        if total_changed + changed > int(cfg.get("max_change_lines", 120)):
            rejected.append({"path": rel, "reason": "max_change_lines_exceeded"})
            continue
        # backup
        bak = path.with_suffix(path.suffix + ".apr.bak")
        bak.write_text(old, encoding="utf-8")
        backups.append(bak)
        path.write_text(new, encoding="utf-8")
        total_changed += changed
        changes_applied.append({"path": rel, "changed_lines": changed})

    return {
        "applied": changes_applied,
        "rejected": rejected,
        "total_changed": total_changed,
        "backups": [b.relative_to(repo_root).as_posix() for b in backups],
    }


def rollback(repo_root: Path, result: Dict):
    for b in result.get("backups", []):
        bak = (repo_root / b).resolve()
        if bak.exists():
            orig = bak.with_suffix("")  # remove .apr.bak
            try:
                orig.write_text(bak.read_text(encoding="utf-8"), encoding="utf-8")
                bak.unlink()
            except Exception:
                pass


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", default=str(Path(__file__).resolve().parents[2]))
    ap.add_argument("--config", default=CONFIG_DEFAULT)
    ap.add_argument("--patch_json", required=True)
    ap.add_argument("--rollback", action="store_true", help="Rollback using recorded backups in patch result")
    args = ap.parse_args()

    repo_root = Path(args.repo).resolve()
    cfg = load_config(repo_root, args.config)

    result = json.loads(Path(args.patch_json).read_text(encoding="utf-8"))
    if args.rollback:
        rollback(repo_root, result)
        print(json.dumps({"rolled_back": True}, indent=2))
    else:
        applied = apply_changes(repo_root, cfg, result)
        print(json.dumps(applied, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
