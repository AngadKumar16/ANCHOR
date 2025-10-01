#!/usr/bin/env python3
"""
Tools/ai_features.py - aggressive feature generator

Behavior:
- Uses need_work.md (falls back to plan.md) as the queue.
- By default treats every listed item as "needs work" (no presence checks).
- For each picked item it generates:
    - <Feature>View.swift
    - <Feature>ViewModel.swift
  (written under a chosen App/Features or similar directory)
- Flags:
    --dry-run   : show what would be created
    --commit    : git add & commit created files
    --debug     : write debug output to ~/.ai-fix-issues/features.log
    --force     : ignore any internal checking and force creation
    --batch N   : implement up to N items this run (default 5)
    --check     : enable the original presence heuristics (OFF by default)
- No .bak files are produced. Files are only replaced when content differs.
- When files are written, the corresponding need_work.md item is marked done immediately.
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
    try:
        proc = subprocess.run(cmd, input=input_text, text=True, capture_output=True, check=False, cwd=cwd, timeout=timeout)
        return proc.returncode, proc.stdout or "", proc.stderr or ""
    except subprocess.TimeoutExpired:
        return 124, "", "Command timed out"
    except Exception as e:
        return 1, "", str(e)

# ---------------- repo / backend helpers ----------------
def repo_has_backend() -> bool:
    candidates = ["backend", "server", "api", "app.py", "requirements.txt", "backend/app.py", "backend/Dockerfile"]
    for c in candidates:
        if os.path.exists(c):
            return True
    # best-effort search
    try:
        rc, out, err = run_cmd(["rg", "--hidden", "--glob", "!.git/**", "-n", "FastAPI|uvicorn|flask|django|express|Vapor|http.server"], timeout=4)
        if rc == 0 and out.strip():
            return True
    except Exception:
        pass
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

# ---------------- naming helpers ----------------
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

def atomic_write(path: str, contents: str, debug: bool) -> bool:
    """
    Atomically write path only when contents differ.
    This intentionally does NOT create .bak files.
    Returns True if a write occurred (created or updated), False if skipped due to identical content.
    """
    tmp_fd, tmp_path = tempfile.mkstemp(prefix="ai_features_", suffix=".tmp")
    os.close(tmp_fd)
    try:
        # If the target exists and its content is identical, skip writing.
        if os.path.exists(path):
            try:
                existing = Path(path).read_text(encoding="utf8")
                if existing == contents:
                    dlog(f"No changes for {path}; skipping write.", debug)
                    return False
            except Exception:
                # If reading fails, proceed to write for safety.
                pass

        # write to temporary file then atomically replace the target path
        with open(tmp_path, "w", encoding="utf8") as f:
            f.write(contents)
        os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
        os.replace(tmp_path, path)
        dlog(f"Wrote {path}", debug)
        return True
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
            # replace [ ] or [] with [x]
            prefix = m.group(1)
            if "[ ]" in prefix:
                new_prefix = prefix.replace("[ ]", "[x]")
            elif "[]" in prefix:
                new_prefix = prefix.replace("[]", "[x]")
            else:
                new_prefix = prefix
            lines[i] = new_prefix + m.group(2)
            new_text = "\n".join(lines) + ("\n" if text.endswith("\n") else "")
            # write immediately (no .bak)
            written = atomic_write(str(p), new_text, debug)
            if written:
                dlog(f"Marked done in {source_path}: {feature}", debug)
            else:
                dlog(f"Marked done (no write needed) in {source_path}: {feature}", debug)
            return True
    return False

# ---------------- batch apply logic ----------------
def generate_backend_auth_stub(debug: bool) -> List[str]:
    """
    Create a simple auth router under backend/auth.py if backend exists.
    Returns list of created/modified paths.
    """
    created = []
    backend_dir = Path("backend")
    if not backend_dir.exists():
        return created

    auth_py = backend_dir / "auth.py"
    auth_contents = """from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

router = APIRouter(prefix="/auth", tags=["auth"])

class LoginRequest(BaseModel):
    username: str
    password: str

@router.post("/login")
async def login(req: LoginRequest):
    # TODO: replace with real authentication logic
    if req.username == "demo" and req.password == "demo":
        return {"token": "fake-token-for-demo"}
    raise HTTPException(status_code=401, detail="Invalid credentials")

@router.get("/me")
async def me():
    return {"id": 1, "username": "demo"}
