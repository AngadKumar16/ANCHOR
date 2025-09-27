#!/usr/bin/env python3
"""
Tools/ai_features.py  -- one feature per run (richer frontend stubs)

Behavior:
 - If backend missing, create minimal FastAPI backend scaffold (one-run).
 - Else read plan.md and create the first missing frontend feature as:
     - <Feature>View.swift (SwiftUI view with preview + mock)
     - <Feature>ViewModel.swift (ObservableObject stub)
 - Flags: --dry-run, --commit, --debug
 - Writes debug log to ~/.ai-fix-issues/features.log if --debug set.
"""
from __future__ import annotations
import argparse
import os
import re
import subprocess
import time
from pathlib import Path
from typing import List, Tuple

HOME = str(Path.home())
DEBUG_LOG_DIR = os.path.join(HOME, ".ai-fix-issues")
os.makedirs(DEBUG_LOG_DIR, exist_ok=True)
DEBUG_LOG = os.path.join(DEBUG_LOG_DIR, "features.log")

def dlog(msg: str, debug: bool=False):
    print(msg)
    if debug:
        try:
            with open(DEBUG_LOG, "a", encoding="utf8") as f:
                f.write(time.strftime("%Y-%m-%d %H:%M:%S ") + msg + "\n")
        except Exception:
            pass

def run_cmd(cmd: List[str], input_text: str = None, cwd: str = None, timeout: int = 60) -> Tuple[int,str,str]:
    try:
        p = subprocess.run(cmd, input=input_text, text=True, capture_output=True, check=False, cwd=cwd, timeout=timeout)
        return p.returncode, p.stdout or "", p.stderr or ""
    except Exception as e:
        return 1, "", str(e)

# ---------- Backend detection + scaffold ----------
def repo_has_backend() -> bool:
    candidates = ["backend", "server", "api", "app.py", "requirements.txt", "backend/app.py", "backend/Dockerfile"]
    for c in candidates:
        if os.path.exists(c):
            return True
    rc, out, err = run_cmd(["grep", "-R", "-n", "--exclude-dir=.git", "FastAPI\\|uvicorn\\|Vapor\\|flask\\|django", "."])
    if rc == 0 and out.strip():
        return True
    return False

def ensure_backend(dry: bool, debug: bool) -> List[str]:
    created = []
    if repo_has_backend():
        dlog("Backend already present; skipping backend creation.", debug)
        return created

    dlog("Backend not detected: will create minimal FastAPI scaffold under ./backend/", debug)
    if dry:
        created = ["backend/", "backend/app.py", "backend/requirements.txt", "backend/Dockerfile"]
        for p in created:
            dlog("[dry-run] would create: " + p, debug)
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
    with open("backend/app.py", "w", encoding="utf8") as f:
        f.write(app_py)
    with open("backend/requirements.txt", "w", encoding="utf8") as f:
        f.write(reqs)
    with open("backend/Dockerfile", "w", encoding="utf8") as f:
        f.write(dockerfile)
    created = ["backend/app.py", "backend/requirements.txt", "backend/Dockerfile"]
    for p in created:
        dlog("Created " + p, debug)
    return created

# ---------- Plan + feature detection ----------
def load_plan(path: str="plan.md") -> List[str]:
    if not os.path.exists(path):
        return []
    items = []
    with open(path, "r", encoding="utf8") as f:
        for raw in f:
            s = raw.strip()
            if not s:
                continue
            m = re.match(r"^[-*\d\.\)]\s*(.+)", s)
            items.append(m.group(1).strip() if m else s)
    return items

def tokens_for_feature(feature: str) -> List[str]:
    words = re.findall(r"[A-Za-z0-9_]+", feature)
    tokens = [w.lower() for w in words if len(w) >= 4]
    if not tokens:
        tokens = [w.lower() for w in words][:2]
    return tokens[:3]

def feature_present_in_repo(feature: str) -> bool:
    tokens = tokens_for_feature(feature)
    if not tokens:
        return False
    for t in tokens:
        rc, out, err = run_cmd(["grep", "-R", "-n", "--exclude-dir=.git", "--exclude-dir=DerivedData", t, "."])
        if rc == 0 and out.strip():
            return True
    return False

