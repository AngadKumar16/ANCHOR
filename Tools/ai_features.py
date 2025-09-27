#!/usr/bin/env python3
"""
Tools/ai_features.py

Behavior:
 - Read plan.md (top-level). Each non-empty line is a feature/task.
 - If backend not present (no ./backend dir or common backend files), create a minimal FastAPI backend.
 - Otherwise, for each feature not found in repo text, create a SwiftUI View stub under App/Features/ or Sources/.
 - Flags: --dry-run, --commit, --debug

Usage:
  python3 Tools/ai_features.py [--dry-run] [--commit] [--debug]
"""
from __future__ import annotations
import argparse
import os
import re
import subprocess
import time
from pathlib import Path
from typing import List

HOME = str(Path.home())
DEBUG_LOG = os.path.join(HOME, ".ai-fix-issues", "features.log")
os.makedirs(os.path.dirname(DEBUG_LOG), exist_ok=True)

def log(msg: str, debug: bool = False):
    print(msg)
    if debug:
        try:
            with open(DEBUG_LOG, "a", encoding="utf8") as f:
                f.write(time.strftime("%Y-%m-%d %H:%M:%S ") + msg + "\n")
        except Exception:
            pass

def run_cmd(cmd: List[str], input_text: str = None, cwd: str = None):
    try:
        p = subprocess.run(cmd, input=input_text, text=True, capture_output=True, check=False, cwd=cwd)
        return p.returncode, p.stdout or "", p.stderr or ""
    except Exception as e:
        return 1, "", str(e)

def load_plan(path: str = "plan.md") -> List[str]:
    if not os.path.exists(path):
        return []
    items = []
    with open(path, "r", encoding="utf8") as f:
        for raw in f:
            s = raw.strip()
            if not s:
                continue
            # allow bullets like "- do X" or "1. do X"
            m = re.match(r"^[-*\d\.\)]\s*(.+)", s)
            items.append(m.group(1).strip() if m else s)
    return items

def repo_has_backend() -> bool:
    # detect common backend presence: backend dir or requirements, app.py, server, Dockerfile
    candidates = ["backend", "server", "api", "app.py", "requirements.txt", "backend/app.py", "backend/Dockerfile"]
    for c in candidates:
        if os.path.exists(c):
            return True
    # also quick grep for "FastAPI" or "uvicorn" or "Vapor" etc
    rc, out, err = run_cmd(["grep", "-R", "-n", "--exclude-dir=.git", "FastAPI\\|uvicorn\\|Vapor\\|django\\|flask", "."])
    if rc == 0 and out.strip():
        return True
    return False

def ensure_backend(dry_run: bool, debug: bool) -> List[str]:
    created = []
    if repo_has_backend():
        log("Backend appears present in repo; skipping backend scaffolding.", debug)
        return created
    log("Backend not detected. Creating minimal FastAPI scaffold under ./backend/", debug)
    if dry_run:
        created = ["backend/ (would create)", "backend/app.py", "backend/requirements.txt", "backend/Dockerfile"]
        for p in created: log("[dry-run] " + p, debug)
        return created

    os.makedirs("backend", exist_ok=True)
    app_py = """from fastapi import FastAPI

app = FastAPI()

@app.get("/")
async def root():
    return {"status": "ok", "msg": "Backend running"}
"""
    reqs = "fastapi\nuvicorn[standard]\n"
    dockerfile = """FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
"""
    with open("backend/app.py", "w", encoding="utf8") as f:
        f.write(app_py)
    with open("backend/requirements.txt", "w", encoding="utf8") as f:
        f.write(reqs)
    with open("backend/Dockerfile", "w", encoding="utf8") as f:
        f.write(dockerfile)
    created = ["backend/app.py", "backend/requirements.txt", "backend/Dockerfile"]
    for p in created: log("Created " + p, debug)
    return created

def feature_tokens(feature: str) -> List[str]:
    words = re.findall(r"[A-Za-z0-9_]+", feature)
    tokens = [w.lower() for w in words if len(w) >= 4]
    if not tokens:
        tokens = [w.lower() for w in words][:2]
    return tokens[:3]

def feature_present_in_repo(feature: str) -> bool:
    tokens = feature_tokens(feature)
    if not tokens:
        return False
    # search for tokens using grep (exclude .git and DerivedData)
    for t in tokens:
        rc, out, err = run_cmd(["grep", "-R", "-n", "--exclude-dir=.git", "--exclude-dir=DerivedData", t, "."])
        if rc == 0 and out.strip():
            return True
    return False

