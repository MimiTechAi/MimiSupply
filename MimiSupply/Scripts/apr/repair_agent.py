#!/usr/bin/env python3
import argparse
import json
import os
from pathlib import Path
import re
from urllib import request, error

CONFIG_DEFAULT = "apr.config.json"


def load_config(repo_root: Path, config_path: str = CONFIG_DEFAULT) -> dict:
    cfg_path = repo_root / config_path
    with cfg_path.open("r", encoding="utf-8") as f:
        return json.load(f)


def build_prompt(failures: dict, contexts: dict) -> str:
    prompt = [
        "You are an Automated Program Repair agent for a Swift iOS app.",
        "Given failing tests and compiler errors, propose minimal patches.",
        "Constraints:",
        "- Keep changes minimal and targeted.",
        "- Preserve style; add comments only when necessary.",
        "- Do not modify project.pbxproj or configuration files.",
        "- Prefer fixes in app or test code.",
        "- Ensure code compiles and tests pass.",
        "\nFailures:",
        json.dumps(failures, ensure_ascii=False, indent=2),
        "\nContext files (subset):",
        "[omitted in prompt preview]",
        f"Context files provided: {len(contexts) if isinstance(contexts, dict) else 0}",
        "\nOutput strictly the following JSON schema and nothing else:",
        '{"changes": [{"path": "relative/path/to/file.swift", "content": "<ENTIRE NEW FILE CONTENT>"}]}'
    ]
    return "\n".join(prompt)


def generate_patch(repo_root: Path, cfg: dict, failures: dict, contexts: dict) -> dict:
    provider = cfg.get("provider", "set_me")
    model = cfg.get("model", "set_me")
    api_env = cfg.get("api_env_var", "OPENAI_API_KEY")
    thinking_cfg = cfg.get("thinking", {}) or {}
    thinking_type = str(thinking_cfg.get("type", "")).lower()
    thinking_enabled = thinking_type != "disabled"

    # Safety: do not call any external LLM until provider/model configured and env key exists
    if provider.startswith("set_me") or model.startswith("set_me"):
        return {
            "changes": [],
            "notes": "LLM provider/model not configured. Set 'provider' and 'model' in apr.config.json to enable code generation.",
        }
    if not os.getenv(api_env):
        return {
            "changes": [],
            "notes": f"Environment variable '{api_env}' not set. No patch generated.",
        }

    if provider == "zai":
        return _generate_with_zai(
            model=model,
            api_key=os.getenv(api_env),
            prompt=build_prompt(failures, contexts),
            thinking_enabled=thinking_enabled,
        )

    # Unknown provider: don't call anything, return notice
    return {
        "changes": [],
        "notes": f"Unknown provider '{provider}'. No external call executed.",
    }


def _zai_chat_completion(model: str, api_key: str, messages: list, thinking_enabled: bool = True, stream: bool = False, max_tokens: int = 4096, temperature: float = 0.6) -> str:
    """Call Z.AI chat completions API and return assistant message content as string.

    Docs reference: https://docs.z.ai/guides/llm/glm-4.5#web-development
    Endpoint: POST https://api.z.ai/api/paas/v4/chat/completions
    Headers: Content-Type: application/json, Authorization: Bearer <api-key>
    Body keys: model, messages[], thinking.type ('enabled'|'disabled'), stream, max_tokens, temperature
    """
    url = "https://api.z.ai/api/paas/v4/chat/completions"
    payload = {
        "model": model,
        "messages": messages,
        "thinking": {"type": "enabled" if thinking_enabled else "disabled"},
        "stream": stream,
        "max_tokens": max_tokens,
        "temperature": temperature,
    }
    data = json.dumps(payload).encode("utf-8")
    req = request.Request(url, data=data, method="POST")
    req.add_header("Content-Type", "application/json")
    req.add_header("Authorization", f"Bearer {api_key}")
    try:
        with request.urlopen(req, timeout=60) as resp:
            raw = resp.read().decode("utf-8", errors="ignore")
            obj = json.loads(raw)
            # OpenAI-like schema: choices[0].message.content
            choices = obj.get("choices") or []
            if choices and isinstance(choices, list):
                msg = choices[0].get("message") or {}
                content = msg.get("content")
                if isinstance(content, str):
                    return content
            # Fallback: try 'output_text'
            content = obj.get("output_text")
            if isinstance(content, str):
                return content
            return ""
    except error.HTTPError as e:
        try:
            err_body = e.read().decode("utf-8", errors="ignore")
        except Exception:
            err_body = str(e)
        return json.dumps({"error": f"HTTPError {e.code}", "body": err_body})
    except Exception as e:
        return json.dumps({"error": str(e)})


def _extract_json_object(text: str) -> dict:
    """Attempt to parse a JSON object from text. Returns {} on failure."""
    if not text:
        return {}
    # Direct parse first
    try:
        return json.loads(text)
    except Exception:
        pass
    # Heuristic: find first '{' ... last '}'
    m = re.search(r"\{[\s\S]*\}", text)
    if m:
        try:
            return json.loads(m.group(0))
        except Exception:
            return {}
    return {}


def _generate_with_zai(model: str, api_key: str, prompt: str, thinking_enabled: bool) -> dict:
    messages = [
        {"role": "user", "content": prompt}
    ]
    content = _zai_chat_completion(
        model=model,
        api_key=api_key,
        messages=messages,
        thinking_enabled=thinking_enabled,
        stream=False,
    )
    obj = _extract_json_object(content)
    if obj.get("changes") and isinstance(obj["changes"], list):
        return obj
    # If we couldn't parse valid changes, return note with excerpt for debugging (truncated)
    excerpt = content[:500] if content else ""
    return {
        "changes": [],
        "notes": "Z.AI response did not contain a valid 'changes' JSON array.",
        "response_excerpt": excerpt,
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", default=str(Path(__file__).resolve().parents[2]))
    ap.add_argument("--config", default=CONFIG_DEFAULT)
    ap.add_argument("--failures_json", required=True)
    ap.add_argument("--contexts_json", required=True)
    args = ap.parse_args()

    repo_root = Path(args.repo).resolve()
    cfg = load_config(repo_root, args.config)
    failures = json.loads(Path(args.failures_json).read_text(encoding="utf-8"))
    contexts = json.loads(Path(args.contexts_json).read_text(encoding="utf-8"))

    patch = generate_patch(repo_root, cfg, failures, contexts.get("contexts", {}))
    print(json.dumps(patch, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
