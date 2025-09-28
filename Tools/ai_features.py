#!/usr/bin/env python3
"""
Tools/ai_features.py

- Uses need_work.md (falls back to plan.md) as the queue of things that need work.
- For the first unchecked item, generates:
    - <Feature>View.swift
    - <Feature>ViewModel.swift
- If no backend detected, creates a minimal FastAPI scaffold.
- Flags: --dry-run, --commit, --debug, --force
- Logs debug output to ~/.ai-fix-issues/features.log when --debug is set
- If --commit is used and commit succeeds, marks the need_work item as done.
"""
from __future__ import annotations
import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import List, Tuple

HOME = str(Path.home())
DEBUG_LOG_DIR = os.path.join(HOME, ".ai-fix-issues")
os.makedirs(DEBUG_LOG_DIR, exist_ok=True)
DEBUG_LOG = os.path.join(DEBUG_LOG_DIR, "features.log")

# timeouts (seconds)
SEARCH_TIMEOUT = 6
RUN_CMD_TIMEOUT = 12

def dlog(msg: str, debug: bool = False):
    line = str(msg).rstrip()
    print(line)
    if debug:
        try:
            with open(DEBUG_LOG, "a", encoding="utf8") as f:
                f.write(time.strftime("%Y-%m-%d %H:%M:%S ") + line + "\n")
        except Exception:
            pass

def run_cmd(cmd: List[str], input_text: str = None, cwd: str = None, timeout: int = RUN_CMD_TIMEOUT) -> Tuple[int, str, str]:
    """
    Run a command safely with a timeout. Returns (rc, stdout, stderr).
    """
    try:
        proc = subprocess.run(cmd, input=input_text, text=True, capture_output=True, check=False, cwd=cwd, timeout=timeout)
        return proc.returncode, proc.stdout or "", proc.stderr or ""
    except subprocess.TimeoutExpired:
        return 124, "", "Command timed out"
    except Exception as e:
        return 1, "", str(e)

def search_repo(term: str, timeout: int = SEARCH_TIMEOUT) -> Tuple[int, str, str]:
    """
    Prefer ripgrep (rg) if available for speed. Exclude .git, DerivedData, node_modules.
    """
    rg = shutil.which("rg")
    if rg:
        cmd = [rg, "--line-number", "--hidden", "--glob", "!.git/**", "--glob", "!DerivedData/**", "--glob", "!node_modules/**", "-n", term, "."]
        return run_cmd(cmd, timeout=timeout)
    else:
        cmd = ["grep", "-R", "--line-number", "--exclude-dir=.git", "--exclude-dir=DerivedData", "--exclude-dir=node_modules", "-n", term, "."]
        return run_cmd(cmd, timeout=timeout)

# ---------------- backend helpers ----------------
def repo_has_backend() -> bool:
    candidates = ["backend", "server", "api", "app.py", "requirements.txt", "backend/app.py", "backend/Dockerfile"]
    for c in candidates:
        if os.path.exists(c):
            return True
    rc, out, err = search_repo(r"FastAPI|uvicorn|flask|django|express|Vapor|http.server", timeout=4)
    if rc == 0 and out.strip():
        return True
    return False

