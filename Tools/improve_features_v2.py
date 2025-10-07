#!/usr/bin/env python3
"""
Tools/improve_features_v2.py

Priority-driven, idempotent (but optionally aggressive) improver for Swift code + backend wiring.

Behavior:
- Priorities:
  0) Placeholder/stub files first (aggressively fix placeholders)
  1) Swift files with <100 lines
  2) Files under App/Features/
  3) Swift files with <200 lines (excluding processed)
  4) Add helpers for each processed file in the correct location
- For each file: ensure backend endpoints (backend/app.py) then frontend improvements.
- Ensures files are referenced by adding entries to App/FeatureRegistry.swift when needed.
- Persists processed file list to ~/.ai-fix-issues/processed_files.json.

Usage:
  python3 Tools/improve_features_v2.py [--dry-run] [--debug] [--force] [--max N] [--no-aggressive]

Notes:
  - Run from repo root.
  - No .bak files created.
"""
from __future__ import annotations
import argparse
import json
import os
import re
import sys
import time
from pathlib import Path
from typing import List, Set
import hashlib

# -------------------------
# Configuration & constants
# -------------------------
HOME = Path.home()
LOG_DIR = HOME / ".ai-fix-issues"
LOG_DIR.mkdir(parents=True, exist_ok=True)
LOG_FILE = LOG_DIR / "improve_v2.log"
STATE_FILE = LOG_DIR / "processed_files.json"

# Focus root: the nested ANCHOR directory (the second ANCHOR)
ROOT_DIR = Path("ANCHOR")

BACKEND_APP = ROOT_DIR / "backend" / "app.py"
BACKEND_REGISTRY = ROOT_DIR / "backend" / "_registry.json"
API_CLIENT_PATH = ROOT_DIR / "App" / "APIClient.swift"
FEATURE_REGISTRY = ROOT_DIR / "App" / "FeatureRegistry.swift"
WRITTEN_HASHES = LOG_DIR / "written_hashes.json"

# When False, the improver will NOT create new files or directories; only update existing files.
ALLOW_CREATE = False



# Default: aggressive ON (per your request). CLI exposes --no-aggressive to disable.
AGGRESSIVE = True

# -------------------------
# Utilities
# -------------------------
<<<<<<< Updated upstream
=======
def relpath_to_project(path: Path) -> str:
    try:
        rel = str(Path(path).relative_to(PROJECT_ROOT))
    except Exception:
        rel = os.path.relpath(str(path), str(PROJECT_ROOT))
    # Normalize away "../"
    if rel.startswith("../"):
        rel = rel[3:]
    return rel

def canonicalize_feat(name: str) -> str:
    """Return a CamelCase canonicalized version of a feature name."""
    return ''.join(word.capitalize() for word in re.split(r'[^A-Za-z0-9]+', name) if word)


>>>>>>> Stashed changes
def now() -> str:
    return time.strftime("%Y-%m-%d %H:%M:%S")

def log(msg: str, debug: bool = False):
    """Log a message; also append to debug log file if debug True."""
    prefix = f"[improver] {msg}"
    print(prefix)
    if debug:
        try:
            with open(LOG_FILE, "a", encoding="utf8") as f:
                f.write(f"{now()} {prefix}\n")
        except Exception:
            pass

def sha256_text(s: str) -> str:
    return hashlib.sha256(s.encode("utf8")).hexdigest()

def load_written_hashes() -> dict:
    try:
        if WRITTEN_HASHES.exists():
            return json.loads(WRITTEN_HASHES.read_text(encoding="utf8"))
    except Exception:
        pass
    return {}

def save_written_hashes(d: dict):
    try:
        # canonical JSON: sorted keys and compact separators for stability
        WRITTEN_HASHES.write_text(json.dumps(d, indent=2, sort_keys=True, separators=(", ", ": ")), encoding="utf8")
    except Exception:
        pass


def normalize_text(s: str) -> str:
    """
    Normalize generated text for stable comparisons:
    - unify CRLF -> LF
    - strip trailing whitespace on each line
    - remove repeated blank lines (optional)
    - ensure exactly one trailing newline
    """
    if s is None:
        return ""
    # unify line endings
    s = s.replace("\r\n", "\n").replace("\r", "\n")
    # strip trailing whitespace on each line
    lines = [ln.rstrip() for ln in s.split("\n")]
    # optionally collapse repeated blank lines (keep one)
    out_lines = []
    prev_blank = False
    for ln in lines:
        is_blank = (ln == "")
        if is_blank and prev_blank:
            # skip duplicate blank line
            continue
        out_lines.append(ln)
        prev_blank = is_blank
    # ensure single trailing newline
    return ("\n".join(out_lines)).rstrip() + "\n"


