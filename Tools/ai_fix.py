#!/usr/bin/env python3
"""
Tools/ai_fix.py

Robust AI fixer for Swift projects (Xcode). Designed to:
 - parse xcodebuild logs
 - identify issues & missing-symbols
 - create minimal stubs for missing symbols
 - run a multi-step AI workflow: analyze -> plan -> rewrite -> self-check
 - persist fixes per-issue in ~/.ai-fix-issues/issues.json
 - safe guards: dry-run, backups, caching, max attempts
 - fallback model backends: Gemini (google.generativeai) -> OpenAI -> gh copilot CLI

Usage:
  python3 Tools/ai_fix.py path/to/build.log [--dry-run] [--commit] [--stubs-only]
                                      [--max-excerpt=N] [--mark-resolved=ID] [--debug]
"""

from __future__ import annotations
import argparse
import json
import os
import re
import sys
import hashlib
import time
import shutil
import subprocess
from pathlib import Path
from typing import Dict, Any, List, Optional, Set, Tuple
from difflib import unified_diff

# Optional SDKs (handled gracefully)
try:
    import google.generativeai as genai  # type: ignore
except Exception:
    genai = None

try:
    import openai  # type: ignore
except Exception:
    openai = None

# ---------- Config and global paths ----------
HOME = str(Path.home())
ISSUES_DIR = os.path.join(HOME, ".ai-fix-issues")
ISSUES_DB = os.path.join(ISSUES_DIR, "issues.json")
CACHE_PATH = os.path.join(ISSUES_DIR, "cache.json")
LOG_PATH = os.path.join(ISSUES_DIR, "log.txt")

os.makedirs(ISSUES_DIR, exist_ok=True)

# ---------- Utilities ----------
def log_debug(enabled: bool, *args):
    if not enabled:
        return
    try:
        with open(LOG_PATH, "a", encoding="utf8") as f:
            f.write(time.strftime("%Y-%m-%dT%H:%M:%S ") + " ".join(map(str, args)) + "\n")
    except Exception:
        pass

def sha256(s: str) -> str:
    return hashlib.sha256((s or "").encode("utf8")).hexdigest()

def safe_read(path: str) -> str:
    try:
        with open(path, "r", encoding="utf8") as f:
            return f.read()
    except Exception:
        return ""

def safe_write(path: str, content: str):
    with open(path, "w", encoding="utf8") as f:
        f.write(content)

def run_cmd(cmd: List[str], input_text: Optional[str] = None, timeout: Optional[int] = None) -> Tuple[int, str, str]:
    try:
        proc = subprocess.run(cmd, input=input_text, text=True, capture_output=True, check=False, timeout=timeout)
        return proc.returncode, proc.stdout or "", proc.stderr or ""
    except subprocess.TimeoutExpired as e:
        return 124, e.stdout or "", (e.stderr or "") + f"\nTimeout after {timeout}s"
    except Exception as e:
        return 1, "", str(e)

# ---------- CLI args ----------
parser = argparse.ArgumentParser(description="AI fixer (Python).")
parser.add_argument("logfile", nargs="?", help="path/to/build.log")
parser.add_argument("--dry-run", action="store_true")
parser.add_argument("--commit", action="store_true")
parser.add_argument("--stubs-only", action="store_true")
parser.add_argument("--max-excerpt", type=int, default=8000)
parser.add_argument("--mark-resolved", type=str, default=None)
parser.add_argument("--debug", action="store_true")
parser.add_argument("--max-ai-attempts", type=int, default=3)
parser.add_argument("--max-issue-reuse", type=int, default=20, help="max times to auto-reapply stored fix before requiring manual review")
args = parser.parse_args()

if not args.logfile:
    print("Usage: python3 ai_fix.py path/to/build.log [--dry-run] [--commit] [--stubs-only] [--max-excerpt=N] [--mark-resolved=ID] [--debug]")
    sys.exit(0)

