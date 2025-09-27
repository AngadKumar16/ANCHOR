#!/usr/bin/env bash
# Tools/loop.sh
# Orchestrates: build -> run -> ai-fix(dry-run) -> ai-fix(apply) -> commit -> repeat
# After N no-modify iterations -> ai_features(dry-run) -> ai_features(apply)
#
# Usage: from repo root:
#   RUN_MODE=launch ./Tools/loop.sh
#
# Env controls:
#   FIXER_SCHEME        (optional) override scheme name
#   MAX_RETRIES         (optional) 0 = infinite (default 0)
#   PREFERRED_SIM       (optional) e.g. "iPhone 16" (default)
#   RUN_MODE            "build" (default) | "test" | "launch"
#   FIXER_DEBUG         "1" to enable ai-fix debug logs
#   FIXER_MAX_EXCERPT   max excerpt passed to ai-fix (default 8000)
#   NO_MODIFY_TRIGGER   number of no-modify iterations before features mode (default 4)
#   MAX_STAGNANT_ATTEMPTS (default 5)
#   PYTHON              python binary (default python3)
#   GENAI_LOCAL/GEMINI_API_KEY for local Gemini if available
#
set -u

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TOOL_DIR="$PROJECT_DIR/Tools"
LOG="$TOOL_DIR/build.log"
LAST_HASH_FILE="$TOOL_DIR/.last_build_hash"
MAX_RETRIES="${MAX_RETRIES:-0}"   # 0 = infinite
SLEEP_BETWEEN="${SLEEP_BETWEEN:-1}"
ATTEMPT=1
PREFERRED_SIM="${PREFERRED_SIM:-iPhone 16}"
PYTHON="${PYTHON:-python3}"
AI_FIX_PY="$TOOL_DIR/ai_fix.py"
AI_FIX_NODE="$TOOL_DIR/ai-fix.js"
AI_FEATURES_PY="$TOOL_DIR/ai_features.py"
FIXER_DEBUG="${FIXER_DEBUG:-0}"
FIXER_MAX_EXCERPT="${FIXER_MAX_EXCERPT:-8000}"
NO_MODIFY_TRIGGER="${NO_MODIFY_TRIGGER:-4}"
MAX_STAGNANT_ATTEMPTS="${MAX_STAGNANT_ATTEMPTS:-5}"
RUN_MODE="${RUN_MODE:-build}"   # allowed: build | test | launch

# counters
STAGNANT_COUNT=0
NO_MODIFY_COUNT=0

cd "$PROJECT_DIR" || exit 1

echo "Starting auto-fixer in $PROJECT_DIR"
echo "Mode: $RUN_MODE"
echo "Logs -> $LOG"
echo "Ctrl-C to stop, or create $TOOL_DIR/STOP to stop."

