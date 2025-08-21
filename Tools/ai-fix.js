#!/usr/bin/env node
// Tools/ai-fix.js (robust issue-memory edition)
// - store AI solutions per "issue" and re-use while issue persists
// - fuzzy-match issue signatures to avoid brittle deletions
// - debug logging at ~/.ai-fix-issues/log.txt
// - skip files marked with `// DO NOT MODIFY BY AI`
// - flags: --dry-run --commit --stubs-only --max-excerpt=N --mark-resolved=ID --debug

const { spawnSync, execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');
const crypto = require('crypto');

function usageAndExit() {
  console.log(`Usage: node ai-fix.js path/to/build.log [--dry-run] [--commit] [--stubs-only] [--max-excerpt=NUM] [--mark-resolved=ID] [--debug]
Flags:
  --dry-run        : Show proposed changes but do not overwrite files.
  --commit         : If fixes applied, run git add <files> && git commit -m "ai-fix: automated fixes".
  --stubs-only     : Only create missing-symbol stubs from the log, skip Copilot steps.
  --max-excerpt=N  : max characters of build log excerpt per file (default 8000).
  --mark-resolved  : Force-delete stored solution for given issue ID.
  --debug          : Write verbose debug trace to ~/.ai-fix-issues/log.txt
`);
  process.exit(0);
}

const argv = process.argv.slice(2);
if (argv.length === 0) usageAndExit();

const logPath = argv.find(a => !a.startsWith('--')) || argv[0];
if (!fs.existsSync(logPath)) {
  console.error("Log file not found:", logPath);
  process.exit(1);
}

const dryRun = argv.includes('--dry-run');
const doCommit = argv.includes('--commit');
const stubsOnly = argv.includes('--stubs-only');
const debug = argv.includes('--debug');
const markResolvedFlag = argv.find(a => a.startsWith('--mark-resolved='));
const MARK_RESOLVED_ID = markResolvedFlag ? markResolvedFlag.split('=')[1] : null;
const maxExcerptFlag = argv.find(a => a.startsWith('--max-excerpt='));
const MAX_EXCERPT = maxExcerptFlag ? parseInt(maxExcerptFlag.split('=')[1], 10) || 8000 : 8000;

const rawLog = fs.readFileSync(logPath, 'utf8');

function logDebug(...args) {
  if (!debug) return;
  try {
    const LDIR = path.join(os.homedir(), '.ai-fix-issues');
    fs.mkdirSync(LDIR, { recursive: true });
    const p = path.join(LDIR, 'log.txt');
    fs.appendFileSync(p, new Date().toISOString() + ' - ' + args.map(a => (typeof a === 'string' ? a : JSON.stringify(a))).join(' ') + '\n');
  } catch (e) {}
}

function sha256(s) { return crypto.createHash('sha256').update(s || '', 'utf8').digest('hex'); }

logDebug('Starting run with', { logPath, dryRun, doCommit, stubsOnly, MAX_EXCERPT });

const ISSUES_DIR = path.join(os.homedir(), '.ai-fix-issues');
const ISSUES_DB = path.join(ISSUES_DIR, 'issues.json');
const CACHE_PATH = path.join(os.homedir(), '.ai-fix-cache.json');
try { fs.mkdirSync(ISSUES_DIR, { recursive: true }); } catch (e) {}

let issuesDb = {};
try { issuesDb = JSON.parse(fs.readFileSync(ISSUES_DB, 'utf8')); } catch (e) { issuesDb = {}; }
let cache = {};
try { cache = JSON.parse(fs.readFileSync(CACHE_PATH, 'utf8')); } catch (e) { cache = {}; }

if (MARK_RESOLVED_ID) {
  if (issuesDb[MARK_RESOLVED_ID]) {
    delete issuesDb[MARK_RESOLVED_ID];
    fs.writeFileSync(ISSUES_DB, JSON.stringify(issuesDb, null, 2), 'utf8');
    console.log("Marked resolved and deleted stored solution for issue:", MARK_RESOLVED_ID);
  } else {
    console.log("No issue with id", MARK_RESOLVED_ID, "found.");
  }
  process.exit(0);
}

// --------- basic helpers ---------
function runCmd(cmd) {
  return execSync(cmd, { encoding: 'utf8' });
}
function safeExec(cmd) {
  try { return execSync(cmd, { encoding: 'utf8', stdio: ['pipe','pipe','pipe'] }); } catch (e) { return null; }
}

// Token overlap fuzzy compare: returns 0..1
function tokenOverlap(a, b) {
  if (!a || !b) return 0;
  const ta = Array.from(new Set(a.toLowerCase().split(/\W+/).filter(Boolean)));
  const tb = Array.from(new Set(b.toLowerCase().split(/\W+/).filter(Boolean)));
  if (ta.length === 0 || tb.length === 0) return 0;
  const common = ta.filter(x => tb.includes(x)).length;
  return common / Math.min(ta.length, tb.length);
}

// decide if two signatures represent the same issue
function sameIssueSig(sigA, sigB) {
  if (!sigA || !sigB) return false;
  if (sigA.includes(sigB) || sigB.includes(sigA)) return true;
  const overlap = tokenOverlap(sigA, sigB);
  return overlap >= 0.5; // threshold: 50% token overlap
}

function detectIssuesFromLog(logContents) {
  logDebug('Detecting issues from log length', logContents.length);
  const issues = [];
  // 1) explicit swift error lines
  const fileErrRegex = /([\/\w\-\._]+\.swift:\d+:(?:.*?)\b(?:error|fatal error|note|warning)\b.*)/g;
  let m;
  const seenSig = new Set();
  while ((m = fileErrRegex.exec(logContents)) !== null) {
    const line = m[1].trim();
    const short = line.replace(/\s+/g, ' ').slice(0, 400);
    // compute a canonical signature (short)
    if (seenSig.has(short)) continue;
    seenSig.add(short);
    const id = sha256(short);
    issues.push({ id, signature: short, sample: line });
  }
  // 2) missing symbol messages
  const missingSymRegex = /cannot find '([^']+)' in scope/g;
  while ((m = missingSymRegex.exec(logContents)) !== null) {
    const sym = m[1];
    const sig = `cannot find ${sym} in scope`;
    if (seenSig.has(sig)) continue;
    seenSig.add(sig);
    const id = sha256(sig);
    issues.push({ id, signature: sig, sample: sig });
  }
  // 3) another common pattern: use of unresolved identifier
  const unresolvedRegex = /use of unresolved identifier '([^']+)'/g;
  while ((m = unresolvedRegex.exec(logContents)) !== null) {
    const sym = m[1];
    const sig = `use of unresolved identifier ${sym}`;
    if (seenSig.has(sig)) continue;
    seenSig.add(sig);
    const id = sha256(sig);
    issues.push({ id, signature: sig, sample: sig });
  }
  logDebug('Detected issue signatures', issues.map(i => i.signature));
  return issues;
}