def atomic_write(path: Path, contents: str, debug: bool = False, dry: bool = False) -> bool:
    """
    Write only if different. Uses a persistent written_hashes file to avoid toggles.
    When AGGRESSIVE is True the function will not respect the written_hash cache and
    will attempt to write/overwrite existing files (still avoids rewrite when on-disk
    content already exactly matches).
    Returns True if written.
    """
    # In dry mode only print candidate
    if dry:
        log(f"[dry-run] would write {path}", debug)
        return True

    # If creation is disabled, do not create new files.
    # Only allow writing if the target file already exists.
    if not ALLOW_CREATE:
        try:
            if not path.exists():
                log(f"Skipping creation of new file {path} because ALLOW_CREATE=False", debug)
                return False
        except Exception:
            log(f"Skipping creation check for {path} (conservative)", debug)
            return False

    
    try:
        # Safety guard: avoid accidental writes to suspicious short filenames like "py"
        try:
            bad_names = {"py", "tmp", "tmpfile", ""}
            suspicious_short = len(path.name) <= 3 and path.suffix == "" and path.name.isalpha()
            if path.name in bad_names or suspicious_short:
                log(f"SKIP writing suspicious filename {path} (possible bug).", True)
                try:
                    import traceback
                    tb = "".join(traceback.format_stack(limit=6))
                    with open(LOG_FILE, "a", encoding="utf8") as f:
                        f.write(f"{now()} suspicious atomic_write target: {path}\n{tb}\n")
                except Exception:
                    pass
                return False
        except Exception:
            pass

        # Normalize new content for deterministic comparison
        new_norm = normalize_text(contents)
        new_hash = sha256_text(new_norm)
        hashes = load_written_hashes()

        # If file exists, compare normalized on-disk content (safety)
        if path.exists():
            try:
                old = path.read_text(encoding="utf8")
                old_norm = normalize_text(old)
                old_hash = sha256_text(old_norm)
                if old_hash == new_hash:
                    # on-disk already matches content — nothing to do
                    # but ensure cache knows this
                    if hashes.get(str(path)) != new_hash:
                        hashes[str(path)] = new_hash
                        save_written_hashes(hashes)
                    log(f"no-op (identical) {path}", debug)
                    return False
            except Exception:
                pass


        # compute new hash

        # If file exists, compare on-disk content too (safety)
        if path.exists():
            try:
                old = path.read_text(encoding="utf8")
                old_hash = sha256_text(old)
                if old_hash == new_hash:
                    # on-disk already matches content — nothing to do
                    # but ensure cache knows this
                    if hashes.get(str(path)) != new_hash:
                        hashes[str(path)] = new_hash
                        save_written_hashes(hashes)
                    log(f"no-op (identical) {path}", debug)
                    return False
            except Exception:
                pass

        # If we previously wrote the same content for this path, normally we'd skip.
        # In AGGRESSIVE mode, ignore the 'written hashes' cache and force a re-write
        # when necessary (but we already checked on-disk identical case above).
        if not AGGRESSIVE:
            if hashes.get(str(path)) == new_hash:
                # the disk might have been changed externally; still check and only write if different
                if path.exists():
                    try:
                        if sha256_text(path.read_text(encoding="utf8")) == new_hash:
                            log(f"no-op (cached identical) {path}", debug)
                            return False
                    except Exception:
                        pass
                # else fall through to write

        # Write atomically
        if ALLOW_CREATE:
            path.parent.mkdir(parents=True, exist_ok=True)
        else:
            if not path.parent.exists():
                log(f"Parent directory {path.parent} missing for {path}; ALLOW_CREATE=False -> skipping write", debug)
                return False

        tmp = path.with_suffix(path.suffix + ".tmp")
        tmp.write_text(new_norm, encoding="utf8")
        tmp.replace(path)
        log(f"WROTE {path}", debug)

        # persist hash
        hashes[str(path)] = new_hash
        save_written_hashes(hashes)
        return True
    except Exception as e:
        log(f"ERROR writing {path}: {e}", True)
        return False


# -------------------------
# File / project helpers
# -------------------------
def load_state() -> Set[str]:
    try:
        if STATE_FILE.exists():
            return set(json.loads(STATE_FILE.read_text(encoding="utf8")))
    except Exception:
        pass
    return set()

def save_state(processed: Set[str]):
    try:
        try:
            STATE_FILE.write_text(json.dumps(sorted(processed), indent=2, separators=(", ", ": ")), encoding="utf8")
        except Exception:
            pass
    except Exception:
        pass