LOGFILE = args.logfile
DRY_RUN = args.dry_run
DO_COMMIT = args.commit
STUBS_ONLY = args.stubs_only
MAX_EXCERPT = args.max_excerpt
MARK_RESOLVED_ID = args.mark_resolved
DEBUG = args.debug
MAX_AI_ATTEMPTS = args.max_ai_attempts
MAX_ISSUE_REUSE = args.max_issue_reuse

log_debug(DEBUG, "Starting run", {"logfile": LOGFILE, "dry_run": DRY_RUN, "commit": DO_COMMIT, "stubs_only": STUBS_ONLY, "max_excerpt": MAX_EXCERPT})

# ---------- Load build log ----------
if not os.path.exists(LOGFILE):
    print("Log file not found:", LOGFILE)
    sys.exit(1)
raw_log = safe_read(LOGFILE)

# ---------- Load DBs ----------
def load_json(path: str) -> Dict[str, Any]:
    try:
        return json.loads(safe_read(path) or "{}")
    except Exception:
        return {}

issues_db: Dict[str, Any] = load_json(ISSUES_DB)
cache: Dict[str, Any] = load_json(CACHE_PATH)

if MARK_RESOLVED_ID:
    if MARK_RESOLVED_ID in issues_db:
        del issues_db[MARK_RESOLVED_ID]
        safe_write(ISSUES_DB, json.dumps(issues_db, indent=2))
        print("Marked resolved and deleted stored solution for issue:", MARK_RESOLVED_ID)
    else:
        print("No issue with id", MARK_RESOLVED_ID, "found.")
    sys.exit(0)

# ---------- Issue detection & fuzzy matching ----------
def token_overlap(a: str, b: str) -> float:
    if not a or not b:
        return 0.0
    ta = set(re.findall(r"\w+", a.lower()))
    tb = set(re.findall(r"\w+", b.lower()))
    if not ta or not tb:
        return 0.0
    return len(ta & tb) / min(len(ta), len(tb))

def same_issue_sig(a: str, b: str) -> bool:
    if not a or not b:
        return False
    if a in b or b in a:
        return True
    return token_overlap(a, b) >= 0.5

def detect_issues_from_log(log_contents: str) -> List[Dict[str, str]]:
    issues: List[Dict[str, str]] = []
    seen: Set[str] = set()
    file_err_re = re.compile(r"([\/\w\-\._]+\.swift:\d+:(?:.*?)\b(?:error|fatal error|note|warning)\b.*)", re.IGNORECASE)
    for m in file_err_re.finditer(log_contents):
        line = m.group(1).strip()
        short = re.sub(r"\s+", " ", line)[:400]
        if short in seen:
            continue
        seen.add(short)
        issues.append({"id": sha256(short), "signature": short, "sample": line})
    for m in re.finditer(r"cannot find '([^']+)' in scope", log_contents):
        sym = m.group(1)
        sig = f"cannot find {sym} in scope"
        if sig in seen: continue
        seen.add(sig)
        issues.append({"id": sha256(sig), "signature": sig, "sample": sig})
    for m in re.finditer(r"use of unresolved identifier '([^']+)'", log_contents):
        sym = m.group(1)
        sig = f"use of unresolved identifier {sym}"
        if sig in seen: continue
        seen.add(sig)
        issues.append({"id": sha256(sig), "signature": sig, "sample": sig})
    log_debug(DEBUG, "Detected issue signatures", [i["signature"] for i in issues])
    return issues

current_issues = detect_issues_from_log(raw_log)

# Map stored -> current via fuzzy
current_matches: Dict[str, Dict[str, str]] = {}
for sid, stored in list(issues_db.items()):
    matched = None
    for cur in current_issues:
        if same_issue_sig(stored.get("signature", ""), cur["signature"]):
            matched = cur
            break
    if matched:
        current_matches[sid] = matched

# Auto-forget stored issues not matching any current
for sid in list(issues_db.keys()):
    if sid not in current_matches:
        log_debug(DEBUG, "Auto-forgetting stored issue", sid, issues_db[sid].get("signature"))
        del issues_db[sid]