def ensure_backend(dry: bool, debug: bool) -> List[str]:
    created = []
    if repo_has_backend():
        dlog("Backend detected; skipping backend creation.", debug)
        return created

    dlog("Backend not detected; will create minimal FastAPI scaffold under ./backend/", debug)
    created = ["backend/", "backend/app.py", "backend/requirements.txt", "backend/Dockerfile"]
    if dry:
        for p in created:
            dlog(f"[dry-run] would create: {p}", debug)
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
CMD [ "uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000" ]
"""
    Path("backend/app.py").write_text(app_py, encoding="utf8")
    Path("backend/requirements.txt").write_text(reqs, encoding="utf8")
    Path("backend/Dockerfile").write_text(dockerfile, encoding="utf8")
    for p in created:
        dlog("Created " + p, debug)
    return created

# ---------------- plan / need_work parsing ----------------
def load_need_work(path: str = "need_work.md") -> Tuple[List[str], str]:
    """
    Return (items, source_path) where items are unchecked list entries from need_work.md.
    Falls back to plan.md if need_work.md doesn't exist.
    """
    preferred = Path(path)
    fallback = Path("plan.md")
    if preferred.exists():
        text = preferred.read_text(encoding="utf8")
        source = str(preferred)
    elif fallback.exists():
        text = fallback.read_text(encoding="utf8")
        source = str(fallback)
    else:
        return [], ""

    unchecked_pattern = re.compile(r'^[\s\-\*\d\.\)]*\[\s*\]\s*(.+)$', re.MULTILINE)
    items = [m.strip() for m in unchecked_pattern.findall(text)]
    if items:
        return items, source

    # fallback: non-empty non-heading lines stripped of bullet prefixes
    lines = []
    for raw in text.splitlines():
        s = raw.strip()
        if not s or s.startswith("#"):
            continue
        m = re.match(r'^[\-\*\d\.\)]\s*(.+)$', s)
        lines.append(m.group(1).strip() if m else s)
    return lines, source

# ---------------- detection heuristics ----------------
def tokens_for_feature(feature: str) -> List[str]:
    words = re.findall(r"[A-Za-z0-9_]+", feature)
    tokens = [w.lower() for w in words if len(w) >= 4]
    if not tokens:
        tokens = [w.lower() for w in words][:2]
    return tokens[:3]

def safe_name_from_feature(feature: str) -> str:
    base = re.sub(r"[^A-Za-z0-9 ]+", "", feature).strip()
    base = "".join(word.capitalize() for word in base.split())
    if not base:
        base = "Feature"
    if not base.endswith("View"):
        base = base + "View"
    return base

def feature_present_in_repo(feature: str) -> bool:
    """
    Stricter detection: check for filename or symbol matches first.
    """
    try:
        base_view = safe_name_from_feature(feature)             # e.g. HabitTrackingView
        vm_name = base_view.replace("View", "ViewModel")        # e.g. HabitTrackingViewModel

        # 1) filename check
        if any(Path(".").rglob(f"*{base_view}.swift")):
            return True
        if any(Path(".").rglob(f"*{vm_name}.swift")):
            return True

        # 2) symbol check
        rc, out, err = search_repo(rf"struct\s+{re.escape(base_view)}\b", timeout=2)
        if rc == 0 and out.strip():
            return True
        rc, out, err = search_repo(rf"class\s+{re.escape(vm_name)}\b", timeout=2)
        if rc == 0 and out.strip():
            return True

        # 3) fallback: require 2 token matches (reduces false positives)
        tokens = tokens_for_feature(feature)
        if not tokens:
            return False
        matches = 0
        for t in tokens:
            rc, out, err = search_repo(t, timeout=2)
            if rc == 0 and out.strip():
                matches += 1
            if matches >= 2:
                return True
        return False
    except Exception:
        # conservative: if detection fails, treat as missing so generator can run
        return False

# ---------------- Swift generation helpers ----------------
def choose_target_dir() -> str:
    candidates = ["App/Features", "Sources", "App"]
    for cand in candidates:
        if os.path.exists(cand):
            return cand
    default = "App/Features"
    os.makedirs(default, exist_ok=True)
    return default

def make_view_and_viewmodel(feature: str) -> Tuple[str, str, str, str]:
    base = safe_name_from_feature(feature)
    target_dir = choose_target_dir()
    view_path = f"{target_dir}/{base}.swift"
    vm_name = base.replace("View", "ViewModel")
    vm_path = f"{target_dir}/{vm_name}.swift"

    vm_contents = f"""import Foundation
import Combine

/// Auto-generated ViewModel for '{feature}'
final class {vm_name}: ObservableObject {{
    @Published var title: String = "{feature}"
    @Published var items: [String] = []

    private var cancellables = Set<AnyCancellable>()

    init() {{
        // Provide mock data for previews
        self.items = ["Sample 1", "Sample 2"]
    }}

    /// Placeholder async loader
    func load() async {{
        // TODO: implement real loading from repository / backend
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s simulated delay
        DispatchQueue.main.async {{
            self.items = ["Loaded item 1", "Loaded item 2"]
        }}
    }}
}}
"""

    view_contents = f"""import SwiftUI

// Auto-generated View for feature: {feature}
struct {base}: View {{
    @StateObject private var viewModel = {vm_name}()

    var body: some View {{
        NavigationView {{
            VStack {{
                Text(viewModel.title)
                    .font(.largeTitle)
                    .padding(.top)

                if viewModel.items.isEmpty {{
                    VStack {{
                        Text("No items yet")
                            .foregroundColor(.secondary)
                        ProgressView()
                            .padding(.top, 8)
                    }}
                }} else {{
                    List(viewModel.items, id: \\.self) {{ item in
                        Text(item)
                    }}
                }}

                Spacer()
            }}
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {{
                ToolbarItem(placement: .navigationBarTrailing) {{
                    Button(action: {{
                        Task {{
                            await viewModel.load()
                        }}
                    }}) {{
                        Image(systemName: "arrow.clockwise")
                    }}
                    .accessibilityLabel("Refresh")
                }}
            }}
            .padding()
        }}
    }}
}}