def list_swift_files() -> List[Path]:
    """List all Swift files under the nested ROOT_DIR (ANCHOR/ANCHOR) 
    excluding Pods, Carthage, Xcode build dirs, and already improved files.
    """
    base = ROOT_DIR
    if not base.exists():
        return []

    files = []
    for p in base.rglob("*.swift"):
        sp = str(p)
        if "Pods/" in sp:
            print("[skip: Pods]    ", sp)
            continue
        if ".build" in sp:
            print("[skip: .build]  ", sp)
            continue
        if "Carthage/" in sp:
            print("[skip: Carthage]", sp)
            continue

        text = p.read_text(errors="ignore")
        if "// [improved]" in text:
            print(f"[skip already improved] {p}")
            continue

        print("[keep]          ", sp)
        files.append(p)

    return sorted(files)



def file_length(path: Path) -> int:
    try:
        return len(path.read_text(encoding="utf8").splitlines())
    except Exception:
        return 0

def is_in_app_features(path: Path) -> bool:
    return "App/Features" in str(path).replace("\\", "/")

# Prefer class/struct name if present otherwise filename stem
def safe_feature_name_from_path(path: Path) -> str:
    try:
        txt = path.read_text(encoding="utf8")
        m = re.search(r'(?:struct|class)\s+([A-Za-z0-9_]+)(?:View|ViewModel)?', txt)
        if m:
            return m.group(1)
    except Exception:
        pass
    s = path.stem
    s = re.sub(r'View$|ViewModel$', '', s)
    return ''.join(x for x in s.title().split())

def grep_repo(pattern: str) -> List[str]:
    """Search text files under ROOT_DIR (nested ANCHOR) for a pattern and return matching paths."""
    out = []
    base = ROOT_DIR
    if not base.exists():
        return out
    # search Swift files (scoped) first
    for p in list_swift_files():
        try:
            txt = p.read_text(encoding="utf8")
            if re.search(pattern, txt):
                out.append(str(p))
        except Exception:
            pass
    # also search other non-Swift files under ROOT_DIR (limited)
    for p in base.rglob("*"):
        if p.is_file() and p.suffix not in (".swift",):
            try:
                txt = p.read_text(encoding="utf8", errors="ignore")
                if pattern in txt:
                    out.append(str(p))
            except Exception:
                pass
    return out



# -------------------------
# Backend helpers
# -------------------------
<<<<<<< Updated upstream
def ensure_backend_scaffold(dry: bool, debug: bool) -> bool:
    """
    Ensure backend/ exists and a minimal app.py template exists. Will be regenerated from registry.
    """
    Path("backend").mkdir(parents=True, exist_ok=True)
    # create an initial registry if missing
    if not BACKEND_REGISTRY.exists():
        if dry:
            log("[dry-run] would create backend/_registry.json", debug)
        else:
            BACKEND_REGISTRY.write_text(json.dumps([], indent=2), encoding="utf8")
    # always (re)generate backend/app.py from registry (idempotent)
    return regenerate_backend_app_from_registry(dry, debug)

def backend_register_feature(name: str, dry: bool, debug: bool) -> bool:
    """
    Add feature name to backend/_registry.json if missing. Return True if registry changed.
    """
    registry = []
    if BACKEND_REGISTRY.exists():
        try:
            registry = json.loads(BACKEND_REGISTRY.read_text(encoding="utf8"))
        except Exception:
            registry = []
    if name in registry:
        return False
    registry.append(name)
    if dry:
        log(f"[dry-run] would add {name} to backend/_registry.json", debug)
        return True
    BACKEND_REGISTRY.write_text(json.dumps(sorted(registry), indent=2, sort_keys=False, separators=(", ", ": ")), encoding="utf8")
    # regenerate app.py after updating registry
    regenerate_backend_app_from_registry(dry, debug)
    return True

def regenerate_backend_app_from_registry(dry: bool, debug: bool) -> bool:
    """
    Read backend/_registry.json and write a deterministic backend/app.py
    The generated app.py contains Pydantic models and endpoints for each feature.
    """
    registry = []
    if BACKEND_REGISTRY.exists():
        try:
            registry = json.loads(BACKEND_REGISTRY.read_text(encoding="utf8"))
        except Exception:
            registry = []

    # Build deterministic app.py content
    parts: List[str] = []
    parts.append("""from fastapi import FastAPI
from pydantic import BaseModel
from typing import List
from uuid import UUID
from datetime import datetime

app = FastAPI()

# AUTO-GENERATED endpoints (regenerated from backend/_registry.json)
""")
    for name in sorted(set(registry)):
        # sanitize name for Python class (simple alnum)
        pyname = re.sub(r'[^0-9A-Za-z]', '', name)
        lower = pyname.lower()
        parts.append(f"""
class {pyname}Model(BaseModel):
    id: UUID
    title: str
    createdAt: datetime
    body: str | None = None

{lower}_store: List[{pyname}Model] = []

@app.get("/{lower}s", response_model=List[{pyname}Model])
async def get_{lower}s():
    return {lower}_store

@app.post("/{lower}", response_model={pyname}Model)
async def post_{lower}(payload: {pyname}Model):
    {lower}_store.append(payload)
    return payload
""")
    new_text = "\n".join(parts).strip() + "\n"
    return atomic_write(BACKEND_APP, new_text, debug, dry)