const currentIssues = detectIssuesFromLog(rawLog);

// Determine matching between stored issues and current ones using fuzzy matching
const currentMatches = {}; // storedId -> matched current issue object
for (const storedId of Object.keys(issuesDb)) {
  const stored = issuesDb[storedId];
  let matched = null;
  for (const cur of currentIssues) {
    if (sameIssueSig(stored.signature || '', cur.signature)) {
      matched = cur;
      break;
    }
  }
  if (matched) currentMatches[storedId] = matched;
}

// Auto-forget: remove stored issues that do NOT match any current signature
for (const storedId of Object.keys(issuesDb)) {
  if (!currentMatches[storedId]) {
    // double-check: maybe a current issue matches by file-level heuristics (we'll also check below)
    logDebug('Auto-forgetting stored issue', storedId, issuesDb[storedId].signature);
    delete issuesDb[storedId];
  }
}

// Recompute dynamic map: which current issues have stored solutions?
const storedForCurrent = {}; // currentIssue.id -> storedIssueId
for (const cur of currentIssues) {
  for (const storedId of Object.keys(issuesDb)) {
    const stored = issuesDb[storedId];
    if (sameIssueSig(stored.signature || '', cur.signature)) {
      storedForCurrent[cur.id] = storedId;
    }
  }
}

logDebug('Stored-for-current mapping', storedForCurrent);