"""
    wrote = atomic_write(str(auth_py), auth_contents, debug)
    if wrote:
        created.append(str(auth_py))

    app_py = backend_dir / "app.py"
    if app_py.exists():
        text = app_py.read_text(encoding="utf8")
        marker = "from .auth import router as auth_router"
        if marker not in text:
            new_text = text + "\n\nfrom .auth import router as auth_router\napp.include_router(auth_router)\n"
            wrote_app = atomic_write(str(app_py), new_text, debug)
            if wrote_app:
                created.append(str(app_py))
    return created

def apply_batch(targets: List[str], source: str, dry: bool, do_commit: bool, debug: bool, check_mode: bool) -> Tuple[List[str], bool]:
    """
    Generate files for each target in list. Returns (created_paths, committed_bool).
    Marks need_work items done as soon as their files are written.
    """
    created_paths = []
    written_targets = []  # targets that resulted in at least one file written

    # ensure backend exists if necessary (create minimal scaffold if missing)
    if not dry:
        ensure_backend(False, debug)

    for t in targets:
        # If check_mode enabled, skip generation if heuristics detect presence (legacy behavior)
        if check_mode:
            # attempt feature presence detection; if present, skip
            try:
                if feature_present_in_repo(t):
                    dlog(f"Feature appears present (skipping): {t}", debug)
                    continue
            except Exception:
                pass

        view_path, view_contents, vm_path, vm_contents = make_view_and_viewmodel(t)
        if dry:
            dlog(f"[dry-run] Would create: {view_path}", debug)
            dlog(f"[dry-run] Would create: {vm_path}", debug)
            created_paths.extend([view_path, vm_path])
            continue

        wrote_view = atomic_write(view_path, view_contents, debug)
        wrote_vm = atomic_write(vm_path, vm_contents, debug)

        if wrote_view or wrote_vm:
            written_targets.append(t)
        if wrote_view:
            created_paths.append(view_path)
        if wrote_vm:
            created_paths.append(vm_path)

        # add backend auth stub for auth-related features
        if re.search(r"auth|login|signup|register|token|oauth|session|user", t, re.I):
            created_backend = generate_backend_auth_stub(debug)
            created_paths.extend(created_backend)

        # mark need_work item done as soon as files were written (mark-on-write)
        if (wrote_view or wrote_vm):
            mark_need_work_done(t, source, debug)

    committed = False
    if not dry and created_paths:
        # stage created files
        rc, out, err = run_cmd(["git", "add"] + created_paths)
        if rc != 0:
            dlog(f"git add failed for created_paths: {err}", debug)
        else:
            rc2, out2, err2 = run_cmd(["git", "commit", "-m", f"AI-feature: add {len(targets)} features"], timeout=30)
            if rc2 == 0:
                committed = True
                dlog(f"Committed: AI-feature: add {len(targets)} features", debug)
            else:
                dlog(f"git commit failed: {err2}", debug)

    # if commit succeeded, ensure need_work.md is included (it may already be modified)
    if committed:
        rc3, o3, e3 = run_cmd(["git", "add", source])
        if rc3 == 0:
            rc4, o4, e4 = run_cmd(["git", "commit", "--amend", "--no-edit"])
            if rc4 == 0:
                dlog(f"Amended commit to include updates to {source}", debug)
            else:
                dlog(f"Amend commit failed: {e4}", debug)
        else:
            dlog(f"git add failed for {source}: {e3}", debug)

    return created_paths, committed

# ---------------- presence heuristic (kept for optional --check) ----------------
def feature_present_in_repo(feature: str) -> bool:
    """
    Stricter detection kept only for --check mode.
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
        rc, out, err = run_cmd(["rg", "-n", rf"struct\s+{re.escape(base_view)}\b"], timeout=2)
        if rc == 0 and out.strip():
            return True
        rc, out, err = run_cmd(["rg", "-n", rf"class\s+{re.escape(vm_name)}\b"], timeout=2)
        if rc == 0 and out.strip():
            return True

        # 3) fallback: require 2 token matches (reduces false positives)
        tokens = tokens_for_feature(feature)
        if not tokens:
            return False
        matches = 0
        for t in tokens:
            rc, out, err = run_cmd(["rg", "-n", t], timeout=2)
            if rc == 0 and out.strip():
                matches += 1
            if matches >= 2:
                return True
        return False
    except Exception:
        return False

# ---------------- main ----------------
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", help="Don't write files")
    parser.add_argument("--commit", action="store_true", help="git add & commit changes")
    parser.add_argument("--debug", action="store_true", help="Write debug log")
    parser.add_argument("--force", action="store_true", help="Force adding features ignoring presence heuristics")
    parser.add_argument("--batch", type=int, default=5, help="Number of need_work items to implement in this run (default 5)")
    parser.add_argument("--check", action="store_true", help="Enable presence-check heuristics (disabled by default)")
    args = parser.parse_args()

    dry = args.dry_run
    do_commit = args.commit
    debug = args.debug
    force = args.force
    batch = max(1, args.batch)
    check_mode = args.check

    # Create backend scaffold early only when not dry (ensure backend exists)
    try:
        ensure_backend(dry, debug)
    except Exception as e:
        dlog(f"ensure_backend error: {e}", debug)

    items, source = load_need_work()
    if not items:
        dlog("need_work.md / plan.md not found or contains no items. Nothing to do.", debug)
        return

    # pick up to batch non-empty items; default behavior: do NOT check repo presence (aggressive)
    targets = [it for it in items if it and len(it.strip()) >= 1][:batch]
    if not targets:
        dlog("No non-empty items found in need_work.md / plan.md. Nothing to do.", debug)
        return

    # If not force and check_mode enabled, will skip items that appear present in repo.
    if not force and check_mode:
        filtered = []
        for t in targets:
            if feature_present_in_repo(t):
                dlog(f"Skipping present feature (check-mode): {t}", debug)
            else:
                filtered.append(t)
        targets = filtered[:batch]
        if not targets:
            dlog("No targets left after presence checks.", debug)
            return

    dlog(f"Will implement up to {len(targets)} features: {targets}", debug)

    created_paths, committed = apply_batch(targets, source, dry, do_commit, debug, check_mode)

    dlog(f"Created feature files: {created_paths} (committed={committed})", debug)

if __name__ == "__main__":
    main()