# Build file -> lines map from log
file_line_re = re.compile(r"([\/\w\-\._]+\.swift):(\d+):")
file_lines_map: Dict[str, Set[int]] = {}
for m in file_line_re.finditer(raw_log):
    f = m.group(1)
    ln = int(m.group(2))
    file_lines_map.setdefault(f, set()).add(ln)
unique_files = list(file_lines_map.keys())
if not unique_files:
    print("No failing .swift files detected in build log.")

# ---------- Create minimal stubs ----------
def ensure_stubs(log_contents: str) -> List[str]:
    missing_re = re.compile(r"cannot find '([^']+)' in scope")
    missing = set(m.group(1) for m in missing_re.finditer(log_contents))
    created: List[str] = []
    for sym in missing:
        safe_name = re.sub(r"[^A-Za-z0-9_]", "", sym)
        if not safe_name:
            continue
        # quick grep to see if symbol exists anywhere
        rc, out, err = run_cmd(["grep", "-R", "--line-number", "--exclude-dir=DerivedData", "--exclude-dir=node_modules", "-n", safe_name, "."])
        if rc == 0 and out.strip():
            continue
        target_candidates = [os.path.join("ANCHOR","Views","Components"), "Sources", "."]
        target_dir = next((d for d in target_candidates if os.path.exists(d)), "Sources")
        os.makedirs(target_dir, exist_ok=True)
        fname = os.path.join(target_dir, f"{safe_name}.swift")
        if os.path.exists(fname):
            continue
        if safe_name.endswith("Style"):
            code = f"import SwiftUI\n\nstruct {safe_name}: ButtonStyle {{ func makeBody(configuration: Configuration) -> some View {{ configuration.label }} }}\n"
        elif safe_name.endswith("Service") or safe_name.endswith("Manager"):
            code = f"import Foundation\n\nfinal class {safe_name} {{ static let shared = {safe_name}(); private init() {{}} }}\n"
        elif safe_name.endswith("View"):
            code = f"import SwiftUI\n\nstruct {safe_name}: View {{ var body: some View {{ Text(\"{safe_name} stub\") }} }}\n"
        else:
            code = f"// Auto-generated minimal stub for {safe_name}\nimport Foundation\n\nstruct {safe_name} {{}}\n"
        try:
            safe_write(fname, code)
            created.append(fname)
            log_debug(DEBUG, "Created stub", fname)
        except Exception as e:
            print("Failed to write stub", fname, e)
    return created

created_stubs = ensure_stubs(raw_log)
changed_files: List[str] = []
if created_stubs:
    changed_files.extend(created_stubs)
if STUBS_ONLY:
    print("Stubs created:", created_stubs)
    safe_write(ISSUES_DB, json.dumps(issues_db, indent=2))
    sys.exit(0)

# ---------- Model backend wrapper ----------
# 1) Try Gemini via google.generativeai if available
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY") or os.environ.get("GENAI_KEY") or os.environ.get("GENAI_API_KEY")
OPENAI_KEY = os.environ.get("OPENAI_API_KEY") or os.environ.get("OPENAI_KEY")
USE_GEMINI = genai is not None and (GEMINI_API_KEY is not None or os.environ.get("GENAI_LOCAL") == "1")
USE_OPENAI = openai is not None and bool(OPENAI_KEY)

if genai is not None and GEMINI_API_KEY:
    try:
        genai.configure(api_key=GEMINI_API_KEY)
    except Exception:
        # some local setups might differ; ignore here
        pass