def make_swiftui_stub(feature: str) -> str:
    # create a safe Swift file name from the feature
    base = re.sub(r"[^A-Za-z0-9]", "", feature.title().replace(" ", "")) or "FeatureView"
    if not base.endswith("View"):
        base = base + "View"
    filename = f"App/Features/{base}.swift"
    # contents: a minimal SwiftUI view
    contents = f"""import SwiftUI

// Auto-generated stub for feature: {feature}
struct {base}: View {{
    var body: some View {{
        VStack {{
            Text("{feature}")
                .font(.headline)
                .padding()
            Text("This is an AI-generated stub. Implement UI here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }}
    }}
}}

#if DEBUG
struct {base}_Preview: PreviewProvider {{
    static var previews: some View {{ {base}() }}
}}
#endif
"""
    return filename, contents

def write_file_with_backup(path: str, contents: str, debug: bool) -> None:
    if os.path.exists(path):
        ts = int(time.time())
        bak = f"{path}.bak.{ts}"
        try:
            os.replace(path, bak)
            log(f"Existing file {path} moved to {bak}", debug)
        except Exception as e:
            log(f"Could not backup {path}: {e}", debug)
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "w", encoding="utf8") as f:
        f.write(contents)
    log(f"Wrote {path}", debug)

def implement_frontend_features(features: List[str], dry_run: bool, debug: bool):
    created = []
    # ensure base dir exists
    suggestions_dir = None
    for candidate in ["App/Features", "Sources", "App"]:
        if os.path.exists(candidate):
            suggestions_dir = candidate
            break
    if suggestions_dir is None:
        suggestions_dir = "App/Features"
    for feature in features:
        if feature_present_in_repo(feature):
            log(f"Feature already present in repo (skipping): {feature}", debug)
            continue
        filename, contents = make_swiftui_stub(feature)
        # prefer to place under suggestions_dir
        if suggestions_dir != "App/Features" and filename.startswith("App/Features/"):
            filename = filename.replace("App/Features", suggestions_dir, 1)
        if dry_run:
            log(f"[dry-run] Would create frontend stub: {filename}", debug)
            created.append(filename + " (dry-run)")
        else:
            write_file_with_backup(filename, contents, debug)
            created.append(filename)
    return created

def git_commit(files: List[str], msg: str, debug: bool) -> bool:
    if not files:
        log("No files to commit.", debug)
        return False
    cmd = ["git", "add"] + files
    rc, out, err = run_cmd(cmd)
    if rc != 0:
        log(f"git add failed: {err}", debug)
        return False
    rc, out, err = run_cmd(["git", "commit", "-m", msg])
    if rc != 0:
        log(f"git commit failed: {err}", debug)
        return False
    log("Committed changes: " + msg, debug)
    return True

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", help="Do not write files")
    parser.add_argument("--commit", action="store_true", help="git add & commit changes")
    parser.add_argument("--debug", action="store_true", help="Write debug log")
    args = parser.parse_args()

    dry = args.dry_run
    do_commit = args.commit
    debug = args.debug

    plan = load_plan()
    if not plan:
        log("plan.md not found or empty. Nothing to do.", debug)
        return

    log(f"Loaded plan.md with {len(plan)} items.", debug)

    created_files = []

    # Step 1: ensure backend exists first. If not present, create it and stop (so that next loop runs with backend present)
    if not repo_has_backend():
        log("Backend not present — creating backend scaffold first.", debug)
        new_backend = ensure_backend(dry, debug)
        created_files.extend(new_backend)
        # once backend created, we return (or continue to add frontend as well)
        # We'll continue to frontend creation after backend is created so user gets both in one run.
    else:
        log("Backend already exists; skipping backend creation.", debug)

    # Step 2: for any plan items that are not explicitly backend tasks, create frontend stubs if missing
    # Consider an item as backend if it includes keyword 'backend', 'api', 'server', 'database', 'db', 'auth', 'login', 'endpoint'
    backend_keywords = {"backend", "api", "server", "database", "db", "auth", "login", "endpoint", "graphql", "rest"}
    frontend_candidates = []
    for item in plan:
        low = item.lower()
        if any(k in low for k in backend_keywords):
            log(f"Item looks like backend task: {item}", debug)
            # if backend missing, skip here because ensure_backend already created it
            if repo_has_backend():
                log(f" - backend believed present; skipping adding backend-specific code for: {item}", debug)
            else:
                log(f" - backend not present; backend scaffold created earlier.", debug)
            continue
        # else treat as frontend feature
        frontend_candidates.append(item)

    if frontend_candidates:
        log(f"Creating frontend stubs for {len(frontend_candidates)} items (if missing).", debug)
        new_front = implement_frontend_features(frontend_candidates, dry, debug)
        created_files.extend(new_front)
    else:
        log("No frontend items found in plan.md (or all were backend tasks).", debug)

    if created_files:
        log("Created/modified files:", debug)
        for p in created_files:
            log("  " + p, debug)
        if do_commit and not dry:
            ok = git_commit(created_files, "AI-features: add features from plan.md / backend scaffold", debug)
            if not ok:
                log("Warning: commit failed or nothing staged.", debug)
    else:
        log("No files created. Everything in plan.md appears present.", debug)

if __name__ == "__main__":
    main()