// ----------- find failing swift files and lines -------------
const fileLineRegex = /([\/\w\-\._]+\.swift):(\d+):/g;
let mm;
const fileLinesMap = new Map();
while ((mm = fileLineRegex.exec(rawLog)) !== null) {
  const f = mm[1], ln = parseInt(mm[2], 10);
  if (!fileLinesMap.has(f)) fileLinesMap.set(f, new Set());
  fileLinesMap.get(f).add(ln);
}
const uniqueFiles = Array.from(fileLinesMap.keys());
if (uniqueFiles.length === 0) {
  console.log("No failing .swift files detected in build log.");
}

// --------- create stubs for missing symbols ----------
function ensureStubs(logContents) {
  const missingRegex = /cannot find '([^']+)' in scope/g;
  const missing = new Set();
  let mm2;
  while ((mm2 = missingRegex.exec(logContents)) !== null) missing.add(mm2[1]);
  if (missing.size === 0) return [];
  const created = [];
  for (const sym of missing) {
    const safeName = sym.replace(/[^A-Za-z0-9_]/g, '');
    try {
      const grepCmd = `grep -R --line-number --exclude-dir=DerivedData --exclude-dir=node_modules -n "${safeName}" . || true`;
      const out = safeExec(grepCmd);
      if (out && String(out).trim().length > 0) continue;
    } catch (e) {}
    const targetDirCandidates = [path.join('ANCHOR','Views','Components'), 'Sources', '.'];
    let targetDir = targetDirCandidates.find(d => fs.existsSync(d)) || 'Sources';
    try { fs.mkdirSync(targetDir, { recursive: true }); } catch (e) {}
    const fname = path.join(targetDir, `${safeName}.swift`);
    if (fs.existsSync(fname)) continue;
    let code;
    if (safeName.endsWith('Style')) {
      code = `import SwiftUI\n\nstruct ${safeName}: ButtonStyle { func makeBody(configuration: Configuration) -> some View { configuration.label } }\n`;
    } else if (safeName.endsWith('Service') || safeName.endsWith('Manager')) {
      code = `import Foundation\n\nfinal class ${safeName} { static let shared = ${safeName}(); private init() {} }\n`;
    } else if (/View$/.test(safeName)) {
      code = `import SwiftUI\n\nstruct ${safeName}: View { var body: some View { Text("${safeName} stub") } }\n`;
    } else {
      code = `// Auto-generated minimal stub for ${safeName}\nimport Foundation\n\nstruct ${safeName} {}\n`;
    }
    try { fs.writeFileSync(fname, code, 'utf8'); created.push(fname); logDebug('Created stub', fname); } catch(e) { console.error('Failed stub write', e.message); }
  }
  return created;
}

const createdStubs = ensureStubs(rawLog);
let changedFiles = [];
if (createdStubs.length > 0) createdStubs.forEach(f => changedFiles.push(f));
if (stubsOnly) {
  console.log("Stubs created:", createdStubs);
  fs.writeFileSync(ISSUES_DB, JSON.stringify(issuesDb, null, 2), 'utf8');
  process.exit(0);
}

// -------- Copilot wrapper ----------
function runCopilot(prompt) {
  try {
    const proc = spawnSync('gh', ['copilot', 'suggest'], {
      input: prompt,
      encoding: 'utf8',
      maxBuffer: 1024 * 1024 * 30
    });
    if (proc.error) throw proc.error;
    return { ok: proc.status === 0 || (proc.stdout && proc.stdout.length > 0), out: proc.stdout || proc.stderr || '' };
  } catch (e) {
    return { ok: false, err: e };
  }
}

// helper to extract context snippet for a file
function buildContextForFile(filePath) {
  const fileOrig = fs.existsSync(filePath) ? fs.readFileSync(filePath, 'utf8') : '';
  const linesSet = fileLinesMap.get(filePath) || new Set();
  if (linesSet.size === 0) return fileOrig.split(/\r?\n/).slice(0, 200).map((l,i)=>`${i+1}: ${l}`).join('\n');
  const lines = fileOrig.split(/\r?\n/);
  const want = new Set();
  for (const ln of linesSet) {
    for (let i = Math.max(0, ln - 1 - 8); i <= Math.min(lines.length -1, ln -1 + 8); i++) want.add(i);
  }
  return Array.from(want).sort((a,b)=>a-b).map(i=>`${i+1}: ${lines[i] || ''}`).join('\n');
}