def call_gemini_chat(system: str, user: str, model: str = "gemini-1.5-pro", max_output_tokens: int = 1600, temperature: float = 0.0) -> str:
    if genai is None:
        raise RuntimeError("google.generativeai SDK not installed")
    # Try chat completion (API can differ between versions, we try several affordances)
    try:
        # first try chat.completions.create
        if hasattr(genai, "chat"):
            resp = genai.chat.completions.create(model=model, messages=[{"role":"system","content":system},{"role":"user","content":user}], temperature=temperature, max_output_tokens=max_output_tokens)
            # resp structure may vary
            if isinstance(resp, dict):
                return resp.get("candidates", [{}])[0].get("content", "")
            return getattr(resp, "candidates", [{}])[0].get("content", "")
        # fallback: generate_text / generate
        if hasattr(genai, "generate_text"):
            r = genai.generate_text(model=model, prompt=system + "\n\n" + user, max_output_tokens=max_output_tokens, temperature=temperature)
            return getattr(r, "text", "") or str(r)
        if hasattr(genai, "generate"):
            r = genai.generate(model=model, prompt=system + "\n\n" + user, max_output_tokens=max_output_tokens, temperature=temperature)
            return getattr(r, "candidates", [{}])[0].get("content", "")
    except Exception as e:
        log_debug(DEBUG, "Gemini call failed", str(e))
        raise
    raise RuntimeError("No recognized genai API surface present")

def call_openai_chat(system: str, user: str, model: str = "gpt-4.1", max_tokens: int = 1500, temperature: float = 0.0) -> str:
    if openai is None:
        raise RuntimeError("OpenAI SDK not installed")
    try:
        messages = [{"role":"system","content":system},{"role":"user","content":user}]
        resp = openai.ChatCompletion.create(model=model, messages=messages, max_tokens=max_tokens, temperature=temperature)
        return resp.choices[0].message["content"]
    except Exception as e:
        log_debug(DEBUG, "OpenAI call failed", str(e))
        raise

def call_copilot_cli(prompt: str, timeout: int = 30) -> str:
    # fall back to GitHub Copilot CLI if available
    rc, out, err = run_cmd(["gh", "copilot", "suggest"], input_text=prompt, timeout=timeout)
    if rc == 0 and out:
        return out
    # Some gh versions output to stderr
    if rc == 0 and err:
        return err
    return ""

def model_chat(system: str, user: str, prefer: str = "gemini", max_out: int = 2000, temp: float = 0.0) -> str:
    """
    Unified model interface. Try local Gemini -> OpenAI -> Copilot CLI.
    """
    # Try Gemini
    if use_gemini_backend():
        try:
            return call_gemini_chat(system, user, max_output_tokens=max_out, temperature=temp)
        except Exception as e:
            log_debug(DEBUG, "Gemini backend failed, falling back", str(e))
    if use_openai_backend():
        try:
            return call_openai_chat(system, user, model=os.environ.get("OPENAI_MODEL","gpt-4.1"), max_tokens=max_out, temperature=temp)
        except Exception as e:
            log_debug(DEBUG, "OpenAI backend failed, falling back", str(e))
    # else fallback to copilot CLI
    try:
        cp_out = call_copilot_cli(system + "\n\n" + user)
        if cp_out:
            return cp_out
    except Exception as e:
        log_debug(DEBUG, "Copilot CLI call failed", str(e))
    return ""

def use_gemini_backend() -> bool:
    return genai is not None and (GEMINI_API_KEY is not None or os.environ.get("GENAI_LOCAL") == "1")

def use_openai_backend() -> bool:
    return openai is not None and (OPENAI_KEY is not None)

# ---------- AI multi-step loop ----------
def build_context_for_file(file_path: str) -> str:
    file_orig = safe_read(file_path)
    lines_set = file_lines_map.get(file_path, set())
    if not lines_set:
        return "\n".join(f"{i+1}: {l}" for i, l in enumerate(file_orig.splitlines()[:200]))
    lines = file_orig.splitlines()
    want = set()
    for ln in lines_set:
        for i in range(max(0, ln-1-8), min(len(lines)-1, ln-1+8)+1):
            want.add(i)
    return "\n".join(f"{i+1}: {lines[i] if i < len(lines) else ''}" for i in sorted(want))