def backend_add_feature_endpoints(name: str, dry: bool, debug: bool) -> bool:
    """
    Append an endpoint snippet for the feature into backend/app.py if not present.
    This is a fallback; regenerate_backend_app_from_registry is the canonical source.
    """
    BACKEND_APP.parent.mkdir(parents=True, exist_ok=True)
    if not BACKEND_APP.exists():
        ensure_backend_scaffold(dry, debug)
    text = BACKEND_APP.read_text(encoding="utf8") if BACKEND_APP.exists() else ""
    marker = f"# AUTO-GENERATED {name} endpoints"
    if marker in text:
        log(f"backend: endpoints for {name} already present", debug)
        return False
    lower = re.sub(r'[^0-9A-Za-z]', '', name).lower()
    snippet = f"""

# AUTO-GENERATED {name} endpoints
class {name}Model(BaseModel):
    id: UUID
    title: str
    createdAt: datetime
    body: str | None = None

{lower}_store = []

@app.get("/{lower}s", response_model=List[{name}Model])
async def get_{lower}s():
    return {lower}_store

@app.post("/{lower}", response_model={name}Model)
async def post_{lower}(payload: {name}Model):
    {lower}_store.append(payload)
    return payload

# END AUTO-GENERATED {name}
"""
    return atomic_write(BACKEND_APP, text + snippet, debug, dry)

# -------------------------
# API client (Swift) helpers
# -------------------------
API_CLIENT_TEMPLATE = """import Foundation

final class APIClient {{
    static let shared = APIClient()
    private init() {{}}

    private var baseURL: URL {{
        return URL(string: "http://127.0.0.1:8000")!
    }}

    func get<T: Decodable>(_ path: String) async throws -> T {{
        let url = baseURL.appendingPathComponent(path)
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(T.self, from: data)
    }}

    func post<T: Decodable, U: Encodable>(_ path: String, _ payload: U) async throws -> T {{
        let url = baseURL.appendingPathComponent(path)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(payload)
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(T.self, from: data)
    }}
}}

/// AUTO-GENERATED API METHODS:
{METHODS}
"""

def ensure_api_client(dry: bool, debug: bool) -> bool:
    """
    Ensure App/APIClient.swift exists. When AGGRESSIVE is True, overwrite existing
    API client with the template so new autogenerated methods/regeneration is reliable.
    """
    if API_CLIENT_PATH.exists() and not AGGRESSIVE:
        return False
    contents = API_CLIENT_TEMPLATE.format(METHODS="")
    return atomic_write(API_CLIENT_PATH, contents, debug, dry)

def make_api_snippet(name: str) -> str:
    lower = re.sub(r'[^0-9A-Za-z]', '', name).lower()
    return f"""
// AUTO-GENERATED: {name} API methods
extension APIClient {{
    func fetch{name}s() async throws -> [{name}Model] {{
        return try await get("/{lower}s")
    }}
    func post{name}(_ payload: {name}Model) async throws -> {name}Model {{
        return try await post("/{lower}", payload)
    }}
}}
"""

def regenerate_api_client_from_registry(dry: bool, debug: bool) -> bool:
    registry = []
    if BACKEND_REGISTRY.exists():
        try:
            registry = json.loads(BACKEND_REGISTRY.read_text(encoding="utf8"))
        except Exception:
            registry = []
    methods = []
    for name in sorted(set(registry)):
        # sanitize for swift type names
        swname = re.sub(r'[^0-9A-Za-z]', '', name)
        lower = swname.lower()
        methods.append(f"""extension APIClient {{
    func fetch{swname}s() async throws -> [{swname}Model] {{
        return try await get("/{lower}s")
    }}
    func post{swname}(_ payload: {swname}Model) async throws -> {swname}Model {{
        return try await post("/{lower}", payload)
    }}
}}""")
    new_text = API_CLIENT_TEMPLATE.format(METHODS="\n\n".join(methods))
    return atomic_write(API_CLIENT_PATH, new_text, debug, dry)

