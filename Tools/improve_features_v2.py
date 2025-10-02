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

BACKEND_APP = Path("backend") / "app.py"
BACKEND_REGISTRY = Path("backend") / "_registry.json"
API_CLIENT_PATH = Path("App") / "APIClient.swift"
FEATURE_REGISTRY = Path("App") / "FeatureRegistry.swift"
WRITTEN_HASHES = LOG_DIR / "written_hashes.json"

# Default: aggressive ON (per your request). CLI exposes --no-aggressive to disable.
AGGRESSIVE = True

# -------------------------
# Utilities
# -------------------------
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
        path.parent.mkdir(parents=True, exist_ok=True)
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
    """List all Swift files in the repo excluding Pods and Xcode build dirs."""
    return sorted([p for p in Path(".").rglob("*.swift") if "Pods/" not in str(p) and ".build" not in str(p) and "Carthage/" not in str(p)])

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
    """Search across many text files for a pattern. Returns matching paths as strings."""
    out = []
    for p in list_swift_files():
        try:
            txt = p.read_text(encoding="utf8")
            if re.search(pattern, txt):
                out.append(str(p))
        except Exception:
            pass
    # also search other files (Objective-C, xcodeproj, SwiftPM) – limited scanning
    for p in Path(".").rglob("*"):
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
    # exclude Tools and Pods
    candidates = [p for p in all_swifts if not str(p).startswith("Tools/") and not "Pods/" in str(p)]
    # First — placeholder/stub files (new behavior)
    placeholders = sorted([p for p in candidates if is_placeholder_file(p) and str(p) not in processed])

    # categorize
    lt100 = sorted([p for p in candidates if file_length(p) < 100 and str(p) not in processed])
    in_features = sorted([p for p in candidates if is_in_app_features(p) and str(p) not in processed])
    lt200 = sorted([p for p in candidates if file_length(p) < 200 and str(p) not in processed])

    # remove duplicates preserving order:
    # placeholders first, then lt100, then App/Features, then lt200 (as before)
    selected: List[Path] = []
    def add_list(lst: List[Path]):
        for p in lst:
            if p not in selected:
                selected.append(p)

    add_list(placeholders)
    add_list(lt100)
    add_list([p for p in in_features if p not in selected])
    add_list([p for p in lt200 if p not in selected])

    if debug:
        log((
            f"Priority lists: placeholders={len(placeholders)}, "
            f"lt100={len(lt100)}, features={len(in_features)}, lt200={len(lt200)}"
        ), True)
    return selected

# -------------------------
# Per-file processing
# -------------------------
def process_file(path: Path, backend: bool, debug: bool, dry: bool) -> List[str]:
    """
    Process a single swift file: create model/repo/vm/view/test/docs where appropriate
    placed in the same directory as the file (or App/Features when file is inside there).
    Returns list of changed paths (strings).
    """
    changed = []
    try:
        name = safe_feature_name_from_path(path)
        log(f"Processing {path} as feature name '{name}'", debug)
        # determine target dir: prefer path.parent for helpers, but for view files in App/Features keep same dir
        target_dir = path.parent if path.parent != Path('.') else Path("App/Features")
        # do NOT create missing target directories when not allowed to add files
        if not target_dir.exists():
            log(f"Target directory {target_dir} does not exist — skipping helper writes for {path}", debug)
            # set to None so later existence checks avoid accidental creates
            target_dir = None


        # target file paths
        model_path = target_dir / f"{name}Model.swift"
        repo_path = target_dir / f"{name}Repository.swift"
        vm_path = target_dir / f"{name}ViewModel.swift"
        view_path = target_dir / f"{name}View.swift"
        test_dir = Path("Tests") / "Features"
        test_dir.mkdir(parents=True, exist_ok=True)
        test_path = test_dir / f"{name}Tests.swift"
        docs_dir = Path("Docs")
        docs_dir.mkdir(parents=True, exist_ok=True)
        doc_path = docs_dir / f"Feature_{name}.md"

        # backend first
                # backend first — do NOT add new features to the backend registry.
        # Only regenerate backend/app.py or API client if the registry already contains the feature.
        if backend:
            registry = []
            if BACKEND_REGISTRY.exists():
                try:
                    registry = json.loads(BACKEND_REGISTRY.read_text(encoding="utf8"))
                except Exception:
                    registry = []

            if name in registry:
                # registry already declares this feature — ensure backend/app.py is regenerated
                if regenerate_backend_app_from_registry(dry, debug):
                    if BACKEND_APP.exists():
                        changed.append(str(BACKEND_APP))
                # if API client exists, regenerate it deterministically from registry
                if API_CLIENT_PATH.exists():
                    if regenerate_api_client_from_registry(dry, debug):
                        changed.append(str(API_CLIENT_PATH))
            else:
                log(f"Skipping backend registry add for {name} (only modifying existing backend entries)", debug)


        # write API client if needed
        if backend:
            if ensure_api_client(dry, debug):
                changed.append(str(API_CLIENT_PATH))
            # append snippet to APIClient.swift if missing marker
            if API_CLIENT_PATH.exists():
                api_text = API_CLIENT_PATH.read_text(encoding="utf8")
                marker = f"// AUTO-GENERATED: {name} API methods"
                if marker not in api_text:
                    new_text = api_text + "\n" + make_api_snippet(name)
                    if atomic_write(API_CLIENT_PATH, new_text, debug, dry):
                        changed.append(str(API_CLIENT_PATH))

        # write frontend helpers in target_dir — ONLY update existing files; do NOT create new ones
        if model_path.exists():
            if atomic_write(model_path, make_swift_model(name), debug, dry):
                changed.append(str(model_path))
        else:
            log(f"Skipping create of new file {model_path} (only modifying existing files)", debug)

        if repo_path.exists():
            if atomic_write(repo_path, make_swift_repo(name), debug, dry):
                changed.append(str(repo_path))
        else:
            log(f"Skipping create of new file {repo_path} (only modifying existing files)", debug)

        if vm_path.exists():
            if atomic_write(vm_path, make_swift_vm(name, backend), debug, dry):
                changed.append(str(vm_path))
        else:
            log(f"Skipping create of new file {vm_path} (only modifying existing files)", debug)

        if view_path.exists():
            if atomic_write(view_path, make_swift_view(name), debug, dry):
                changed.append(str(view_path))
        else:
            log(f"Skipping create of new file {view_path} (only modifying existing files)", debug)

        if test_path.exists():
            if atomic_write(test_path, make_swift_test(name), debug, dry):
                changed.append(str(test_path))
        else:
            log(f"Skipping create of new file {test_path} (only modifying existing files)", debug)

        if doc_path.exists():
            if atomic_write(doc_path, make_docs_md(name), debug, dry):
                changed.append(str(doc_path))
        else:
            log(f"Skipping create of new file {doc_path} (only modifying existing files)", debug)


    except Exception as e:
        log(f"error processing {path}: {e}", True)
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
    backend = Path("backend").exists() or AGGRESSIVE

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