def extract_json_fragment(text: str) -> Optional[dict]:
    m = re.search(r"(\{[\s\S]*\})", text)
    if not m:
        return None
    try:
        return json.loads(m.group(1))
    except Exception:
        # try to sanitize: replace single quotes -> double quotes, remove trailing commas
        t = m.group(1).replace("'", '"')
        t = re.sub(r",\s*}", "}", t)
        try:
            return json.loads(t)
        except Exception:
            return None

def ai_analyze_then_fix(excerpt: str, context_snippet: str, original_content: str, debug: bool=False) -> Optional[str]:
    """
    Steps:
     1) Analysis: ask model to explain and produce a plan (prefer JSON).
     2) Rewrite: ask model to produce fixed file (only file content).
     3) Self-check: ask model whether candidate resolves errors (prefer JSON).
     Loop up to MAX_AI_ATTEMPTS, augmenting plan with critique.
    """
    # 1) Analysis
    analysis_system = "You are a Swift build error analyst. Be concise and precise."
    analysis_user = (
        "Task:\n"
        "  1) Read the build log excerpt and the file context.\n"
        "  2) Identify the likely root cause(s) of the compile errors shown.\n"
        "  3) Produce a concise, ordered plan of changes to fix the problem(s).\n\n"
        "Return ONLY a JSON object with keys: {\"explanation\": string, \"plan\": [string, ...]}\n\n"
        "Build excerpt:\n---\n" + excerpt[:MAX_EXCERPT] + "\n---\n\n"
        "Context snippet (near failing lines):\n---\n" + context_snippet[:MAX_EXCERPT] + "\n---\n\n"
        "File head (truncated):\n---\n" + original_content[:MAX_EXCERPT] + "\n---\n"
    )

    analysis_out = model_chat(analysis_system, analysis_user, max_out=1200, temp=0.0)
    log_debug(DEBUG, "Analysis_out", analysis_out[:2000])
    obj = extract_json_fragment(analysis_out)
    plan_list: List[str] = []
    explanation: str = ""
    if obj:
        explanation = obj.get("explanation", "") or ""
        plan_list = obj.get("plan", []) or []
        if isinstance(plan_list, str):
            plan_list = [plan_list]
    else:
        # fallback parse: collect enumerated lines
        lines = [l.strip() for l in analysis_out.splitlines() if l.strip()]
        for line in lines:
            if re.match(r"^\d+[\.\)]\s+", line) or re.match(r"^[-*]\s+", line):
                plan_list.append(re.sub(r"^\d+[\.\)]\s*|^[-*]\s*", "", line))
        explanation = "\n".join(lines[:3])
    if not plan_list:
        # as last resort, use the raw analysis text as single plan entry
        if analysis_out.strip():
            plan_list = [analysis_out.strip()]
        else:
            log_debug(DEBUG, "No plan produced")
            return None

    plan_text = "\n".join(f"- {p}" for p in plan_list)

    # 2) Rewrite attempts
    for attempt in range(1, MAX_AI_ATTEMPTS + 1):
        log_debug(DEBUG, f"Rewrite attempt {attempt}")
        rewrite_system = "You are a careful Swift refactoring assistant. Keep changes minimal."
        rewrite_user = (
            "Apply this plan to the original file. Output ONLY the full corrected Swift file contents and NOTHING else.\n\n"
            "Plan:\n" + plan_text + "\n\n"
            "Original file:\n---\n" + original_content + "\n---\n\n"
            "Requirements:\n"
            " - Preserve license headers / top-of-file comments unless they must be changed.\n"
            " - Prefer minimal diffs; do not rewrite unrelated code.\n            "
        )
        fix_out = model_chat(rewrite_system, rewrite_user, max_out=4000, temp=0.0)
        fixed_candidate = fix_out.strip()
        if not fixed_candidate:
            log_debug(DEBUG, "Empty fix_out; continuing")
            continue

        # 3) Self-check
        check_system = "You are a Swift build verifier. Be direct and accurate."
        check_user = (
            "Given this build log excerpt and a candidate fixed file, determine whether the reported compile errors would be resolved.\n"
            "Return ONLY a JSON object: {\"ok\": true|false, \"explanation\": \"...\"}\n\n"
            "Build excerpt:\n---\n" + excerpt[:MAX_EXCERPT] + "\n---\n\n"
            "Candidate fixed file (truncated):\n---\n" + fixed_candidate[:MAX_EXCERPT] + "\n---\n"
        )
        check_out = model_chat(check_system, check_user, max_out=1000, temp=0.0)
        log_debug(DEBUG, "Self-check out", check_out[:2000])
        chk = extract_json_fragment(check_out)
        ok = False
        critique_text = ""
        if chk:
            ok = bool(chk.get("ok"))
            critique_text = chk.get("explanation", "") or ""
        else:
            # heuristics: look for 'ok', 'resolved', 'fix' tokens
            critique_text = check_out.strip()
            if re.search(r"\b(true|ok|resolved|likely resolved|should fix)\b", check_out, re.IGNORECASE):
                ok = True
            else:
                ok = False

        if ok:
            return fixed_candidate
        else:
            # augment plan with critique and retry
            plan_text += "\n\n# Critique & notes:\n" + (critique_text or check_out)
            log_debug(DEBUG, "Self-check failed; augmenting plan and retrying", {"attempt": attempt})
            time.sleep(0.5)
    # All attempts exhausted
    log_debug(DEBUG, "AI failed to produce a verified fix after attempts")
    return None

