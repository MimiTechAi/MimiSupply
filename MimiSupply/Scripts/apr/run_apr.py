#!/usr/bin/env python3
import argparse
import json
import sys
from pathlib import Path

# Make sibling modules importable when run as a script
BASE_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(BASE_DIR))

import failure_parser  # noqa: E402
import context_retriever  # noqa: E402
import patch_applier  # noqa: E402
import validator  # noqa: E402
import reporter  # noqa: E402
import repair_agent  # noqa: E402

CONFIG_DEFAULT = "apr.config.json"


def main():
    ap = argparse.ArgumentParser(description="Run local APR pipeline for MimiSupply")
    ap.add_argument("--repo", default=str(BASE_DIR.parents[2]))
    ap.add_argument("--config", default=CONFIG_DEFAULT)
    ap.add_argument("--log", default="build.log", help="Path to xcodebuild log. If missing and --generate-log, tests will be run.")
    ap.add_argument("--generate-log", action="store_true", help="Run tests to generate build.log before parsing")
    ap.add_argument("--dry-run", action="store_true", help="Skip writing patches; only simulate")
    args = ap.parse_args()

    repo_root = Path(args.repo).resolve()
    cfg = repair_agent.load_config(repo_root, args.config)

    # Optionally generate build log by running tests
    log_path = repo_root / args.log
    if args.generate_log or not log_path.exists():
        test_result = validator.run_tests(repo_root, cfg)
        print(json.dumps({"generated_log": True, "test_passed": test_result.get("passed")}, indent=2))

    # Parse failures
    failures = failure_parser.parse_build_log(log_path)

    # Retrieve context
    ctx = context_retriever
    contexts = ctx.read_files(
        ctx.compute_focus(failures, repo_root) + ctx.list_scoped_files(repo_root, cfg.get("file_scopes", []), cfg.get("excludes", []))
    )
    contexts_payload = {"contexts": contexts}

    # Generate patch (may be empty if provider not configured)
    patch = repair_agent.generate_patch(repo_root, cfg, failures, contexts)

    result = {
        "failures": failures,
        "patch": patch,
        "apply": None,
        "validation": None,
        "rolled_back": False,
        "notes": patch.get("notes"),
    }

    applied = None
    if patch.get("changes"):
        if args.dry_run:
            applied = {"applied": [], "rejected": [], "total_changed": 0, "backups": []}
        else:
            applied = patch_applier.apply_changes(repo_root, cfg, patch)
        result["apply"] = applied

        # Validate build & tests
        validation = validator.run_tests(repo_root, cfg)
        result["validation"] = validation

        # Rollback if tests failed
        if not validation.get("passed") and not args.dry_run:
            patch_applier.rollback(repo_root, applied)
            result["rolled_back"] = True

    # Write report
    reporter.write_report(repo_root, result, cfg)

    print(json.dumps({"report": cfg.get("paths", {}).get("report_path", "apr-report.json"), "changes": len(patch.get("changes", []))}, indent=2))


if __name__ == "__main__":
    main()
