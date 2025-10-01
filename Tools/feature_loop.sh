#!/usr/bin/env bash
# Tools/feature_loop.sh
# Robust feature loop: run ai_features, iteratively improve, commit, fallback to placeholder

set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS="$ROOT/Tools"

PYTHON="${PYTHON:-python3}"
AI_FEATURES="$TOOLS/ai_features.py"
IMPROVER="$TOOLS/improve_features.py"
IMPROVER_ARGS="${IMPROVER_ARGS:-"--debug --batch 10 --force"}"
BATCH="${BATCH:-8}"
SLEEP="${SLEEP:-1}"
DRY_RUN="${DRY_RUN:-0}"
MAX_IMPROVE_PASSES="${MAX_IMPROVE_PASSES:-6}"
EXIT_ON_COMMIT_FAIL="${EXIT_ON_COMMIT_FAIL:-0}"
LOGFILE="$TOOLS/feature_loop.log"

cd "$ROOT" || exit 1

echo "Starting feature loop in $ROOT"
echo "DRY_RUN=$DRY_RUN, SLEEP=$SLEEP, MAX_IMPROVE_PASSES=$MAX_IMPROVE_PASSES, LOG=$LOGFILE"

# cleanup helper for temp files
_cleanup_tmp() {
    [ -n "${TMP_OUT:-}" ] && [ -f "$TMP_OUT" ] && rm -f "$TMP_OUT"
}
trap _cleanup_tmp EXIT

# ------------------------------
# Run ai_features
# ------------------------------
run_ai_features() {
    if [ "$DRY_RUN" = "1" ]; then
        echo "[dry-run] Would run ai_features"
        return 0
    fi
    if [ ! -f "$AI_FEATURES" ]; then
        echo "ai_features not found at $AI_FEATURES, skipping." | tee -a "$LOGFILE"
        return 1
    fi
    echo "Running ai_features..." | tee -a "$LOGFILE"
    $PYTHON "$AI_FEATURES" --commit --debug --batch "$BATCH" --force 2>&1 | tee -a "$LOGFILE"
    return ${PIPESTATUS[0]:-0}
}

# ------------------------------
# Run improver and capture changed files
# ------------------------------
IMPROVER_CHANGED_FILES=""
run_improver() {
    IMPROVER_CHANGED_FILES=""
    if [ "$DRY_RUN" = "1" ]; then
        echo "[dry-run] Would run improver" | tee -a "$LOGFILE"
        return 0
    fi
    if [ ! -f "$IMPROVER" ]; then
        echo "Improver not found at $IMPROVER, skipping." | tee -a "$LOGFILE"
        return 1
    fi

    TMP_OUT="$(mktemp)"
    echo "Running improver..." | tee -a "$LOGFILE"
    # Use eval to support IMPROVER_ARGS containing spaces/quotes
    eval "$PYTHON \"$IMPROVER\" $IMPROVER_ARGS" 2>&1 | tee "$TMP_OUT" | tee -a "$LOGFILE"
    RC=${PIPESTATUS[0]:-0}

    IMPROVER_CHANGED_FILES=$(grep -Eo '([A-Za-z0-9_./-]+\.swift|\.py|\.md|\.json)' "$TMP_OUT" | sed 's|^[./]||' | sort -u || true)
    _cleanup_tmp

    if [ -n "$IMPROVER_CHANGED_FILES" ]; then
        echo "Improver changed files:" | tee -a "$LOGFILE"
        echo "$IMPROVER_CHANGED_FILES" | tee -a "$LOGFILE"
    else
        echo "No files reported by improver." | tee -a "$LOGFILE"
    fi

    return $RC
}

# ------------------------------
# Commit user-facing files
# ------------------------------
commit_files() {
    local files="$1"
    local message="$2"

    if [ -z "$files" ]; then
        echo "No files to commit." | tee -a "$LOGFILE"
        return 1
    fi

    # Filter out Tools/
    USER_FILES=$(echo "$files" | grep -Ev '^Tools/' || true)
    if [ -z "$USER_FILES" ]; then
        echo "No user-facing files to commit." | tee -a "$LOGFILE"
        return 1
    fi

    echo "$USER_FILES" | while IFS= read -r f; do
        [ -z "$f" ] && continue
        # If file exists, add it. If it doesn't exist but is new, allow git add to try (will no-op).
        if [ -e "$f" ]; then
            git add -- "$f" 2>/dev/null || git add -A -- "$f" 2>/dev/null || true
            echo "Staged: $f" | tee -a "$LOGFILE"
        else
            # attempt to add path regardless (handles newly-created files that may be printed differently)
            git add -- "$f" 2>/dev/null || true
            echo "Attempted to stage (may be new): $f" | tee -a "$LOGFILE"
        fi
    done

    # nothing staged? skip commit
    if git diff --cached --quiet; then
        echo "Nothing staged to commit." | tee -a "$LOGFILE"
        return 1
    fi

    if git commit -m "$message" >/dev/null 2>&1; then
        echo "Committed: $message" | tee -a "$LOGFILE"
        return 0
    else
        echo "Commit failed: $message" | tee -a "$LOGFILE"
        # respect EXIT_ON_COMMIT_FAIL
        if [ "${EXIT_ON_COMMIT_FAIL:-0}" = "1" ]; then
            echo "EXIT_ON_COMMIT_FAIL=1; exiting." | tee -a "$LOGFILE"
            exit 2
        fi
        return 2
    fi
}

