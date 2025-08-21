#!/usr/bin/env python3
import argparse
import json
from pathlib import Path

CONFIG_DEFAULT = "apr.config.json"


def load_config(repo_root: Path, config_path: str = CONFIG_DEFAULT) -> dict:
    cfg_path = repo_root / config_path
    with cfg_path.open("r", encoding="utf-8") as f:
        return json.load(f)


def write_report(repo_root: Path, report: dict, cfg: dict):
    path = cfg.get("paths", {}).get("report_path", "apr-report.json")
    (repo_root / path).write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", default=str(Path(__file__).resolve().parents[2]))
    ap.add_argument("--config", default=CONFIG_DEFAULT)
    ap.add_argument("--report_json", required=True)
    args = ap.parse_args()

    repo_root = Path(args.repo).resolve()
    cfg = load_config(repo_root, args.config)
    report = json.loads(Path(args.report_json).read_text(encoding="utf-8"))
    write_report(repo_root, report, cfg)
    print(json.dumps({"written": True, "path": cfg.get('paths', {}).get('report_path', 'apr-report.json')}, indent=2))


if __name__ == "__main__":
    main()