# ---------- Main per-file flow ----------
for file_path in unique_files:
    if not os.path.exists(file_path):
        print("File missing on disk, skipping", file_path)
        continue
    print("\n=== Processing", file_path)
    log_debug(DEBUG, "Processing file", file_path)

    content = safe_read(file_path)
    if "// DO NOT MODIFY BY AI" in content:
        print("Skipping file due to DO NOT MODIFY BY AI marker:", file_path)
        log_debug(DEBUG, "Skip marker found", file_path)
        continue

    excerpt_pattern = re.compile(r"(?:^|\n)([^\n]*" + re.escape(file_path) + r"[^\n]*)(?:\n|$)")
    found_lines = [m.group(1) for m in excerpt_pattern.finditer(raw_log)]
    excerpt = ("\n".join(found_lines) if found_lines else raw_log[:MAX_EXCERPT])[:MAX_EXCERPT]

    # 1) Re-apply stored solution if suitable
    applied_stored = False
    for cur in current_issues:
        stored_id = None
        for sid, s in issues_db.items():
            if same_issue_sig(s.get("signature", ""), cur["signature"]):
                stored_id = sid
                break
        if not stored_id:
            continue
        stored = issues_db.get(stored_id)
        if not stored or not stored.get("files") or not stored["files"].get(file_path):
            continue
        stored_content = stored["files"][file_path]
        if not stored_content:
            continue
        if stored_content == content:
            print(f"Stored solution for issue {stored_id} already present in {file_path} (no-op).")
            applied_stored = True
            break
        # avoid infinite reuse loop
        if stored.get("reuseCount", 0) >= MAX_ISSUE_REUSE:
            print(f"Stored solution for issue {stored_id} reached reuse limit; skipping and marking for manual review.")
            continue
        if DRY_RUN:
            print(f"[dry-run] Would re-apply stored solution for issue {stored_id} to {file_path}")
            applied_stored = True
            break
        # apply stored solution
        backup = f"{file_path}.bak.{int(time.time())}"
        try:
            shutil.copyfile(file_path, backup)
        except Exception:
            pass
        try:
            safe_write(file_path, stored_content)
            print(f"Re-applied stored solution for issue {stored_id} to {file_path}")
            stored["reuseCount"] = stored.get("reuseCount", 0) + 1
            stored["lastAppliedAt"] = time.strftime("%Y-%m-%dT%H:%M:%S")
            changed_files.append(file_path)
            log_debug(DEBUG, "Applied stored solution", stored_id, file_path)
        except Exception as e:
            print("Failed to write stored solution", e)
        applied_stored = True
        break
    if applied_stored:
        continue

    # 2) No stored -> ask AI
    context_snippet = build_context_for_file(file_path)
    fixed = ai_analyze_then_fix(excerpt, context_snippet, content, debug=DEBUG)
    if fixed is None:
        print("AI produced no verified fix for", file_path)
        continue

    fixed_hash = sha256(fixed)
    cache_key = os.path.realpath(file_path)
    if cache.get(cache_key) and cache[cache_key].get("lastHash") == fixed_hash:
        print("AI returned identical content as last time for", file_path, "- skipping apply to avoid loop.")
        log_debug(DEBUG, "AI duplicate detected", file_path)
        continue

    if fixed == content:
        print("AI output matches original file (no-op).")
        cache[cache_key] = {"lastHash": fixed_hash, "triedAt": time.strftime("%Y-%m-%dT%H:%M:%S")}
        continue

    # Dry-run: stage into issues_db
    if DRY_RUN:
        print("[dry-run] Would overwrite:", file_path)
        cache[cache_key] = {"lastHash": fixed_hash, "triedAt": time.strftime("%Y-%m-%dT%H:%M:%S")}
        for cur in current_issues:
            if same_issue_sig(cur["signature"], fixed) or same_issue_sig(cur["signature"], content) or file_path in excerpt:
                issues_db.setdefault(cur["id"], {"id": cur["id"], "signature": cur["signature"], "files": {}, "createdAt": time.strftime("%Y-%m-%dT%H:%M:%S")})
                issues_db[cur["id"]]["files"][file_path] = fixed
                log_debug(DEBUG, "Dry-run: staged stored solution", cur["id"], file_path)
        continue

    # apply fix
    backup = f"{file_path}.bak.{int(time.time())}"
    try:
        shutil.copyfile(file_path, backup)
    except Exception:
        pass
    try:
        safe_write(file_path, fixed)
        print("Applied AI fix to", file_path)
        changed_files.append(file_path)
        cache[cache_key] = {"lastHash": fixed_hash, "triedAt": time.strftime("%Y-%m-%dT%H:%M:%S"), "backup": backup}
        # save fix to issues_db
        for cur in current_issues:
            if same_issue_sig(cur["signature"], fixed) or same_issue_sig(cur["signature"], content) or file_path in excerpt:
                issues_db.setdefault(cur["id"], {"id": cur["id"], "signature": cur["signature"], "files": {}, "createdAt": time.strftime("%Y-%m-%dT%H:%M:%S")})
                issues_db[cur["id"]]["files"][file_path] = fixed
                issues_db[cur["id"]]["savedAt"] = time.strftime("%Y-%m-%dT%H:%M:%S")
                log_debug(DEBUG, "Saved solution for issue", cur["id"], "file", file_path)
    except Exception as e:
        print("Failed to write fixed file", e)
        try:
            shutil.copyfile(backup, file_path)
        except Exception:
            pass

# ---------- Persist DB & cache ----------
try:
    safe_write(ISSUES_DB, json.dumps(issues_db, indent=2))
except Exception as e:
    log_debug(DEBUG, "Failed to write issues db", str(e))
try:
    safe_write(CACHE_PATH, json.dumps(cache, indent=2))
except Exception as e:
    log_debug(DEBUG, "Failed to write cache", str(e))

# ---------- Optional commit ----------
if not DRY_RUN and DO_COMMIT and changed_files:
    try:
        rc, out, err = run_cmd(["git", "add"] + changed_files)
        rc, out, err = run_cmd(["git", "commit", "-m", f"ai-fix: automated fixes for {os.path.basename(LOGFILE)}"])
        print("Committed fixes (if any).")
    except Exception as e:
        print("Git commit failed", e)

# ---------- Summary ----------
print("")
if changed_files:
    print("AI made changes to files:")
    for f in changed_files:
        print(" -", f)
else:
    print("AI did not modify any files on this pass.")
print("Stored issue IDs:", list(issues_db.keys()))
log_debug(DEBUG, "Run complete. changedFiles:", changed_files, "storedIssues", list(issues_db.keys()))
sys.exit(0)