# ------------------------------
# Create placeholder if nothing changed
# ------------------------------
create_placeholder() {
    TS=$(date +%s)
    POOL=("DailyJournal" "DailyCheckin" "CloudSyncSettings" "ExportCSV" "UserAnalytics" "SecureNotes" "BackupRestore")
    idx=$((TS % ${#POOL[@]}))
    NAME="${POOL[$idx]}${TS}"
    DIR="App/Features"
    mkdir -p "$DIR"
    mkdir -p Tests/Features

    VM_PATH="$DIR/${NAME}ViewModel.swift"
    VIEW_PATH="$DIR/${NAME}View.swift"
    TEST_PATH="Tests/Features/${NAME}Tests.swift"

    cat > "$VM_PATH" <<EOF
import Foundation
import Combine

final class ${NAME}ViewModel: ObservableObject {
    @Published var title: String = "${POOL[$idx]}"
    @Published var items: [String] = []

    func saveEntry(_ s: String) {
        guard !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        items.append(s)
    }

    func load() async {
        try? await Task.sleep(nanoseconds: 200_000_000)
        DispatchQueue.main.async {
            if self.items.isEmpty { self.items = ["Sample entry"] }
        }
    }
}
EOF

    cat > "$VIEW_PATH" <<EOF
import SwiftUI

struct ${NAME}View: View {
    @StateObject private var vm = ${NAME}ViewModel()
    @State private var draft: String = ""

    var body: some View {
        NavigationView {
            VStack {
                Text(vm.title).font(.largeTitle).padding(.bottom)
                TextEditor(text: $draft).frame(minHeight:140).padding()
                HStack {
                    Button("Save") {
                        vm.saveEntry(draft)
                        draft = ""
                    }
                    .buttonStyle(.borderedProminent)
                    Button("Reload") {
                        Task { await vm.load() }
                    }
                }
                List(vm.items, id: \\.self) { Text($0) }
                Spacer()
            }.padding()
        }
    }
}

#if DEBUG
struct ${NAME}View_Previews: PreviewProvider {
    static var previews: some View { ${NAME}View() }
}
#endif
EOF

    cat > "$TEST_PATH" <<EOF
import XCTest
@testable import Anchor

final class ${NAME}Tests: XCTestCase {
    func testScaffold() {
        let vm = ${NAME}ViewModel()
        XCTAssertNotNil(vm)
    }
}
EOF

    git add "$VM_PATH" "$VIEW_PATH" "$TEST_PATH" >/dev/null 2>&1 || true
    if git commit -m "Auto: placeholder feature ${NAME}" >/dev/null 2>&1; then
        echo "Committed placeholder ${NAME}" | tee -a "$LOGFILE"
        return 0
    else
        echo "Placeholder commit failed" | tee -a "$LOGFILE"
        return 1
    fi
}

# ------------------------------
# Main loop
# ------------------------------
ITER=1
while :; do
    [ -f "$TOOLS/STOP" ] && echo "STOP detected, exiting." && exit 0

    echo "=== ITERATION $ITER ($(date)) ===" | tee -a "$LOGFILE"

    run_ai_features || true
    sleep 0.2

    run_improver || true
    if [ -n "$IMPROVER_CHANGED_FILES" ]; then
        commit_files "$IMPROVER_CHANGED_FILES" "Auto-improver iteration $ITER" || true
    fi

    # commit any other user code changes
    CHANGED_USER=$(git --no-pager diff --name-only | grep -Ev '^Tools/' || true)
    if [ -n "$CHANGED_USER" ]; then
        commit_files "$CHANGED_USER" "Auto: user changes iteration $ITER" || true
    fi

    # fallback to placeholder if nothing committed and nothing reported by improver
    CHANGED_USER_POST=$(git --no-pager diff --name-only | grep -Ev '^Tools/' || true)
    if [ -z "$IMPROVER_CHANGED_FILES" ] && [ -z "$CHANGED_USER_POST" ]; then
        echo "No changes detected; creating placeholder..." | tee -a "$LOGFILE"
        create_placeholder || echo "Placeholder creation failed" | tee -a "$LOGFILE"
    fi

    ITER=$((ITER+1))
    echo "Sleeping $SLEEP seconds..." | tee -a "$LOGFILE"
    sleep "$SLEEP"
done