#if DEBUG
struct {base}_Preview: PreviewProvider {{
    static var previews: some View {{
        {base}()
            .previewDevice("iPhone 14")
    }}
}}
#endif
"""
    return view_path, view_contents, vm_path, vm_contents

def atomic_write(path: str, contents: str, debug: bool):
    tmp_fd, tmp_path = tempfile.mkstemp(prefix="ai_features_", suffix=".tmp")
    os.close(tmp_fd)
    try:
        with open(tmp_path, "w", encoding="utf8") as f:
            f.write(contents)
        os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
        # backup if exists
        if os.path.exists(path):
            ts = int(time.time())
            bak = f"{path}.bak.{ts}"
            try:
                os.replace(path, bak)
                dlog(f"Backed up existing {path} -> {bak}", debug)
            except Exception as e:
                dlog(f"Backup failed for {path}: {e}", debug)
        os.replace(tmp_path, path)
        dlog(f"Wrote {path}", debug)
    finally:
        if os.path.exists(tmp_path):
            try:
                os.remove(tmp_path)
            except Exception:
                pass

def git_commit(paths: List[str], msg: str, debug: bool) -> bool:
    if not paths:
        dlog("No paths to commit.", debug)
        return False
    rc, out, err = run_cmd(["git", "add"] + paths)
    if rc != 0:
        dlog(f"git add failed: {err}", debug)
        return False
    rc, out, err = run_cmd(["git", "commit", "-m", msg])
    if rc != 0:
        dlog(f"git commit failed: {err}", debug)
        return False
    dlog(f"Committed: {msg}", debug)
    return True

# ---------------- need_work update ----------------
def mark_need_work_done(feature: str, source_path: str, debug: bool) -> bool:
    """
    Marks the first unchecked line that matches the feature text as checked in source_path.
    Returns True if changed and written.
    """
    p = Path(source_path)
    if not p.exists():
        return False
    text = p.read_text(encoding="utf8")
    # naive but safe: find the first line that contains the feature and an unchecked checkbox
    lines = text.splitlines()
    pattern = re.compile(r'(^[\s\-\*\d\.\)]*\[\s*\]\s*)(.*' + re.escape(feature) + r'.*)', re.IGNORECASE)
    for i, ln in enumerate(lines):
        m = pattern.search(ln)
        if m:
            lines[i] = ln.replace(m.group(1), m.group(1).replace("[ ]", "[x]") if "[ ]" in m.group(1) else m.group(1).replace("[]", "[x]"))
            new_text = "\n".join(lines) + ("\n" if text.endswith("\n") else "")
            atomic_write(str(p), new_text, debug)
            dlog(f"Marked done in {source_path}: {feature}", debug)
            return True
    return False

# ---------------- main ----------------
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", help="Don't write files")
    parser.add_argument("--commit", action="store_true", help="git add & commit changes")
    parser.add_argument("--debug", action="store_true", help="Write debug log")
    parser.add_argument("--force", action="store_true", help="Force adding a feature even if heuristics say none missing")
    args = parser.parse_args()

    dry = args.dry_run
    do_commit = args.commit
    debug = args.debug
    force = args.force or os.environ.get("AI_FEATURES_FORCE") == "1"

    # 1) backend
    if not repo_has_backend():
        created = ensure_backend(dry, debug)
        if created:
            dlog(f"Backend scaffold created (or would be): {created}", debug)
            if do_commit and not dry:
                git_commit(created, "AI-features: create backend scaffold", debug)
        else:
            dlog("No backend files created.", debug)
        return

    # 2) need_work / plan
    items, source = load_need_work()
    if not items:
        dlog("need_work.md / plan.md not found or contains no unchecked items. Nothing to do.", debug)
        return

    dlog(f"Loaded {len(items)} items from {source}; scanning for first missing feature...", debug)
    target = None
    for it in items:
        if not it or len(it.strip()) < 3:
            continue
        if feature_present_in_repo(it):
            dlog(f"Feature already present (skipping): {it}", debug)
            continue
        target = it
        break

    if not target:
        if force:
            dlog("Force set: selecting the first need_work item despite heuristics.", debug)
            target = items[0]
        else:
            dlog("No missing frontend features found in need_work.md / plan.md (all present according to heuristics).", debug)
            return

    dlog("Will implement feature: " + target, debug)
    view_path, view_contents, vm_path, vm_contents = make_view_and_viewmodel(target)

    if dry:
        dlog(f"[dry-run] Would create: {view_path}", debug)
        dlog(f"[dry-run] Would create: {vm_path}", debug)
        return

    # write files
    atomic_write(view_path, view_contents, debug)
    atomic_write(vm_path, vm_contents, debug)
    created = [view_path, vm_path]

    committed = False
    if do_commit:
        ok = git_commit(created, f"AI-feature: add {target}", debug)
        if ok:
            committed = True
        else:
            dlog("Commit failed for feature files.", debug)

    dlog(f"Created feature files: {created} (committed={committed})", debug)

    # mark the need_work item done when commit succeeded (or mark anyway if not committing is undesired)
    if committed:
        changed = mark_need_work_done(target, source, debug)
        if changed:
            # stage the change and commit again (append to commit message)
            rc, out, err = run_cmd(["git", "add", source])
            if rc == 0:
                rc2, out2, err2 = run_cmd(["git", "commit", "--amend", "--no-edit"])
                if rc2 == 0:
                    dlog(f"Marked {target} done in {source} and amended commit.", debug)
                else:
                    dlog(f"Marked done but amend commit failed: {err2}", debug)
            else:
                dlog(f"Marked done but git add failed: {err}", debug)

if __name__ == "__main__":
    main()