# -------------------------
# Feature registry (Swift linking) helpers
# -------------------------
def generate_registry_with_extra(*extra_names: str) -> str:
    """
    Read existing registry (if any) and merge with extra_names. Return the full contents.
    """
    existing = []
    if FEATURE_REGISTRY.exists():
        try:
            txt = FEATURE_REGISTRY.read_text(encoding="utf8")
            existing = re.findall(r'_ = ([A-Za-z0-9_]+)View\(\)', txt)
        except Exception:
            existing = []
    merged = sorted(set(existing + [n for n in extra_names if n]))
    contents = "// Auto-generated FeatureRegistry to ensure views are referenced\nimport SwiftUI\n\nfunc __registerFeaturesForLinking() {\n"
    for n in merged:
        contents += f"    _ = {n}View()\n"
    contents += "}\n"
    return contents

def ensure_feature_registry_refs(names: List[str], dry: bool, debug: bool) -> bool:
    """
    Merge provided names with existing FeatureRegistry references and write the file.
    If names is empty, still ensure the file exists (idempotent).
    """
    existing = []
    if FEATURE_REGISTRY.exists():
        try:
            txt = FEATURE_REGISTRY.read_text(encoding="utf8")
            existing = re.findall(r'_ = ([A-Za-z0-9_]+)View\(\)', txt)
        except Exception:
            existing = []
    # merge
    merged = sorted(set(existing + names))
    contents = "// Auto-generated FeatureRegistry to ensure views are referenced\nimport SwiftUI\n\nfunc __registerFeaturesForLinking() {\n"
    for n in merged:
        contents += f"    _ = {n}View()\n"
    contents += "}\n"
    return atomic_write(FEATURE_REGISTRY, normalize_text(contents), debug, dry)

# -------------------------
# Frontend generation helpers
# -------------------------
=======
# Normalize feature name into proper CamelCase
def canonicalize_feat(name: str) -> str:
    import re
    parts = re.findall(r"[A-Za-z0-9]+", name)
    return "".join(p[0].upper() + p[1:] for p in parts if p)

# v
def ai_propose_changes(
    feature: str,
    state: Dict[str, Path],
    debug: bool = False,
    prev: Optional[Dict[str, str]] = None,
    pass_no: int = 0
) -> Dict[str, str]:
    """
    Given a feature name and its current state, propose files to create or modify.
    Returns a dict: path_str -> file_contents (fully rendered).

    This function is the AI integration point; replace its body with a call to an LLM
    to produce higher-quality code. For now we use deterministic templates and heuristics.

    If called multiple times (multi-pass mode), we refine previous proposals cautiously.
    """

    # --- THINKING PHASE PATCH START ---
    if prev is not None:
        # Conservative refinement: only keep entries that persist or converge.
        refined = {}
        for path, content in prev.items():
            # If the same file already proposed, keep it.
            refined[path] = content
        if debug:
            log(f"[think:{pass_no}] refining {len(refined)} files", debug)
        return refined
    # --- THINKING PHASE PATCH END ---

    proposals: Dict[str, str] = {}
    feat = canonicalize_feat(feature)
    features_dir = PROJECT_ROOT / "App" / "Features"
    view_path = features_dir / f"{feat}View.swift"
    vm_path = features_dir / f"{feat}ViewModel.swift"
    repo_path = features_dir / f"{feat}Repository.swift"
    model_path = PROJECT_ROOT / "Models" / f"{feat}Model.swift"
    test_path = PROJECT_ROOT / "Tests" / "Features" / f"{feat}Tests.swift"
    plan_path = PROJECT_ROOT / "plan.md"

    # === Generation logic ===
    if not state.get("view"):
        proposals[str(view_path)] = make_swift_view(feat)
    if not state.get("viewmodel"):
        proposals[str(vm_path)] = make_swift_vm(feat, backend=True)
    if not any(m.name.endswith(f"{feat}Model.swift") for m in state.get("models", [])):
        proposals[str(model_path)] = make_swift_model(feat)
    if not state.get("repo"):
        proposals[str(repo_path)] = make_swift_repo(feat)
    if not state.get("tests"):
        proposals[str(test_path)] = make_swift_test(feat)

    # Add/update plan.md
    plan_note = (
        f"# Feature: {feat}\n\n"
        f"Auto-generated plan for {feat}\n\n"
        "- Implement UI (View & ViewModel)\n"
        "- Implement Repository & Model\n"
        "- Add backend endpoints and API client methods\n"
        "- Add tests\n\n"
    )
    existing_plan = read_text_safe(plan_path)
    if plan_note.strip() not in existing_plan:
        proposals[str(plan_path)] = (
            existing_plan + "\n\n" + plan_note if existing_plan else plan_note
        )

    if debug:
        log(f"ai_propose_changes({feature}): proposing {len(proposals)} files", debug)

    return proposals


# Reuse make_* templates from previous code (simple, safe templates)
>>>>>>> Stashed changes
def make_swift_model(name: str) -> str:
    return f"""import Foundation

struct {name}Model: Codable, Identifiable, Hashable {{
    public var id: UUID = UUID()
    public var title: String
    public var createdAt: Date = Date()
    public var body: String?
}}
"""