// -------- main per-file flow ----------
for (const filePath of uniqueFiles) {
  if (!fs.existsSync(filePath)) { console.warn('File missing on disk, skipping', filePath); continue; }
  console.log('\n=== Processing', filePath);
  logDebug('Processing file', filePath);

  // skip marker check
  const content = fs.readFileSync(filePath, 'utf8');
  if (content.includes('// DO NOT MODIFY BY AI')) {
    console.log('Skipping file due to DO NOT MODIFY BY AI marker:', filePath);
    logDebug('Skip marker found for', filePath);
    continue;
  }

  // find any current issue signatures that reference this file (by inspecting nearby log lines)
  const excerptPattern = new RegExp(`(?:^|\\n)([^\\n]*${filePath.replace(/[.*+?^${}()|[\]\\]/g,'\\$&')}[^\\n]*)(?:\\n|$)`, 'g');
  let foundLines = [];
  let mm2;
  while ((mm2 = excerptPattern.exec(rawLog)) !== null) foundLines.push(mm2[1]);
  const excerpt = (foundLines.length ? foundLines.join('\n') : rawLog.slice(0, MAX_EXCERPT)).slice(0, MAX_EXCERPT);

  // check if any current issue has a stored solution; if yes, re-apply it
  let appliedStored = false;
  for (const cur of currentIssues) {
    // fuzzy match cur.signature -> find stored ID that matches
    let storedId = null;
    for (const sid of Object.keys(issuesDb)) {
      if (sameIssueSig(issuesDb[sid].signature, cur.signature)) {
        storedId = sid; break;
      }
    }
    if (!storedId) continue;
    const stored = issuesDb[storedId];
    if (!stored || !stored.files || !stored.files[filePath]) continue;
    const storedContent = stored.files[filePath];
    if (!storedContent) continue;

    // if same content already, skip
    if (storedContent === content) {
      console.log(`Stored solution for issue ${storedId} already present in ${filePath} (no-op).`);
      appliedStored = true;
      break;
    }
    // apply stored solution (or show in dry-run)
    if (dryRun) {
      console.log(`[dry-run] Would re-apply stored solution for issue ${storedId} to ${filePath}`);
    } else {
      const backup = `${filePath}.bak.${Date.now()}`;
      try { fs.copyFileSync(filePath, backup); } catch (e) {}
      try {
        fs.writeFileSync(filePath, storedContent, 'utf8');
        console.log(`Re-applied stored solution for issue ${storedId} to ${filePath}`);
        stored.reuseCount = (stored.reuseCount || 0) + 1;
        stored.lastAppliedAt = new Date().toISOString();
        changedFiles.push(filePath);
        logDebug('Applied stored solution', { storedId, filePath });
      } catch (e) {
        console.error('Failed to write stored solution', e.message);
      }
    }
    appliedStored = true;
    break; // re-applied for this file; skip Copilot
  }
  if (appliedStored) continue;

  // No stored solution applied -> call Copilot
  const contextSnippet = buildContextForFile(filePath);
  const prompt = [
    `You are an assistant that rewrites a single Swift source file to fix the reported compile errors.`,
    `Only output the full corrected Swift file contents — nothing else.`,
    `Build excerpt (relevant lines):`, '---', excerpt, '---',
    `File context (near failing lines):`, '---', contextSnippet, '---',
    `Original file contents:`, '---', content, '---',
    `Only output the fixed file contents.`
  ].join('\n\n');

  logDebug('Calling Copilot for', filePath, 'promptLength', prompt.length);

  const resp = runCopilot(prompt);
  if (!resp.ok) {
    console.warn('Copilot call failed or returned empty for', filePath, resp.err || resp.out);
    continue;
  }
  const fixed = String(resp.out || '').trim();
  if (!fixed) { console.log('Copilot produced empty output'); continue; }

  const fixedHash = sha256(fixed);
  const cacheKey = path.resolve(filePath);
  if (cache[cacheKey] && cache[cacheKey].lastHash === fixedHash) {
    console.log('Copilot returned identical content as last time for', filePath, '- skipping apply to avoid loop.');
    logDebug('Copilot duplicate detected', filePath);
    continue;
  }

  // If copilot output is same as file, skip and update cache
  if (fixed === content) {
    console.log('Copilot output matches original file (no-op).');
    cache[cacheKey] = { lastHash: fixedHash, triedAt: new Date().toISOString() };
    continue;
  }

  // Apply (or dry-run)
  if (dryRun) {
    console.log('[dry-run] Would overwrite:', filePath);
    cache[cacheKey] = { lastHash: fixedHash, triedAt: new Date().toISOString() };
    // save proposed solution into in-memory issuesDb for any current issue that seems to apply to this file
    for (const cur of currentIssues) {
      const id = cur.id;
      // if current issue signature references this file (fuzzy) then prepare to save
      if (!sameIssueSig(cur.signature, fixed) && !sameIssueSig(cur.signature, content)) {
        // still save if excerpt contained the filePath (heuristic)
        if (!String(excerpt).includes(filePath)) continue;
      }
      if (!issuesDb[id]) issuesDb[id] = { id, signature: cur.signature, files: {} , createdAt: new Date().toISOString()};
      issuesDb[id].files = issuesDb[id].files || {};
      issuesDb[id].files[filePath] = fixed;
      logDebug('Dry-run: staged stored solution for', id, filePath);
    }
    continue;
  }

  // write backup and file
  const backup = `${filePath}.bak.${Date.now()}`;
  try { fs.copyFileSync(filePath, backup); } catch(e) {}
  try {
    fs.writeFileSync(filePath, fixed, 'utf8');
    console.log('Applied Copilot fix to', filePath);
    changedFiles.push(filePath);
    cache[cacheKey] = { lastHash: fixedHash, triedAt: new Date().toISOString(), backup };
    // save into issuesDb for any current issue whose signature matches excerpt or file context
    for (const cur of currentIssues) {
      // heuristics: match by fuzzy signature OR the build excerpt contains filePath and the cur.signature tokens overlap with excerpt
      if (sameIssueSig(cur.signature, fixed) || sameIssueSig(cur.signature, content) || String(excerpt).includes(filePath)) {
        if (!issuesDb[cur.id]) issuesDb[cur.id] = { id: cur.id, signature: cur.signature, files: {}, createdAt: new Date().toISOString() };
        issuesDb[cur.id].files = issuesDb[cur.id].files || {};
        issuesDb[cur.id].files[filePath] = fixed;
        issuesDb[cur.id].savedAt = new Date().toISOString();
        logDebug('Saved solution for issue', cur.id, 'file', filePath);
      }
    }
  } catch (e) {
    console.error('Failed to write fixed file', e.message);
    try { fs.copyFileSync(backup, filePath); } catch(_) {}
  }
}

// persist DB & cache
try { fs.writeFileSync(ISSUES_DB, JSON.stringify(issuesDb, null, 2), 'utf8'); } catch (e) { console.warn('Failed to write issues db', e.message); }
try { fs.writeFileSync(CACHE_PATH, JSON.stringify(cache, null, 2), 'utf8'); } catch (e) { console.warn('Failed to write cache', e.message); }

// optional commit
if (!dryRun && doCommit && changedFiles.length > 0) {
  try {
    execSync(`git add ${changedFiles.map(f=>`"${f}"`).join(' ')}`);
    execSync(`git commit -m "ai-fix: automated fixes for ${path.basename(logPath)}" || true`);
    console.log('Committed fixes (if any).');
  } catch (e) { console.warn('Git commit failed', e.message); }
}

// summary
console.log('');
if (changedFiles.length) {
  console.log('AI made changes to files:'); changedFiles.forEach(f=>console.log(' -', f));
} else {
  console.log('AI did not modify any files on this pass.');
}
console.log('Stored issue IDs:', Object.keys(issuesDb));
logDebug('Run complete. changedFiles:', changedFiles, 'storedIssues', Object.keys(issuesDb));
process.exit(0);