# helpers
detect_scheme_and_build_base() {
  if [ -f "$PROJECT_DIR/Anchor.xcworkspace" ]; then
    LIST_CMD=(xcodebuild -list -workspace Anchor.xcworkspace)
    BUILD_BASE=(xcodebuild -workspace Anchor.xcworkspace)
  else
    LIST_CMD=(xcodebuild -list -project Anchor.xcodeproj)
    BUILD_BASE=(xcodebuild -project Anchor.xcodeproj)
  fi

  if [ -n "${FIXER_SCHEME:-}" ]; then
    SCHEME="$FIXER_SCHEME"
  else
    SCHEMES=$("${LIST_CMD[@]}" 2>/dev/null | awk '/Schemes:/{flag=1; next} /^$/{flag=0} flag{print}')
    SCHEME=$(echo "$SCHEMES" | sed -n '1p' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  fi
  if [ -z "$SCHEME" ]; then
    echo "⚠️ No scheme found. Please set FIXER_SCHEME or share scheme in Xcode."
    "${LIST_CMD[@]}"
    exit 1
  fi
  echo "Using scheme: '$SCHEME'"
}

detect_simulator() {
  if xcrun simctl list devices available | grep -q "$PREFERRED_SIM"; then
    SIM_NAME="$PREFERRED_SIM"
  else
    SIM_NAME=$(xcrun simctl list devices available | grep -E 'iPhone' | sed -E 's/([^(]+) \(.*$/\1/' | sed -n '1p' | sed 's/ *$//')
  fi
  if [ -z "$SIM_NAME" ]; then
    echo "⚠️ No iPhone simulators available. Install runtimes in Xcode > Settings > Components."
    exit 1
  fi
  SIM_UDID=$(xcrun simctl list devices available | awk -v name="$SIM_NAME" -F '[()]' 'tolower($0) ~ tolower(name){gsub(/^[[:space:]]+|[[:space:]]+$/,"",$1); print $2; exit}')
  echo "Using simulator: $SIM_NAME (udid: $SIM_UDID)"
}

hash_log() {
  if [ -f "$LOG" ]; then
    if command -v sha256sum >/dev/null 2>&1; then
      sha256sum "$LOG" | awk '{print $1}'
    else
      shasum -a 256 "$LOG" | awk '{print $1}'
    fi
  else
    echo ""
  fi
}

build_ai_fix_args() {
  local args=()
  # always include dry-run first when called from main loop (we call apply separately)
  [ "$FIXER_DEBUG" = "1" ] && args+=("--debug")
  [ -n "$FIXER_MAX_EXCERPT" ] && args+=("--max-excerpt=$FIXER_MAX_EXCERPT")
  echo "${args[@]}"
}

# read previous hash if present
PREV_LOG_HASH=""
[ -f "$LAST_HASH_FILE" ] && PREV_LOG_HASH="$(cat "$LAST_HASH_FILE" 2>/dev/null || true)"

# make sure tools exist
if [ ! -f "$AI_FIX_PY" ] && [ ! -f "$AI_FIX_NODE" ]; then
  echo "No ai-fix script found at $AI_FIX_PY or $AI_FIX_NODE. Please add one."
  exit 1
fi

trap 'echo "Interrupted by user"; exit 2' INT

detect_scheme_and_build_base
if [ "$RUN_MODE" = "launch" ] || [ "$RUN_MODE" = "test" ]; then
  detect_simulator
fi

echo "NO_MODIFY_TRIGGER=$NO_MODIFY_TRIGGER, MAX_STAGNANT_ATTEMPTS=$MAX_STAGNANT_ATTEMPTS"

# Main loop
while : ; do
  if [ -f "$TOOL_DIR/STOP" ]; then
    echo "STOP file detected ($TOOL_DIR/STOP). Exiting loop."
    exit 0
  fi

  if [ "$MAX_RETRIES" -gt 0 ] && [ "$ATTEMPT" -gt "$MAX_RETRIES" ]; then
    echo "⚠️ Max retries ($MAX_RETRIES) reached, stopping."
    exit 1
  fi

  echo
  echo "=============================="
  echo "Attempt $ATTEMPT - $(date)"
  echo "Building..."

  # run build/test (do not exit on non-zero)
  if [ "$RUN_MODE" = "test" ]; then
    "${BUILD_BASE[@]}" -scheme "$SCHEME" -sdk iphonesimulator -destination "platform=iOS Simulator,name=$SIM_NAME" test > "$LOG" 2>&1 || true
  else
    if [ -n "${SIM_NAME:-}" ]; then
      "${BUILD_BASE[@]}" -scheme "$SCHEME" -sdk iphonesimulator -destination "platform=iOS Simulator,name=$SIM_NAME" build > "$LOG" 2>&1 || true
    else
      "${BUILD_BASE[@]}" -scheme "$SCHEME" -sdk iphonesimulator build > "$LOG" 2>&1 || true
    fi
  fi

  # optional launch mode to capture runtime logs for a short window
  if [ "$RUN_MODE" = "launch" ]; then
    echo "Gathering build settings to locate built .app..."
    TMPSETTINGS="$TOOL_DIR/build_settings.txt"
    "${BUILD_BASE[@]}" -scheme "$SCHEME" -sdk iphonesimulator -destination "platform=iOS Simulator,name=$SIM_NAME" -showBuildSettings > "$TMPSETTINGS" 2>&1 || true
    BUILT_PRODUCTS_DIR=$(grep -m1 "BUILT_PRODUCTS_DIR" "$TMPSETTINGS" | awk -F'= ' '{print $2}' || true)
    FULL_PRODUCT_NAME=$(grep -m1 "FULL_PRODUCT_NAME" "$TMPSETTINGS" | awk -F'= ' '{print $2}' || true)
    APP_PATH=""
    if [ -n "$BUILT_PRODUCTS_DIR" ] && [ -n "$FULL_PRODUCT_NAME" ]; then
      APP_PATH="$BUILT_PRODUCTS_DIR/$FULL_PRODUCT_NAME"
    fi

    if [ -n "$APP_PATH" ] && [ -d "$APP_PATH" ]; then
      echo "Installing app to simulator..."
      xcrun simctl install "$SIM_UDID" "$APP_PATH" >> "$LOG" 2>&1 || true
      BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_PATH/Info.plist" 2>/dev/null || true)
      if [ -n "$BUNDLE_ID" ]; then
        echo "Launching $BUNDLE_ID on simulator (capturing console for 5s)..."
        if xcrun simctl launch --help 2>&1 | grep -q -- '--console'; then
          xcrun simctl launch --console "$SIM_UDID" "$BUNDLE_ID" >> "$LOG" 2>&1 &
          LAUNCH_PID=$!
          sleep 5
          kill ${LAUNCH_PID} >/dev/null 2>&1 || true
        else
          xcrun simctl spawn "$SIM_UDID" log stream --style compact --predicate 'processImagePath CONTAINS "'"$BUNDLE_ID"'"' >> "$LOG" 2>&1 &
          LOG_STREAM_PID=$!
          xcrun simctl launch "$SIM_UDID" "$BUNDLE_ID" >> "$LOG" 2>&1 || true
          sleep 5
          kill ${LOG_STREAM_PID} >/dev/null 2>&1 || true
        fi
      else
        echo "Could not read CFBundleIdentifier; skipping launch."
      fi
    else
      echo "No built .app found; skipping install/launch."
    fi
  fi

  # if build had no "error:" lines, consider it successful for this iteration
  if ! grep -q "error:" "$LOG"; then
    echo "✅ Build succeeded (or no 'error:' lines) on attempt $ATTEMPT"
    # NOTE: Do NOT reset NO_MODIFY_COUNT here anymore.
    # Previously this caused NO_MODIFY_COUNT never to reach the trigger when builds were clean.
    # Leave NO_MODIFY_COUNT alone so feature-mode can trigger after N consecutive iterations with no git changes.
    # continue to next iteration (maybe run tests etc.)
  else
    echo "❌ Build failed — parsing build log and running AI fixer (dry-run first)..."
    # --- AI fixer dry-run
    AI_ARGS="$(build_ai_fix_args)"
    echo "Invoking ai-fix (dry-run): $PYTHON $AI_FIX_PY $LOG $AI_ARGS --dry-run"
    # shellcheck disable=SC2086
    if [ -f "$AI_FIX_PY" ]; then
      $PYTHON "$AI_FIX_PY" "$LOG" $AI_ARGS --dry-run || echo "(ai-fix dry-run returned non-zero; continuing)"
    else
      node "$AI_FIX_NODE" "$LOG" --dry-run || echo "(node ai-fix dry-run returned non-zero; continuing)"
    fi

    # detect whether ai-fix proposed changes by checking ~/.ai-fix-issues/issues.json
    ISSUES_DB="$HOME/.ai-fix-issues/issues.json"
    PROPOSED=0
    if [ -f "$ISSUES_DB" ]; then
      # non-empty json -> proposals present
      if [ -s "$ISSUES_DB" ]; then
        # check if JSON has any keys (naive)
        if python3 - <<PY >/dev/null 2>&1
import json,sys
try:
  d=json.load(open("$ISSUES_DB"))
  sys.exit(0 if (d and len(d.keys())>0) else 1)
except Exception:
  sys.exit(1)
PY
        then
          PROPOSED=1
        fi
      fi
    fi

    if [ "$PROPOSED" -eq 1 ]; then
      echo "AI produced proposals (dry-run). Now applying fixes (real run)..."
      # apply fixes (no dry-run) and commit
      if [ -f "$AI_FIX_PY" ]; then
        $PYTHON "$AI_FIX_PY" "$LOG" $AI_ARGS --commit || echo "(ai-fix apply returned non-zero; continuing)"
      else
        node "$AI_FIX_NODE" "$LOG" --commit || echo "(node ai-fix apply returned non-zero; continuing)"
      fi
    else
      echo "AI dry-run produced no proposals; nothing to apply."
    fi
  fi

  # --- Check for git changes and update counters/trigger features when appropriate
    # --- Check for git changes and update counters/trigger features when appropriate
  CUR_LOG_HASH="$(hash_log)"
  if ! git diff --quiet --exit-code; then
    CHANGED=$(git --no-pager diff --name-only)
    echo "🧾 Git changes detected (raw):"
    echo "$CHANGED"

    # Filter out tool-only changes (Tools/ build log / last hash)
    # Keep user-code changes only (non-Tools)
    CHANGED_USER=$(echo "$CHANGED" | grep -Ev '^Tools/' || true)

    if [ -n "$CHANGED_USER" ]; then
      echo "Committing user-code changes:"
      echo "$CHANGED_USER"
      # stage only user files (avoid committing logs/.last_build_hash)
      git add $CHANGED_USER >/dev/null 2>&1 || git add -A
      if git commit -m "Auto-fixer: attempt $ATTEMPT" >/dev/null 2>&1; then
        echo "Committed fixes (attempt $ATTEMPT)."
        # Reset counters when actual code changes are made
        STAGNANT_COUNT=0
        NO_MODIFY_COUNT=0
      else
        echo "(commit failed or no changes staged for user files)"
      fi
      PREV_LOG_HASH="$CUR_LOG_HASH"
      echo "$PREV_LOG_HASH" > "$LAST_HASH_file" 2>/dev/null || true
    else
      # Only Tools/ or build artifacts changed — do NOT commit these; avoid resetting counters.
      echo "Only tool/build-log changes detected (Tools/, build.log, or .last_build_hash). Skipping commit."
      echo "You can inspect these with: git --no-pager diff -- Tools/"
      # leave NO_MODIFY_COUNT unchanged so the no-modify streak can continue
      # update prev log hash (so we can detect stagnation of log contents too)
      PREV_LOG_HASH="$CUR_LOG_HASH"
      echo "$PREV_LOG_HASH" > "$LAST_HASH_FILE"
      # Optionally discard log changes so git working tree stays clean:
      # git checkout -- Tools/build.log Tools/.last_build_hash >/dev/null 2>&1 || true
    fi
  else
    echo "No file changes made by AI."
    # increment no-modify counter — now this happens whenever there are no git changes,
    # regardless of whether build was successful or not.
    NO_MODIFY_COUNT=$((NO_MODIFY_COUNT+1))
    echo "No-modify count: $NO_MODIFY_COUNT / $NO_MODIFY_TRIGGER"

    if [ -n "$CUR_LOG_HASH" ] && [ "$CUR_LOG_HASH" = "$PREV_LOG_HASH" ]; then
      STAGNANT_COUNT=$((STAGNANT_COUNT+1))
      echo "Log repeated; stagnant count $STAGNANT_COUNT / $MAX_STAGNANT_ATTEMPTS"
    else
      STAGNANT_COUNT=0
    fi
    PREV_LOG_HASH="$CUR_LOG_HASH"
    echo "$PREV_LOG_HASH" > "$LAST_HASH_FILE"
  fi


  # --- Feature mode trigger: run ai_features.py in dry-run, then apply if it would do something
  if [ "$NO_MODIFY_COUNT" -ge "$NO_MODIFY_TRIGGER" ]; then
    echo "📌 No modifications for $NO_MODIFY_COUNT iterations — switching to feature-add dry-run."
    if [ -f "$AI_FEATURES_PY" ]; then
      FEAT_ARGS=()
      [ "$FIXER_DEBUG" = "1" ] && FEAT_ARGS+=("--debug")
      echo "Invoking ai_features (dry-run): $PYTHON $AI_FEATURES_PY --dry-run ${FEAT_ARGS[*]}"
      # capture output (robust)
      OUT_FEAT=$($PYTHON "$AI_FEATURES_PY" --dry-run "${FEAT_ARGS[@]}" 2>&1 || true)
      echo "$OUT_FEAT"
      # decision: look for a variety of indicators that features would be created/modified
      if echo "$OUT_FEAT" | grep -Ei "(would (create|write|modify|add|change)|Will create|Will write|\[dry-run\])" >/dev/null 2>&1; then
        echo "ai_features dry-run indicates actions. Applying feature changes now..."
        $PYTHON "$AI_FEATURES_PY" --commit "${FEAT_ARGS[@]}" 2>&1 || echo "(ai_features apply returned non-zero; continuing)"
        # After attempting to apply features, reset NO_MODIFY_COUNT so we don't immediately retrigger
        NO_MODIFY_COUNT=0
      else
        echo "ai_features dry-run indicated no actions or nothing to add."
        # If dry-run didn't indicate actions, still reset the counter so we don't spam dry-runs forever.
        NO_MODIFY_COUNT=0
      fi
    else
      echo "ai_features script not found at $AI_FEATURES_PY"
      # avoid infinite loop if script missing
      NO_MODIFY_COUNT=0
    fi
    # small safety sleep to avoid tight loop
    sleep 1
  fi

  if [ "$STAGNANT_COUNT" -ge "$MAX_STAGNANT_ATTEMPTS" ] && [ "$MAX_STAGNANT_ATTEMPTS" -gt 0 ]; then
    echo "⚠️ No progress after $STAGNANT_COUNT repeats; stopping loop for manual inspection."
    exit 2
  fi

  ATTEMPT=$((ATTEMPT+1))
  echo "Sleeping $SLEEP_BETWEEN seconds..."
  sleep "$SLEEP_BETWEEN"
done