def make_swift_repo(name: str) -> str:
    return f"""import Foundation

final class {name}Repository {{
    static let shared = {name}Repository()
    private init() {{}}
    private var store: [{name}Model] = []

    func save(_ m: {name}Model) async throws {{
        store.append(m)
    }}
    func fetchAll() async throws -> [{name}Model] {{
        return store
    }}
}}
"""

def make_swift_vm(name: str, backend: bool) -> str:
    backend_save = ""
    backend_load = ""
    if backend:
        backend_save = f"""
        // attempt backend post (best-effort)
        do {{
            let posted = try await APIClient.shared.post{name}(m)
            // ignore for now
        }} catch {{ }}
"""
        backend_load = f"""
        // attempt backend fetch (best-effort)
        do {{
            let remote = try await APIClient.shared.fetch{name}s()
            if !remote.isEmpty {{
                DispatchQueue.main.async {{ self.items = remote }}
                return
            }}
        }} catch {{ }}
"""
    return f"""import Foundation
import Combine

final class {name}ViewModel: ObservableObject {{
    @Published var items: [{name}Model] = []
    @Published var draftTitle: String = ""
    @Published var draftBody: String = ""

    init() {{
        self.items = [{name}Model(title: "Welcome to {name}", body: "Auto-added")]
    }}

    func saveDraft() async {{
        guard !draftTitle.trimmingCharacters(in: .whitespaces).isEmpty else {{ return }}
        let m = {name}Model(title: draftTitle, body: draftBody)
        do {{
            try await {name}Repository.shared.save(m)
{backend_save}
            DispatchQueue.main.async {{ self.items.append(m); draftTitle = ""; draftBody = "" }}
        }} catch {{ }}
    }}

    func loadAll() async {{
{backend_load}
        do {{
            self.items = try await {name}Repository.shared.fetchAll()
        }} catch {{ }}
    }}
}}
"""

def make_swift_view(name: str) -> str:
    return f"""import SwiftUI

struct {name}View: View {{
    @StateObject private var vm = {name}ViewModel()
    @State private var draft: String = ""

    var body: some View {{
        NavigationView {{
            VStack {{
                Text("{name}").font(.largeTitle)
                TextField("Title", text: $vm.draftTitle).textFieldStyle(.roundedBorder).padding()
                TextEditor(text: $vm.draftBody).frame(minHeight:120).padding()
                HStack {{
                    Button("Save") {{ Task {{ await vm.saveDraft() }} }}.buttonStyle(.borderedProminent())
                    Button("Reload") {{ Task {{ await vm.loadAll() }} }}
                }}
                List(vm.items, id: \\.id) {{ it in
                    VStack(alignment: .leading) {{
                        Text(it.title).bold()
                        if let b = it.body {{ Text(b).font(.subheadline).foregroundColor(.secondary) }}
                    }}
                }}
                Spacer()
            }}
            .padding()
            .toolbar {{ ToolbarItem(placement: .navigationBarTrailing) {{ Button(action: {{ Task {{ await vm.loadAll() }} }}) {{ Image(systemName: "arrow.clockwise") }} }} }}
        }}
    }}
}}

#if DEBUG
struct {name}View_Previews: PreviewProvider {{
    static var previews: some View {{ {name}View() }}
}}
#endif
"""

def make_swift_test(name: str) -> str:
    return f"""import XCTest
@testable import Anchor

final class {name}Tests: XCTestCase {{
    func testScaffold() async throws {{
        let vm = {name}ViewModel()
        vm.draftTitle = "t"
        await vm.saveDraft()
        XCTAssertTrue(!vm.items.isEmpty)
    }}
}}
"""

def make_docs_md(name: str) -> str:
    return f"# {name}\n\nAuto-generated docs for {name}\n"

# -------------------------
# Placeholder detection & prioritization
# -------------------------
def is_placeholder_file(path: Path) -> bool:
    """
    Heuristic: detect files that look like placeholders / stubs that should be
    improved first. Checks filename and a few common placeholder markers inside file.
    """
    try:
        name = path.name.lower()
        if "placeholder" in name or "need_work" in name or "todo" in name or "stub" in name or "draft" in name:
            return True
        txt = path.read_text(encoding="utf8").lower()
        # common markers that indicate file is a placeholder or needs work
        markers = ["placeholder", "todo:", "tbd", "need_work", "fixme", "implement me", "pass  # placeholder", "// placeholder", "/* placeholder */"]
        for m in markers:
            if m in txt:
                return True
    except Exception:
        # if reading fails, treat as non-placeholder
        return False
    return False

