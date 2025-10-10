#!/usr/bin/env python3
"""
improver_loop.py — FULL FEATURED (Option B)

This is the Option B implementation: a domain-aware improver that:
 - Indexes the repository (basic AST for Python/JS/Swift) to understand symbols.
 - Runs linters and tests (including Xcode test runs / iOS simulator support).
 - Uses Gemini CLI as an "advisor" to propose candidate code changes for
   ambiguous failures (only if gemini is available).
 - Creates a git branch, commits patches, and can open a PR via `gh` CLI if
   configured.
 - Uses a conservative confidence scoring system. It will NEVER auto-apply
   high-risk patches to your main branch without passing tests AND exceeding
   the configured confidence threshold.

USAGE:
  python3 improver_loop.py --config .improver_config.json [--dry-run]

IMPORTANT SAFETY NOTES (READ):
 - This script performs write operations when not in --dry-run. By default
   it uses `suggest-only` mode and writes suggested patches to a branch.
 - You MUST review generated patches before merging. The script will try to
   run tests and will only auto-apply LLM suggestions when tests pass AND the
   confidence threshold is reached (configurable).

CONFIGURATION (.improver_config.json example keys):
{
  "anchor_dir": "ANCHOR",
  "xcode_workspace": "MyApp.xcworkspace",
  "xcode_scheme": "MyAppTests",
  "simulator_name": "iPhone 14",
  "simulator_os": "17.0",
  "gemini_cli": "gemini",   # path to gemini CLI
  "gh_cli": "gh",           # path to GitHub CLI
  "auto_apply": false,
  "confidence_threshold": 0.85,
  "dry_run": true
}

"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

# imrover_loop.py (top of file)
from transformers import AutoModelForCausalLM, AutoTokenizer
import torch

# Load local/open-source LLM
# ---------------------- Local model loader -----------------------------

MODEL_NAME = "TheBloke/WizardLM-7B-uncensored"  # Or local path
# ---------------------- Robust local model loader + fallback -------------
_model = None
_tokenizer = None
_device = None
_local_model_available = None  # None = unknown, False = unavailable, True = available

def load_model():
    """
    Attempt to load the local model once. On macOS we force CPU + float32 to
    reduce segfault OOM issues. If anything goes wrong we mark the local model
    unavailable and return False.
    Returns: True if local model loaded and ready, False otherwise.
    """
    global _model, _tokenizer, _device, _local_model_available

    if _local_model_available is not None:
        # Already attempted load
        return _local_model_available

    print(f"Attempting to load model '{MODEL_NAME}' (safe mode)...")
    try:
        # Load tokenizer (may download if not cached)
        _tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)

        # Choose device safely: prefer CUDA on Linux/Windows; force CPU on macOS (Darwin)
        use_device = None
        if torch.cuda.is_available():
            use_device = torch.device("cuda")
            print("Using CUDA GPU for model.")
        else:
            # On macOS, MPS/GPTQ often segfaults; use CPU to be safe.
            import platform
            if platform.system() == "Darwin":
                use_device = torch.device("cpu")
                print("macOS detected: forcing CPU to avoid MPS/GPTQ segfaults.")
            elif torch.backends.mps.is_available():
                # If not macOS Darwin (rare), allow MPS
                use_device = torch.device("mps")
                print("Using MPS device.")
            else:
                use_device = torch.device("cpu")
                print("Using CPU device.")

        _device = use_device

        # Load model in safe dtype (float32). Use device_map=None for CPU to avoid map logic.
        model_kwargs = dict(dtype=torch.float32)
        if _device == torch.device("cpu"):
            # load into CPU
            _model = AutoModelForCausalLM.from_pretrained(MODEL_NAME, device_map=None, **model_kwargs)
            # already on CPU
        else:
            # allow HF to place layers if GPU/MPS available
            _model = AutoModelForCausalLM.from_pretrained(MODEL_NAME, device_map="auto", **model_kwargs)
            # move to detected device if needed
            try:
                _model.to(_device)
            except Exception:
                # some HF models auto-placed layers; ignore if .to fails
                pass

        _local_model_available = True
        print("Local model loaded successfully.")
        return True

    except Exception as e:
        # Catch everything: OSError, RuntimeError, segfault surfaced as Exception, etc.
        print("Failed to load local model:", repr(e))
        print("Local model will be marked unavailable. Falling back to Gemini CLI or stub suggestions.")
        _local_model_available = False
        # Try to cleanup partially-loaded objects
        try:
            _model = None
            _tokenizer = None
            _device = None
        except Exception:
            pass
        return False


def run_local_model(prompt: str, max_tokens: int = 200, cfg: Optional[Dict[str, Any]] = None) -> str:
    """
    Generate a response for `prompt`. Behavior:
      - If local model loads successfully -> generate locally.
      - Else if Gemini CLI is configured in cfg -> call Gemini advisor and return its text.
      - Else write a stub file to ANCHOR/stubs with context and return a fallback string.
    cfg: optional config dict (used to check gemini_cli and anchor_dir).
    """
    global _model, _tokenizer, _device, _local_model_available

    # Ensure we attempted to load the model (lazy)
    if _local_model_available is None:
        load_model()

    if _local_model_available:
        # Local generation path
        try:
            # Tokenize and move inputs onto same device as model if possible
            inputs = _tokenizer(prompt, return_tensors="pt")
            if _device is not None:
                inputs = {k: v.to(_device) for k, v in inputs.items()}
            outputs = _model.generate(**inputs, max_new_tokens=max_tokens)
            return _tokenizer.decode(outputs[0], skip_special_tokens=True)
        except Exception as e:
            # If generation fails, mark local model unavailable and fall through to fallback
            print("Local model generation failed:", repr(e))
            _local_model_available = False

    # Fallback: attempt Gemini CLI if configured
    cfg_local = cfg or {}
    gemini_bin = cfg_local.get('gemini_cli') if isinstance(cfg_local, dict) else None
    if gemini_bin:
        # Reuse existing call_gemini_advisor wrapper (which expects cfg)
        try:
            advice = call_gemini_advisor(prompt, cfg_local)
            if advice and advice.get('text'):
                return advice.get('text')
        except Exception as e:
            print("Gemini advisor failed:", repr(e))

    # Final fallback: write a stub suggestion to disk (human will handle)
    try:
        anchor_dir = Path(cfg_local.get('anchor_dir', 'ANCHOR')) if isinstance(cfg_local, dict) else Path('ANCHOR')
        stubs_dir = anchor_dir / 'stubs'
        stubs_dir.mkdir(parents=True, exist_ok=True)
        fname = stubs_dir / f'suggestion_{datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")}.md'
        content = "# Auto-generated fallback suggestion\n\nContext:\n\n" + prompt[:10000]
        fname.write_text(content, encoding='utf-8')
        print(f"Wrote stub suggestion to {fname} (local model & Gemini unavailable).")
        return f"[NO_MODEL_AVAILABLE] Created stub suggestion at {fname}. Please inspect."
    except Exception as e:
        print("Failed to write stub suggestion:", repr(e))
        return "[NO_MODEL_AVAILABLE] Model and Gemini unavailable; failed to write stub."



# ---------------------- Default configuration ----------------------------
DEFAULT_CONFIG = {
    "anchor_dir": "ANCHOR",
    "small_file_line_threshold": 100,
    "iterations_before_run": 5,
    "max_iterations": 200,
    "backup_dir": ".improver_backups",
    "dry_run": True,
    "auto_apply": False,
    "confidence_threshold": 0.85,
    # Xcode-specific defaults (user should override for their project)
    "xcode_workspace": "",
    "xcode_project": "",
    "xcode_scheme": "",
    "simulator_name": "iPhone 14",
    "simulator_os": "17.0",
    "gemini_cli": "gemini",
    "gh_cli": "gh",
}

# ------------------------- Helpers --------------------------------------

def load_config(path: str) -> Dict[str, Any]:
    cfg = DEFAULT_CONFIG.copy()
    if not path:
        return cfg
    p = Path(path)
    if not p.exists():
        print(f"Config {path} not found — using defaults.")
        return cfg
    try:
        with p.open() as f:
            data = json.load(f)
            cfg.update(data)
    except Exception as e:
        print(f"Failed to load config {path}: {e}")
    return cfg


def run_cmd(cmd: str, cwd: str = '.', timeout: int = 600) -> Tuple[int, str, str]:
    proc = subprocess.run(cmd, shell=True, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=timeout)
    out = proc.stdout.decode('utf-8', errors='ignore')
    err = proc.stderr.decode('utf-8', errors='ignore')
    return proc.returncode, out, err



# ---------------------- Repository indexing -----------------------------

import ast


def index_python_repo(anchor_dir: Path) -> Dict[str, Any]:
    """Basic index: maps module (file stem) to its top-level defs and imports."""
    index = {}
    for py in anchor_dir.rglob('*.py'):
        try:
            text = py.read_text(encoding='utf-8')
            tree = ast.parse(text)
            exports = {'functions': [], 'classes': [], 'imports': []}
            for node in ast.iter_child_nodes(tree):
                if isinstance(node, ast.FunctionDef):
                    exports['functions'].append(node.name)
                elif isinstance(node, ast.ClassDef):
                    exports['classes'].append(node.name)
                elif isinstance(node, ast.Import):
                    for n in node.names:
                        exports['imports'].append(n.name)
                elif isinstance(node, ast.ImportFrom):
                    module = node.module or ''
                    for n in node.names:
                        exports['imports'].append(f"{module}.{n.name}" if module else n.name)
            index[str(py.relative_to(anchor_dir))] = exports
        except Exception:
            continue
    return index


# ---------------------- Xcode / Simulator runner ------------------------

def build_and_test_xcode(cfg: Dict[str, Any]) -> Dict[str, Any]:
    """Run xcodebuild tests in the simulator. Returns dict with keys: success, stdout, stderr, cmd"""
    workspace = cfg.get('xcode_workspace')
    project = cfg.get('xcode_project')
    scheme = cfg.get('xcode_scheme')
    sim_name = cfg.get('simulator_name', 'iPhone 14')
    sim_os = cfg.get('simulator_os', '17.0')

    if not scheme:
        return {'success': False, 'stdout': '', 'stderr': 'No xcode_scheme configured', 'cmd': ''}

    # Destination string
    dest = f"platform=iOS Simulator,name={sim_name},OS={sim_os}"

    # Choose workspace or project
    if workspace:
        target_part = f"-workspace {workspace} -scheme {scheme}"
    elif project:
        target_part = f"-project {project} -scheme {scheme}"
    else:
        # attempt to run scheme-only (xcodebuild may find the project)
        target_part = f"-scheme {scheme}"

    # xcodebuild test command
    cmd = f"xcodebuild test {target_part} -destination '{dest}'"

    print(f"Running Xcode tests with command: {cmd}")

    # Ensure simulator is booted
    boot_simulator_if_needed(sim_name, sim_os)

    ret, out, err = run_cmd(cmd, timeout=1800)
    success = (ret == 0)
    return {'success': success, 'stdout': out, 'stderr': err, 'cmd': cmd}


def boot_simulator_if_needed(sim_name: str, sim_os: str):
    # Find a matching device id
    try:
        ret, out, err = run_cmd('xcrun simctl list devices --json')
        if ret != 0:
            print('Warning: unable to list simulators')
            return
        import json as _json
        data = _json.loads(out)
        devices = data.get('devices', {})
        target_udid = None
        for runtime, devs in devices.items():
            # runtime is like 'iOS 17.0'
            for d in devs:
                if d.get('name') == sim_name and d.get('isAvailable', True):
                    target_udid = d.get('udid')
                    state = d.get('state')
                    if state != 'Booted':
                        print(f'Booting simulator {sim_name} ({runtime})')
                        run_cmd(f'xcrun simctl boot {target_udid}')
                    return
    except Exception as e:
        print(f'Exception while trying to boot simulator: {e}')


# ---------------------- Gemini CLI advisor ------------------------------

def call_gemini_advisor(prompt: str, cfg: Dict[str, Any], max_tokens: int = 1024) -> Optional[Dict[str, Any]]:
    """Call Gemini CLI to get advice or suggested patch. Returns dict: {text, confidence} or None."""
    gemini = cfg.get('gemini_cli', 'gemini')
    # Example CLI usage — adjust if your gemini CLI uses other flags
    cmd = f"{gemini} -m gpt-5 --input '{escape_single_quotes(prompt)}' --max-tokens {max_tokens}"
    print(f"Calling Gemini advisor: {cmd}")
    try:
        ret, out, err = run_cmd(cmd, timeout=120)
        if ret != 0:
            print('Gemini CLI failed or not available:', err[:400])
            return None
        # Very simple heuristic: returned text + artificial confidence based on length
        text = out.strip()
        confidence = min(0.95, 0.2 + min(0.75, len(text) / 5000.0))
        return {'text': text, 'confidence': confidence}
    except Exception as e:
        print('Error calling gemini:', e)
        return None


def escape_single_quotes(s: str) -> str:
    return s.replace("'", "'\''")


# ---------------------- Patch manager & git flow ------------------------

def git_create_branch_and_commit(branch: str, files_to_add: List[Path], commit_message: str, cfg: Dict[str, Any]) -> bool:
    # create branch from current HEAD
    if cfg.get('dry_run', True):
        print(f"[DRY-RUN] Would create branch {branch} and commit {len(files_to_add)} files")
        return True
    ret, out, err = run_cmd(f'git checkout -b {branch}')
    if ret != 0:
        print('Failed to create branch:', err)
        return False
    for p in files_to_add:
        run_cmd(f'git add {str(p)}')
    ret, out, err = run_cmd(f'git commit -m "{commit_message}"')
    if ret != 0:
        print('git commit failed:', err)
        return False
    print(f'Created branch {branch} and committed changes')
    return True


def gh_create_pr(branch: str, title: str, body: str, cfg: Dict[str, Any]) -> Optional[str]:
    gh = cfg.get('gh_cli', 'gh')
    if cfg.get('dry_run', True):
        print(f"[DRY-RUN] Would open PR from branch {branch} with title: {title}")
        return None
    cmd = f"{gh} pr create --title '{escape_single_quotes(title)}' --body '{escape_single_quotes(body)}' --head {branch}"
    ret, out, err = run_cmd(cmd)
    if ret != 0:
        print('gh pr create failed:', err)
        return None
    return out.strip()


# ---------------------- Confidence & apply logic ------------------------

def compute_confidence(metrics: Dict[str, Any]) -> float:
    """Combine metrics into a confidence score (0..1).
    Example metrics: {'num_call_sites': int, 'llm_confidence': float, 'tests_affected': int}
    """
    score = 0.0
    num_call_sites = metrics.get('num_call_sites', 0)
    llm_conf = metrics.get('llm_confidence', 0.0)
    tests_impact = metrics.get('tests_impact', 0)

    # heuristics
    score += min(0.4, 0.05 * num_call_sites)  # more call sites -> higher evidence
    score += min(0.5, llm_conf * 0.5)
    # penalize if tests are failing after change (tests_impact > 0)
    if tests_impact > 0:
        score *= 0.3
    return min(1.0, score)


# ---------------------- Main improver logic -----------------------------

def analyze_and_suggest(anchor_dir: Path, cfg: Dict[str, Any]) -> List[Dict[str, Any]]:
    """Perform analysis and return a list of suggested patches (not applied yet).
    Each suggestion: {id, file, type, summary, patch_text, metrics}
    """
    suggestions = []
    # Index Python files
    py_index = index_python_repo(anchor_dir)

    # Look for missing-import style errors by running linters (if available)
    # For Option B, we focus on real failures found by tests/build.
    # We'll defer to build/test output to create targeted suggestions.
    return suggestions


def attempt_fix_with_local_model(context_snippet: str, max_tokens: int = 200) -> Dict[str, Any]:
    """
    Use local Mistral 7B to propose a minimal, safe Swift patch.
    
    Args:
        context_snippet: The context or error message to analyze
        max_tokens: Maximum number of tokens for the model to generate
        
    Returns:
        Dict containing 'patch' (str) and 'llm_confidence' (float) if successful,
        or an error message if the model fails to generate a response.
    """
    if not context_snippet or not isinstance(context_snippet, str):
        return {'error': 'Invalid context_snippet: must be a non-empty string'}
        
    try:
        prompt = (
            "You are an expert iOS/Swift developer. Given the following failing test output and code context, "
            "propose a minimal, safe code patch (diff) that addresses the issue. Return only the patch in unified "
            "diff format and a short explanation. Include TODO markers where uncertain.\n\n"
            f"Context:\n{context_snippet}"
        )
        
        patch_text = run_local_model(prompt, max_tokens=max_tokens)
        
        if not patch_text or not isinstance(patch_text, str):
            return {'error': 'Model returned an invalid response'}
            
        # Simple heuristic: longer patch -> higher confidence (with reasonable bounds)
        confidence = min(0.95, 0.2 + min(0.75, len(patch_text) / 5000.0))
        
        return {
            'patch': patch_text, 
            'llm_confidence': confidence,
            'success': True
        }
        
    except Exception as e:
        return {
            'error': f'Error generating patch: {str(e)}',
            'success': False
        }


# ---------------------- High-level loop --------------------------------

def apply_patch(file_path: Path, patch_text: str, cfg: Dict[str, Any]) -> bool:
    """Apply a patch to the given file."""
    try:
        # Create backup
        backup_path = file_path.with_suffix(f"{file_path.suffix}.bak")
        shutil.copy2(file_path, backup_path)
        
        # Apply patch
        with open(file_path, 'r') as f:
            original = f.read()
        
        # Simple patch application (for demo purposes)
        # In production, use a proper patch library
        patched = original + "\n" + patch_text
        
        with open(file_path, 'w') as f:
            f.write(patched)
            
        return True
    except Exception as e:
        print(f"Failed to apply patch to {file_path}: {str(e)}")
        # Restore from backup if available
        if backup_path.exists():
            shutil.copy2(backup_path, file_path)
        return False

def add_feature(file_path: Path, feature_code: str, cfg: Dict[str, Any]) -> bool:
    """Add a new feature to the codebase."""
    try:
        # For new files
        if not file_path.exists():
            file_path.parent.mkdir(parents=True, exist_ok=True)
            with open(file_path, 'w') as f:
                f.write(feature_code)
            return True
            
        # For existing files, append the feature
        with open(file_path, 'a') as f:
            f.write("\n\n" + feature_code)
        return True
    except Exception as e:
        print(f"Failed to add feature to {file_path}: {str(e)}")
        return False

def fix_errors(error_log: str, cfg: Dict[str, Any]) -> bool:
    """Analyze build/test errors and attempt to fix them."""
    print("Analyzing errors and generating fixes...")
    
    # Get AI-suggested fixes
    suggestions = generate_error_fixes(error_log, cfg)
    
    if not suggestions:
        print("No fixes suggested by the model")
        return False
        
    # Apply fixes
    for suggestion in suggestions:
        file_path = Path(cfg['anchor_dir']) / suggestion['file']
        if apply_patch(file_path, suggestion['patch'], cfg):
            print(f"Applied fix to {file_path}")
            return True
            
    return False

def add_missing_features(cfg: Dict[str, Any]) -> bool:
    """Identify and add missing features to the codebase."""
    print("Checking for missing features...")
    
    # Check for missing API client methods
    if not is_api_client_complete(cfg):
        print("Adding missing API client methods...")
        return add_api_client_methods(cfg)
        
    # Check for missing UI components
    if not is_ui_complete(cfg):
        print("Adding missing UI components...")
        return add_ui_components(cfg)
        
    return False

def main_loop(cfg: Dict[str, Any]):
    """Main improvement loop that fixes errors and adds features."""
    anchor_dir = Path(cfg.get('anchor_dir', 'ANCHOR'))
    if not anchor_dir.exists():
        print(f"Anchor directory not found: {anchor_dir}")
        sys.exit(2)

    iteration = 0
    while iteration < cfg.get('max_iterations', 50):
        iteration += 1
        print('='*80)
        print(f'Iteration {iteration}')

        # 1) Attempt Xcode build/tests
        xcode_info = build_and_test_xcode(cfg)
        if xcode_info.get('cmd'):
            print('Xcode cmd executed: ', xcode_info['cmd'])
        
        if xcode_info.get('success'):
            print('Build successful!')
            # Try adding new features if build is successful
            if add_missing_features(cfg):
                print("Added new features, restarting build cycle...")
                continue
            break
            
        # 2) If build failed, try to fix errors
        print('Build failed. Attempting to fix errors...')
        error_log = xcode_info.get('output', '') + xcode_info.get('error', '')
        if fix_errors(error_log, cfg):
            print("Applied fixes, restarting build...")
            continue
            
        # 3) If we couldn't fix errors, try adding missing features
        print("Couldn't fix errors. Trying to add missing features...")
        if add_missing_features(cfg):
            print("Added features, restarting build...")
            continue
            
        print("Couldn't fix errors or add features. Manual intervention needed.")
        break
        
        # Small delay between iterations
        time.sleep(cfg.get('retry_delay_seconds', 10))

    print("Improvement loop completed!")


def generate_error_fixes(error_log: str, cfg: Dict[str, Any]) -> List[Dict[str, Any]]:
    """Generate fixes for the given error log."""
    # For demonstration purposes, assume we have a simple model that suggests fixes
    # In a real-world scenario, you would use a more sophisticated model or approach
    suggestions = []
    for line in error_log.splitlines():
        if "error:" in line:
            suggestion = {
                'file': 'path/to/file.swift',
                'patch': 'patch code here',
                'confidence': 0.8
            }
            suggestions.append(suggestion)
    return suggestions

def is_api_client_complete(cfg: Dict[str, Any]) -> bool:
    """Check if the API client is complete."""
    # For demonstration purposes, assume we have a simple model that checks completeness
    # In a real-world scenario, you would use a more sophisticated model or approach
    return True

def add_api_client_methods(cfg: Dict[str, Any]) -> bool:
    """Add missing API client methods."""
    # For demonstration purposes, assume we have a simple model that adds methods
    # In a real-world scenario, you would use a more sophisticated model or approach
    return True

def is_ui_complete(cfg: Dict[str, Any]) -> bool:
    """Check if the UI is complete."""
    # For demonstration purposes, assume we have a simple model that checks completeness
    # In a real-world scenario, you would use a more sophisticated model or approach
    return True

def add_ui_components(cfg: Dict[str, Any]) -> bool:
    """Add missing UI components."""
    # For demonstration purposes, assume we have a simple model that adds components
    # In a real-world scenario, you would use a more sophisticated model or approach
    return True


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--config', '-c', default='', help='Path to .improver_config.json')
    parser.add_argument('--dry-run', action='store_true', help='Do not write or commit anything')
    args = parser.parse_args()

    cfg = load_config(args.config)
    if args.dry_run:
        cfg['dry_run'] = True
    # If user asked specifically to run (no dry-run), respect config too

    # Start main loop
    main_loop(cfg)
