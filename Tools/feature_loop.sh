#!/usr/bin/env bash
# Tools/feature_loop.sh
# Feature loop: run ai_features, iteratively improve, commit edits only (no new placeholders)

set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS="$ROOT/Tools"

PYTHON="${PYTHON:-python3}"
AI_FEATURES="$TOOLS/ai_features.py"
IMPROVER="$TOOLS/improve_features_v2.py"
IMPROVER_ARGS="${IMPROVER_ARGS:-"--debug --batch 10 --force --think 10"}"

BATCH="${BATCH:-8}"
SLEEP="${SLEEP:-1}"
DRY_RUN="${DRY_RUN:-0}"
MAX_IMPROVE_PASSES="${MAX_IMPROVE_PASSES:-6}"
EXIT_ON_COMMIT_FAIL="${EXIT_ON_COMMIT_FAIL:-0}"
LOGFILE="${LOGFILE:-/tmp/feature_loop.$(whoami).log}"

if [ -f "$LOGFILE" ]; then
  size=$(stat -f%z "$LOGFILE" 2>/dev/null || stat -c%s "$LOGFILE" 2>/dev/null || echo 0)
  if [ "$size" -gt $((50*1024*1024)) ]; then
    mv "$LOGFILE" "$LOGFILE.$(date +%Y%m%d-%H%M%S)"
    : > "$LOGFILE"
  fi
fi

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
    $PYTHON "$AI_FEATURES" --debug 2>&1 | tee -a "$LOGFILE"
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
    # Run improver; capture its stdout/stderr to TMP_OUT and also append to LOGFILE
    eval "$PYTHON \"$IMPROVER\" $IMPROVER_ARGS" 2>&1 | tee "$TMP_OUT" | tee -a "$LOGFILE"
    RC=${PIPESTATUS[0]:-0}

    # Prefer machine markers emitted by improver (repo-relative paths)
    IMPROVER_CHANGED_FILES=$(grep -E '^IMPROVER_WRITTEN:' "$TMP_OUT" 2>/dev/null \
        | sed 's|^IMPROVER_WRITTEN:||' \
        | sed 's|^\./||' \
        | sort -u || true)

    # If no markers, fallback to legacy filename extraction (try to normalize to repo-relative)
    if [ -z "$IMPROVER_CHANGED_FILES" ]; then
        IMPROVER_CHANGED_FILES=$(grep -Eo '([A-Za-z0-9_./-]+\.swift|\.py|\.md|\.json)' "$TMP_OUT" \
            | sed -e "s|^$ROOT/||" -e 's|^\./||' \
            | sort -u || true)
    fi

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

    # normalize lines to repo-relative before filtering
    USER_FILES=$(printf '%s\n' "$files" | sed -e "s|^$ROOT/||" -e 's|^\./||' | grep -Ev '^Tools/' || true)
    if [ -z "$USER_FILES" ]; then
        echo "No user-facing files to commit." | tee -a "$LOGFILE"
        return 1
    fi

    echo "$USER_FILES" | while IFS= read -r f; do
        [ -z "$f" ] && continue
        if [ -e "$f" ]; then
            git add -- "$f" 2>/dev/null || git add -A -- "$f" 2>/dev/null || true
            echo "Staged: $f" | tee -a "$LOGFILE"
        fi
    done

    if git diff --cached --quiet; then
        echo "Nothing staged to commit." | tee -a "$LOGFILE"
        return 1
    fi

    if git commit -m "$message" >/dev/null 2>&1; then
        echo "Committed: $message" | tee -a "$LOGFILE"
        return 0
    else
        echo "Commit failed: $message" | tee -a "$LOGFILE"
        if [ "${EXIT_ON_COMMIT_FAIL:-0}" = "1" ]; then
            echo "EXIT_ON_COMMIT_FAIL=1; exiting." | tee -a "$LOGFILE"
            exit 2
        fi
        return 2
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

    CHANGED_USER=$(git --no-pager diff --name-only | grep -Ev '^Tools/' || true)
    if [ -n "$CHANGED_USER" ]; then
        commit_files "$CHANGED_USER" "Auto: user changes iteration $ITER" || true
    fi

    # Only edits are allowed — no placeholder fallback
    CHANGED_USER_POST=$(git --no-pager diff --name-only | grep -Ev '^Tools/' || true)
    if [ -z "$IMPROVER_CHANGED_FILES" ] && [ -z "$CHANGED_USER_POST" ]; then
        echo "No changes detected; nothing to commit." | tee -a "$LOGFILE"
    fi

    ITER=$((ITER+1))
    echo "Sleeping $SLEEP seconds..." | tee -a "$LOGFILE"
    sleep "$SLEEP"
done