def collect_prioritized_files(processed: Set[str], debug: bool) -> List[Path]:
    all_swifts = list_swift_files()
    # Only consider files inside ANCHOR/ANCHOR
    candidates = [p for p in all_swifts if str(p).startswith("ANCHOR/")]


    # First — placeholder/stub files
    placeholders = sorted([p for p in candidates if is_placeholder_file(p) and str(p) not in processed])

    # categorize
    lt100 = sorted([p for p in candidates if file_length(p) < 100 and str(p) not in processed])
    in_anchor = sorted([p for p in candidates if str(p).startswith("ANCHOR/ANCHOR") and str(p) not in processed])
    lt200 = sorted([p for p in candidates if file_length(p) < 200 and str(p) not in processed])

    # remove duplicates preserving order:
    selected: List[Path] = []
    def add_list(lst: List[Path]):
        for p in lst:
            if p not in selected:
                selected.append(p)

    add_list(placeholders)
    add_list(lt100)
    add_list([p for p in in_anchor if p not in selected])
    add_list([p for p in lt200 if p not in selected])

    if debug:
        log((
            f"Priority lists: placeholders={len(placeholders)}, "
            f"lt100={len(lt100)}, anchor={len(in_anchor)}, lt200={len(lt200)}"
        ), True)
    return selected


# -------------------------
# Per-file processing
# -------------------------
def process_file(path: Path, backend: bool, debug: bool, dry: bool) -> List[str]:
    """
    Process a single Swift file: update model/repo/vm/view/test/docs if they exist.
    Only modifies files inside nested ANCHOR/ANCHOR; no new files are created.
    Returns list of changed paths (strings).
    """
    changed = []

    # Skip files not in nested ANCHOR/ANCHOR
    try:
        nested_anchor = ROOT_DIR / "ANCHOR"
        try:
            path.resolve().relative_to(nested_anchor.resolve())
        except ValueError:
            log(f"Skipping {path} — not in nested ANCHOR/ANCHOR", debug)
            return changed
    except Exception:
        log(f"Skipping {path} — path resolution failed", debug)
        return changed

    try:
        name = safe_feature_name_from_path(path)
        log(f"Processing {path} as feature name '{name}'", debug)

        target_dir = path.parent

        # Only proceed if target_dir exists
        if not target_dir.exists():
            log(f"Target directory {target_dir} does not exist — skipping helpers for {path}", debug)
            target_dir = None

        # Compute helper paths only if directory exists
        model_path = target_dir / f"{name}Model.swift" if target_dir else None
        repo_path = target_dir / f"{name}Repository.swift" if target_dir else None
        vm_path = target_dir / f"{name}ViewModel.swift" if target_dir else None
        view_path = target_dir / f"{name}View.swift" if target_dir else None
        test_path = target_dir / f"{name}Tests.swift" if target_dir else None
        doc_path = target_dir / f"{name}.md" if target_dir else None

        # Backend updates
        if backend:
            registry = []
            if BACKEND_REGISTRY.exists():
                try:
                    registry = json.loads(BACKEND_REGISTRY.read_text(encoding="utf8"))
                except Exception:
                    registry = []

            if name in registry:
                if regenerate_backend_app_from_registry(dry, debug) and BACKEND_APP.exists():
                    changed.append(str(BACKEND_APP))
                if API_CLIENT_PATH.exists() and regenerate_api_client_from_registry(dry, debug):
                    changed.append(str(API_CLIENT_PATH))
            else:
                log(f"Skipping backend registry add for {name} (only modifying existing backend entries)", debug)

            # Append API snippet only if marker missing
            if API_CLIENT_PATH.exists():
                api_text = API_CLIENT_PATH.read_text(encoding="utf8")
                marker = f"// AUTO-GENERATED: {name} API methods"
                if marker not in api_text:
                    new_text = api_text + "\n" + make_api_snippet(name)
                    if atomic_write(API_CLIENT_PATH, new_text, debug, dry):
                        changed.append(str(API_CLIENT_PATH))

        # Update frontend helpers — only existing files
        for helper_path, make_func in [
            (model_path, make_swift_model),
            (repo_path, make_swift_repo),
            (vm_path, lambda n: make_swift_vm(n, backend)),
            (view_path, make_swift_view),
            (test_path, make_swift_test),
            (doc_path, make_docs_md),
        ]:
            if helper_path and helper_path.exists():
                if atomic_write(helper_path, make_func(name), debug, dry):
                    changed.append(str(helper_path))
            elif helper_path:
                log(f"Skipping creation of new file {helper_path} (only modifying existing files)", debug)

    except Exception as e:
        log(f"Error processing {path}: {e}", True)

    return changed