# ---------- File generation helpers (richer stubs) ----------
def safe_name_from_feature(feature: str) -> str:
    # Create a PascalCase base name; ensure it ends with 'View'
    base = re.sub(r"[^A-Za-z0-9 ]+", "", feature).strip()
    base = "".join(word.capitalize() for word in base.split())
    if not base:
        base = "Feature"
    if not base.endswith("View"):
        base = base + "View"
    return base

def choose_target_dir() -> str:
    for cand in ["App/Features", "Sources", "App"]:
        if os.path.exists(cand):
            return cand
    # default
    return "App/Features"

def make_view_and_viewmodel(feature: str) -> Tuple[str, str, str, str]:
    """
    Returns: view_path, view_contents, vm_path, vm_contents
    """
    base = safe_name_from_feature(feature)
    target_dir = choose_target_dir()
    view_path = f"{target_dir}/{base}.swift"
    vm_name = base.replace("View", "ViewModel")
    vm_path = f"{target_dir}/{vm_name}.swift"

    # ViewModel: ObservableObject with mock data & async loader placeholder
    vm_contents = f"""import Foundation
import Combine

/// Auto-generated ViewModel for '{feature}'
final class {vm_name}: ObservableObject {{
    @Published var title: String = "{feature}"
    @Published var items: [String] = []

    private var cancellables = Set<AnyCancellable>()

    init() {{
        // Provide mock data for previews
        self.items = [\"Sample 1\", \"Sample 2\"]
    }}

    /// Placeholder async loader
    func load() async {{
        // TODO: implement real loading from repository / backend
        await Task.sleep(200_000_000) // 0.2s simulated delay
        DispatchQueue.main.async {{
            self.items = [\"Loaded item 1\", \"Loaded item 2\"]
        }}
    }}
}}
"""

    # View: SwiftUI view wired to ViewModel, with simple list + refresh + preview
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
                    List(viewModel.items, id: \\ .self) {{ item in
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
            .previewDevice(\"iPhone 14\")
    }}
}}
#endif
"""

    return view_path, view_contents, vm_path, vm_contents

def write_with_backup(path: str, contents: str, debug: bool) -> None:
    if os.path.exists(path):
        ts = int(time.time())
        bak = f"{path}.bak.{ts}"
        try:
            os.replace(path, bak)
            dlog(f"Backed up existing {path} -> {bak}", debug)
        except Exception as e:
            dlog(f"Backup failed for {path}: {e}", debug)
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "w", encoding="utf8") as f:
        f.write(contents)
    dlog("Wrote " + path, debug)

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

# ---------- Main ----------
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", help="Don't write files")
    parser.add_argument("--commit", action="store_true", help="git add & commit changes")
    parser.add_argument("--debug", action="store_true", help="Write debug log")
    args = parser.parse_args()

    dry = args.dry_run
    do_commit = args.commit
    debug = args.debug

    # 1) backend scaffold if needed
    if not repo_has_backend():
        created = ensure_backend(dry, debug)
        if created:
            dlog(f"Backend scaffold created (or would be): {created}", debug)
            if do_commit and not dry:
                git_commit(created, "AI-features: create backend scaffold", debug)
        else:
            dlog("No backend files created.", debug)
        return

    # 2) read plan.md and pick first missing feature
    plan = load_plan()
    if not plan:
        dlog("plan.md not found or empty. Nothing to do.", debug)
        return

    dlog(f"plan.md contains {len(plan)} items; scanning for first missing feature...", debug)
    target_feature = None
    for item in plan:
        if feature_present_in_repo(item):
            dlog(f"Feature already present (skipping): {item}", debug)
            continue
        target_feature = item
        break

    if not target_feature:
        dlog("No missing frontend features found in plan.md (all present).", debug)
        return

    dlog("Will implement one feature this run: " + target_feature, debug)
    view_path, view_contents, vm_path, vm_contents = make_view_and_viewmodel(target_feature)

    created_files = []
    if dry:
        dlog(f"[dry-run] Would create: {view_path}", debug)
        dlog(f"[dry-run] Would create: {vm_path}", debug)
        return

    # write files (with backups if needed)
    write_with_backup(view_path, view_contents, debug)
    write_with_backup(vm_path, vm_contents, debug)
    created_files.extend([view_path, vm_path])

    if do_commit:
        ok = git_commit(created_files, f"AI-feature: add {target_feature}", debug)
        if not ok:
            dlog("Commit failed for feature files.", debug)
    else:
        dlog(f"Created feature files: {created_files} (not committed).", debug)

if __name__ == "__main__":
    main()
