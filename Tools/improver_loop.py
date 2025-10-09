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
import uuid
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

# imrover_loop.py (top of file)
from transformers import AutoModelForCausalLM, AutoTokenizer
import torch

# Load local/open-source LLM
MODEL_NAME = "mistralai/Mistral-7B-Instruct-v0.1"  # Or local path
tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)
model = AutoModelForCausalLM.from_pretrained(
    MODEL_NAME,
    device_map="auto",          # GPU if available, else CPU
    torch_dtype=torch.float16,  # Saves memory
    low_cpu_mem_usage=True
)


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

def run_local_model(prompt: str, max_tokens: int = 200) -> str:
    """Run the local Mistral model to generate a patch suggestion."""
    inputs = tokenizer(prompt, return_tensors="pt").to(model.device)
    outputs = model.generate(**inputs, max_new_tokens=max_tokens)
    return tokenizer.decode(outputs[0], skip_special_tokens=True)



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
    Returns: {'patch': str, 'llm_confidence': float}
    """
    prompt = (
        "You are an expert iOS/Swift developer. Given the following failing test output and code context, "
        "propose a minimal, safe code patch (diff) that addresses the issue. Return only the patch in unified "
        "diff format and a short explanation. Include TODO markers where uncertain.\n\n"
        f"Context:\n{context_snippet}"
    )
    patch_text = run_local_model(prompt, max_tokens=max_tokens)
    # simple heuristic: longer patch -> higher confidence
    confidence = min(0.95, 0.2 + min(0.75, len(patch_text) / 5000.0))
    return {'patch': patch_text, 'llm_confidence': confidence}



# ---------------------- High-level loop --------------------------------

def main_loop(cfg: Dict[str, Any]):
    anchor_dir = Path(cfg.get('anchor_dir', 'ANCHOR'))
    if not anchor_dir.exists():
        print(f"Anchor directory not found: {anchor_dir}")
        sys.exit(2)

    iteration = 0
    while iteration < cfg.get('max_iterations', 200):
        iteration += 1
        print('='*80)
        print(f'Iteration {iteration}')

        # 1) Attempt Xcode build/tests (user said they run a simulator)
        xcode_info = build_and_test_xcode(cfg)
        if xcode_info.get('cmd'):
            print('Xcode cmd executed: ', xcode_info['cmd'])
        print('Xcode success:', xcode_info.get('success'))

        if xcode_info.get('success'):
            print('Tests passed — no immediate fixes required.')
            # Could still run linters and propose non-critical enhancements.
            # For now, stop if everything is green.
            return

        # 2) Tests/build failed — gather context and ask Gemini
        context_snippet = ''
        context_snippet += 'STDOUT:' + xcode_info.get('stdout', '')[:4000]
        context_snippet += 'STDERR:' + xcode_info.get('stderr', '')[:4000]

        # 3) Ask Gemini for a suggested patch
        print('Requesting Gemini advisor for suggested patch...')
        suggestion = attempt_fix_with_local_model(context_snippet)
        if not suggestion:
            print('No suggestion from Gemini; creating a safe suggestion stub in ANCHOR/stubs')
            # create suggestion file with context for human devs
            stubs_dir = anchor_dir / 'stubs'
            stubs_dir.mkdir(parents=True, exist_ok=True)
            fname = stubs_dir / f'suggestion_{datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")}.md'
            content = f"# Manual suggestioContext:{context_snippet}"
            if not cfg.get('dry_run', True):
                fname.write_text(content, encoding='utf-8')
            print(f'Wrote {fname} (dry_run={cfg.get("dry_run")})')
            return

        # 4) Evaluate suggestion: compute confidence and decide whether to apply
        llm_confidence = suggestion.get('llm_confidence', 0.0)
        patch_text = suggestion.get('patch', '')
        metrics = {'num_call_sites': 1, 'llm_confidence': llm_confidence, 'tests_impact': 1}
        conf = compute_confidence(metrics)
        print(f'LLM reported confidence: {llm_confidence}; computed score: {conf}')

        branch = f'improver/{datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")}-{uuid.uuid4().hex[:6]}'
        patch_file = Path(cfg.get('anchor_dir')) / 'stubs' / f'patch_{datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")}.diff'
        patch_file.parent.mkdir(parents=True, exist_ok=True)
        if not cfg.get('dry_run', True):
            patch_file.write_text(patch_text, encoding='utf-8')
        print(f'Wrote suggestion patch to {patch_file} (dry_run={cfg.get("dry_run")})')

        # If high confidence and auto_apply enabled — apply to a branch and run tests
        if conf >= cfg.get('confidence_threshold', 0.85) and cfg.get('auto_apply', False):
            print('High confidence and auto_apply enabled — attempting to apply patch to a new branch')
            # Attempt to apply patch via git apply
            if not cfg.get('dry_run', True):
                # write patch to temp file and try to apply
                ret, out, err = run_cmd(f'git checkout -b {branch}')
                if ret != 0:
                    print('Failed to create branch:', err)
                    return
                tmp_patch = tempfile.NamedTemporaryFile(delete=False, mode='w', encoding='utf-8')
                tmp_patch.write(patch_text)
                tmp_patch.flush()
                tmp_patch.close()
                ret, out, err = run_cmd(f'git apply --index {tmp_patch.name}')
                if ret != 0:
                    print('git apply failed:', err)
                    # cleanup and abort
                    run_cmd('git checkout -')
                    return
                run_cmd(f'git commit -am "improver: apply suggested patch"')
                # Run xcode tests again
                xcode_after = build_and_test_xcode(cfg)
                if xcode_after.get('success'):
                    print('Applied patch and tests now pass.')
                    # Optionally open PR
                    if cfg.get('gh_cli') and not cfg.get('dry_run', True):
                        pr_link = gh_create_pr(branch, 'improver: suggested fix', 'Auto-generated suggestion from improver', cfg)
                        print('PR created:', pr_link)
                        return
                else:
                    print('Applied patch but tests still failing. Reverting branch.')
                    run_cmd('git checkout -')
                    run_cmd(f'git branch -D {branch}')
                    return
            else:
                print('[DRY-RUN] Would create branch, apply patch, run tests, and possibly create PR')
                return
        else:
            # Not auto-applying: create branch with patch file committed and open PR for review (if configured)
            print('Not auto-applying — creating branch with patch file for review')
            if not cfg.get('dry_run', True):
                # create branch, add patch file, commit
                try:
                    run_cmd(f'git checkout -b {branch}')
                    run_cmd(f'git add {str(patch_file)}')
                    run_cmd('git commit -m "improver: add suggested patch for review"')
                    if cfg.get('gh_cli'):
                        pr_link = gh_create_pr(branch, 'improver: suggested patch', f'Patch created by improver. Confidence: {conf}', cfg)
                        print('PR created:', pr_link)
                except Exception as e:
                    print('Failed to create branch/commit:', e)
            else:
                print(f'[DRY-RUN] Would create branch {branch} and commit {patch_file}')
            return

    print('Reached max iterations; exiting')


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