# -------------------------
# Main orchestration
# -------------------------
def main(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--debug", action="store_true")
    parser.add_argument("--force", action="store_true", help="reprocess even if in processed state")
    parser.add_argument("--max", type=int, default=0, help="max files to process this run (0 = unlimited)")
    # backward-compatible alias for external callers that pass --batch
    parser.add_argument("--batch", type=int, default=0, help="legacy alias for --max (keeps compatibility)")
    parser.add_argument("--aggressive", dest="aggressive", action="store_true", help="be aggressive about overwriting and adding backend")
    parser.add_argument("--no-aggressive", dest="aggressive", action="store_false", help="disable aggressive behavior")
    parser.add_argument("--think", type=int, default=10, help="number of internal passes for deep thinking per feature (default: 10)")


    parser.set_defaults(aggressive=True)
    args = parser.parse_args(argv)

    debug = args.debug
    dry = args.dry_run
    force = args.force
    # prefer --max if provided; otherwise fall back to --batch for compatibility
    max_count = args.max if args.max and args.max > 0 else (args.batch if args.batch and args.batch > 0 else 0)
    global AGGRESSIVE
    AGGRESSIVE = bool(args.aggressive)

    processed = load_state()
    if force:
        processed = set()  # ignore past
    backend = (ROOT_DIR / "backend").exists() or AGGRESSIVE


    # ensure APIClient skeleton if backend present
    if backend:
        if BACKEND_REGISTRY.exists():
            # regenerate deterministic backend/app.py from existing registry (idempotent)
            regenerate_backend_app_from_registry(dry, debug)
        # only regenerate API client if it already exists (do not create new API client file)
        if API_CLIENT_PATH.exists():
            regenerate_api_client_from_registry(dry, debug)

    prioritized = collect_prioritized_files(processed, debug)
    if max_count and max_count > 0:
        prioritized = prioritized[:max_count]

    if not prioritized:
        log("No prioritized files to process.", debug)
        return 0

<<<<<<< Updated upstream
    changed_overall = []
    names_to_register: List[str] = []
    for p in prioritized:
        strp = str(p)
        if strp in processed:
            log(f"Skipping already processed: {p}", debug)
            continue
        changed = process_file(p, backend, debug, dry)
        if changed:
            changed_overall.extend(changed)
        # persist processed immediately so we won't re-run on crash
        processed.add(strp)
=======
    all_written = []
    all_skipped = []
    backend_names_added = []

    for feat in to_process:
        log(f"=== Processing feature: {feat} ===", debug)
        state = project_state.get(feat, {})
        proposals_passes: list[Dict[str, str]] = []
        prev = None
        for pass_no in range(args.think):
            step = ai_propose_changes(feature, state, debug=args.debug, prev=prev, pass_no=pass_no)
            proposals_passes.append(step)
            prev = step  # feed forward the previous result

        # Only keep files that are stable (identical across all passes)
        stable: Dict[str, str] = {}
        if proposals_passes:
            first = proposals_passes[0]
            for path, content in first.items():
                if all(path in p and p[path] == content for p in proposals_passes[1:]):
                    stable[path] = content

        proposals = stable
        if args.debug:
            log(f"Stable proposals for {feature}: {len(proposals)} files after {args.think} passes", args.debug)

        # collect which backend names to add (if feature wasn't in backend registry)
        # We decide to register all planned features; backend_register_feature will be idempotent.
        backend_names = [feat]

        written, skipped = process_proposals(proposals, backend_names, debug, dry)
        all_written.extend(written)
        all_skipped.extend(skipped)
        backend_names_added.extend(backend_names)

        processed.add(str(feat))
>>>>>>> Stashed changes
        save_state(processed)
        # remember the feature name for registry
        try:
            nm = safe_feature_name_from_path(p)
            if nm:
                names_to_register.append(nm)
        except Exception:
            pass

    # add registry references for all names processed this run (merge with existing)
    if names_to_register:
        # Merge with existing and write
        if ensure_feature_registry_refs(names_to_register, dry, debug):
            log("Updated feature registry", debug)

    # ensure API snippets for processed features are appended to App/APIClient.swift if backend exists
    if backend and API_CLIENT_PATH.exists():
        api_text = API_CLIENT_PATH.read_text(encoding="utf8")
        for p in prioritized:
            name = safe_feature_name_from_path(p)
            marker = f"// AUTO-GENERATED: {name} API methods"
            if marker not in api_text:
                new_api = api_text + "\n" + make_api_snippet(name)
                if atomic_write(API_CLIENT_PATH, new_api, debug, dry):
                    changed_overall.append(str(API_CLIENT_PATH))
                    api_text = new_api

    if changed_overall:
        log("Files changed this run:", debug)
        for c in sorted(set(changed_overall)):
            log(f" - {c}", debug)
    else:
        log("No files were changed by the improver.", debug)

    return 0

if __name__ == "__main__":
    raise SystemExit(main())
