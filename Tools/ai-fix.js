#!/usr/bin/env node
// Tools/ai-fix.js
// Node helper: given a build log path, find failing .swift files, call gh copilot suggest
// to rewrite each failing file, and optionally create simple stubs for missing types
// Outputs informational messages and exits 0 even if it couldn't fix everything.

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

function safeExec(cmd, opts = {}) {
  try {
    return execSync(cmd, { stdio: 'inherit', shell: true, ...opts });
  } catch (err) {
    // return null but don't crash — caller decides
    return null;
  }
}

if (process.argv.length < 3) {
  console.error("Usage: node ai-fix.js path/to/build.log");
  process.exit(0);
}

const logPath = process.argv[2];
if (!fs.existsSync(logPath)) {
  console.error("Log file not found:", logPath);
  process.exit(0);
}

const log = fs.readFileSync(logPath, 'utf8');

// 1) find failing swift files in the log
const fileRegex = /([\/\w\-\._]+\.swift):\d+:/g;
const matches = [...log.matchAll(fileRegex)];
const uniqueFiles = [...new Set(matches.map(m => m[1]))];

if (uniqueFiles.length === 0) {
  console.log("No failing .swift files detected in build log.");
} else {
  console.log("Failing Swift files detected:", uniqueFiles);
}

const changedFiles = [];

function ensureStubForMissingSymbols(logContents) {
  // find "cannot find 'X' in scope" patterns
  const missingRegex = /cannot find '([^']+)' in scope/g;
  const missing = new Set();
  let m;
  while ((m = missingRegex.exec(logContents)) !== null) {
    missing.add(m[1]);
  }
  if (missing.size === 0) return [];

  const created = [];
  for (const sym of missing) {
    // skip if symbol already exists in project
    const grepCmd = `grep -R --line-number --exclude-dir=DerivedData --exclude-dir=node_modules "${sym}" . || true`;
    const out = execSync(grepCmd, { encoding: 'utf8', stdio: ['pipe', 'pipe', 'ignore'] }).toString().trim();
    if (out) {
      // symbol found somewhere — skip
      continue;
    }

    // Create a minimal stub depending on name heuristic
    let code = null;
    const safeName = sym.replace(/[^A-Za-z0-9_]/g, '');
    const targetDir = path.join('ANCHOR', 'Views', 'Components');
    if (!fs.existsSync(targetDir)) {
      // fallback to project root if not found
      try { fs.mkdirSync(targetDir, { recursive: true }); } catch (e) {}
    }

    const fname = path.join(targetDir, `${safeName}.swift`);
    if (fs.existsSync(fname)) continue;

    if (safeName.endsWith("Style")) {
      // create a ButtonStyle stub
      code = `import SwiftUI

struct ${safeName}: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
`;
    } else if (safeName.endsWith("Service") || safeName.endsWith("Manager")) {
      code = `import Foundation

final class ${safeName} {
    static let shared = ${safeName}()
    private init() {}
}
`;
    } else {
      code = `// Auto-generated minimal stub for ${safeName}
import Foundation

struct ${safeName} {}
`;
    }

    try {
      fs.writeFileSync(fname, code, 'utf8');
      created.push(fname);
      console.log("Created stub for missing symbol:", sym, "->", fname);
    } catch (e) {
      console.error("Failed to write stub for", sym, e.message);
    }
  }
  return created;
}

// create stubs before calling copilot — this resolves simple "cannot find" errors quickly
const createdStubs = ensureStubForMissingSymbols(log);
if (createdStubs.length > 0) {
  createdStubs.forEach(f => changedFiles.push(f));
}

// 2) For each failing file, ask Copilot to rewrite the file to fix compile errors.
// Prompt will include a reasonably sized excerpt of the build log to guide the fix.
for (const filePath of uniqueFiles) {
  if (!fs.existsSync(filePath)) {
    console.warn("Failing file not found on disk (skipping):", filePath);
    continue;
  }

  console.log("=== Fixing:", filePath);
  const backup = `${filePath}.bak.${Date.now()}`;
  try {
    fs.copyFileSync(filePath, backup);
  } catch (e) {
    console.error("Backup failed for", filePath, e.message);
  }

  // build log excerpt limited to avoid extremely large prompts
  const logExcerpt = log.slice(0, 8000);

  // Prompt: be specific and ask for only corrected file contents, no commentary
  const prompt = `The Swift file below failed to compile. Use the following build log excerpt to fix compile/runtime errors. 
Only output the full corrected Swift file contents and nothing else. Do not add commentary or file delimiters.

Build log excerpt:
${logExcerpt}

File path: ${filePath}

Original file contents:
${fs.readFileSync(filePath, 'utf8')}
`;

  // write prompt to temp file to avoid shell quoting issues
  const tmpPrompt = path.join(os.tmpdir(), `copilot_prompt_${Date.now()}.txt`);
  fs.writeFileSync(tmpPrompt, prompt, 'utf8');

  // run gh copilot suggest: read original file via stdin, pass prompt as argument, output to .fixed
  const fixedPath = `${filePath}.fixed`;
  // note: copilot CLI usage may differ between versions; this inline approach works on many setups
  const cmd = `gh copilot suggest "${prompt.replace(/"/g, '\\"')}" < "${filePath}" > "${fixedPath}"`;
  console.log("Running Copilot to generate fixed file...");
  try {
    execSync(cmd, { stdio: 'inherit', shell: true, maxBuffer: 1024 * 1024 * 20 });
  } catch (e) {
    console.warn("Copilot command failed (non-fatal). Error:", e.message);
  }

  // validate fixed file
  let usedFixed = false;
  try {
    if (fs.existsSync(fixedPath) && fs.statSync(fixedPath).size > 0) {
      const fixedContent = fs.readFileSync(fixedPath, 'utf8');
      const origContent = fs.readFileSync(filePath, 'utf8');
      if (fixedContent.trim() && fixedContent !== origContent) {
        fs.writeFileSync(filePath, fixedContent, 'utf8');
        usedFixed = true;
        changedFiles.push(filePath);
        console.log("Applied Copilot fix to:", filePath);
      } else {
        console.log("Copilot produced no change or identical content for", filePath);
      }
      // cleanup fixedPath
      try { fs.unlinkSync(fixedPath); } catch (e) {}
    } else {
      console.log("No .fixed file produced for", filePath);
    }
  } catch (e) {
    console.error("Error validating/applying fixed file for", filePath, e.message);
    // restore backup
    try { fs.copyFileSync(backup, filePath); } catch (ee) {}
  }
}

// 3) Print summary and exit
if (changedFiles.length > 0) {
  console.log("AI made changes to files:");
  changedFiles.forEach(f => console.log(" -", f));
} else {
  console.log("AI did not modify any files on this pass.");
}

console.log("ai-fix.js finished.");
// exit 0 so the loop continues even if some fixes failed
process.exit(0);
