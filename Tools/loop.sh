#!/usr/bin/env bash
# Tools/loop.sh
# Orchestrates: build -> run -> ai-fix(apply) -> commit -> repeat
# After NO_MODIFY_TRIGGER no-modify iterations -> ai_features(apply)
#
# Usage: from repo root:
#   RUN_MODE=launch ./Tools/loop.sh
#
# Env controls:
#   FIXER_SCHEME, MAX_RETRIES, PREFERRED_SIM, RUN_MODE, FIXER_DEBUG,
#   FIXER_MAX_EXCERPT, NO_MODIFY_TRIGGER (default 1), MAX_STAGNANT_ATTEMPTS,
#   PYTHON (default python3), EXIT_ON_COMMIT_FAIL (default 1)
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
NO_MODIFY_TRIGGER="${NO_MODIFY_TRIGGER:-1}"   # trigger features immediately on first no-modify
MAX_STAGNANT_ATTEMPTS="${MAX_STAGNANT_ATTEMPTS:-5}"
RUN_MODE="${RUN_MODE:-build}"   # allowed: build | test | launch
EXIT_ON_COMMIT_FAIL="${EXIT_ON_COMMIT_FAIL:-1}"  # 1 = stop loop if commit fails

# counters
STAGNANT_COUNT=0
NO_MODIFY_COUNT=0
FEAT_ARGS=()

cd "$PROJECT_DIR" || exit 1

echo "Starting auto-fixer in $PROJECT_DIR"
echo "Mode: $RUN_MODE"
echo "Logs -> $LOG"
echo "Ctrl-C to stop, or create $TOOL_DIR/STOP to stop."
echo "EXIT_ON_COMMIT_FAIL=$EXIT_ON_COMMIT_FAIL"

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
  if [ -z "${SIM_NAME:-}" ]; then
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
  [ "${FIXER_DEBUG:-0}" = "1" ] && args+=("--debug")
  [ -n "${FIXER_MAX_EXCERPT:-}" ] && args+=("--max-excerpt=$FIXER_MAX_EXCERPT")
  echo "${args[@]}"
}

PREV_LOG_HASH=""
[ -f "$LAST_HASH_FILE" ] && PREV_LOG_HASH="$(cat "$LAST_HASH_FILE" 2>/dev/null || true)"

if [ ! -f "$AI_FIX_PY" ] && [ ! -f "$AI_FIX_NODE" ]; then
  echo "No ai-fix script found at $AI_FIX_PY or $AI_FIX_NODE. Please add one."
  exit 1
fi

trap 'echo "Interrupted by user"; exit 2' INT

detect_scheme_and_build_base
if [ "$RUN_MODE" = "launch" ] || [ "$RUN_MODE" = "test" ] || [ "$RUN_MODE" = "build" ]; then
  detect_simulator
fi

echo "NO_MODIFY_TRIGGER=$NO_MODIFY_TRIGGER, MAX_STAGNANT_ATTEMPTS=$MAX_STAGNANT_ATTEMPTS"

# Run a command and return rc (prints output)
run_and_capture() {
  # "$@" is the command
  "$@" 2>&1 | tee -a "$LOG"
  return ${PIPESTATUS[0]:-0}
}

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
    "${BUILD_BASE[@]}" -scheme "$SCHEME" -sdk iphonesimulator -destination "platform=iOS Simulator,name=$SIM_NAME" build > "$LOG" 2>&1 || true
  fi

  # optional launch mode to capture runtime logs for a short window
  if [ "$RUN_MODE" = "launch" ]; then
    echo "Gathering build settings to locate built .app..." | tee -a "$LOG"
    TMPSETTINGS="$TOOL_DIR/build_settings.txt"
    "${BUILD_BASE[@]}" -scheme "$SCHEME" -sdk iphonesimulator -destination "platform=iOS Simulator,name=$SIM_NAME" -showBuildSettings > "$TMPSETTINGS" 2>&1 || true
    BUILT_PRODUCTS_DIR=$(grep -m1 "BUILT_PRODUCTS_DIR" "$TMPSETTINGS" | awk -F'= ' '{print $2}' || true)
    FULL_PRODUCT_NAME=$(grep -m1 "FULL_PRODUCT_NAME" "$TMPSETTINGS" | awk -F'= ' '{print $2}' || true)
    APP_PATH=""
    if [ -n "$BUILT_PRODUCTS_DIR" ] && [ -n "$FULL_PRODUCT_NAME" ]; then
      APP_PATH="$BUILT_PRODUCTS_DIR/$FULL_PRODUCT_NAME"
    fi

    if [ -n "$APP_PATH" ] && [ -d "$APP_PATH" ]; then
      echo "Installing app to simulator..." | tee -a "$LOG"
      xcrun simctl install "$SIM_UDID" "$APP_PATH" >> "$LOG" 2>&1 || true
      BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_PATH/Info.plist" 2>/dev/null || true)
      if [ -n "$BUNDLE_ID" ]; then
        echo "Launching $BUNDLE_ID on simulator (capturing console for 5s)..." | tee -a "$LOG"
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
        echo "Could not read CFBundleIdentifier; skipping launch." | tee -a "$LOG"
      fi
    else
      echo "No built .app found; skipping install/launch." | tee -a "$LOG"
    fi
  fi

  # if build had no "error:" lines, consider it successful for this iteration
  if ! grep -q "error:" "$LOG"; then
    echo "✅ Build succeeded (or no 'error:' lines) on attempt $ATTEMPT" | tee -a "$LOG"
  else
    echo "❌ Build failed — parsing build log and running AI fixer (apply mode)..." | tee -a "$LOG"
    AI_ARGS="$(build_ai_fix_args)"
    echo "Invoking ai-fix (apply): $PYTHON $AI_FIX_PY $LOG $AI_ARGS --commit" | tee -a "$LOG"

    if [ -f "$AI_FIX_PY" ]; then
      run_and_capture $PYTHON "$AI_FIX_PY" "$LOG" $AI_ARGS --commit
      RC_AI_FIX=$?
    else
      run_and_capture node "$AI_FIX_NODE" "$LOG" --commit
      RC_AI_FIX=$?
    fi

    echo "ai-fix exit code: $RC_AI_FIX" | tee -a "$LOG"

    # if ai-fix wrote files, check commit status
    if ! git diff --quiet --exit-code; then
      CHANGED=$(git --no-pager diff --name-only)
      echo "🧾 Git changes detected after ai-fix (raw):" | tee -a "$LOG"
      echo "$CHANGED" | tee -a "$LOG"

      CHANGED_USER=$(echo "$CHANGED" | grep -Ev '^Tools/' || true)

      if [ -n "$CHANGED_USER" ]; then
        echo "Committing user-code changes:" | tee -a "$LOG"
        echo "$CHANGED_USER" | tee -a "$LOG"
        git add $CHANGED_USER >/dev/null 2>&1 || git add -A
        if git commit -m "Auto-fixer: attempt $ATTEMPT" >/dev/null 2>&1; then
          echo "Committed fixes (attempt $ATTEMPT)." | tee -a "$LOG"
          STAGNANT_COUNT=0
          NO_MODIFY_COUNT=0
        else
          echo "(commit failed or no changes staged for user files)" | tee -a "$LOG"
          if [ "$EXIT_ON_COMMIT_FAIL" = "1" ]; then
            echo "Exiting loop due to commit failure (EXIT_ON_COMMIT_FAIL=1)." | tee -a "$LOG"
            exit 2
          fi
        fi
        PREV_LOG_HASH="$(hash_log)"
        echo "$PREV_LOG_HASH" > "$LAST_HASH_FILE"
      else
        echo "Only tool/build-log changes detected (Tools/, build.log, or .last_build_hash). Skipping commit." | tee -a "$LOG"
        PREV_LOG_HASH="$(hash_log)"
        echo "$PREV_LOG_HASH" > "$LAST_HASH_FILE"
        NO_MODIFY_COUNT=$((NO_MODIFY_COUNT+1))
        echo "No-modify count (tool-only changes): $NO_MODIFY_COUNT / $NO_MODIFY_TRIGGER" | tee -a "$LOG"
      fi
    else
      echo "No file changes made by ai-fix." | tee -a "$LOG"
      NO_MODIFY_COUNT=$((NO_MODIFY_COUNT+1))
      echo "No-modify count: $NO_MODIFY_COUNT / $NO_MODIFY_TRIGGER" | tee -a "$LOG"
      PREV_LOG_HASH="$(hash_log)"
      echo "$PREV_LOG_HASH" > "$LAST_HASH_FILE"
    fi
  fi

  # --- Feature mode trigger (now immediate when NO_MODIFY_COUNT >= NO_MODIFY_TRIGGER)
  if [ "$NO_MODIFY_COUNT" -ge "$NO_MODIFY_TRIGGER" ]; then
    echo "📌 No modifications for $NO_MODIFY_COUNT iterations — switching to feature-add (apply)..." | tee -a "$LOG"
    if [ -f "$AI_FEATURES_PY" ]; then
      FEAT_ARGS=()
      if [ "${FIXER_DEBUG:-0}" = "1" ]; then
        FEAT_ARGS+=("--debug")
      fi

      if [ "${#FEAT_ARGS[@]}" -gt 0 ]; then
        FEAT_PREVIEW="$(printf ' %s' "${FEAT_ARGS[@]}")"
      else
        FEAT_PREVIEW=""
      fi

      echo "Invoking ai_features (apply): $PYTHON $AI_FEATURES_PY --commit${FEAT_PREVIEW}" | tee -a "$LOG"
      if [ "${#FEAT_ARGS[@]}" -gt 0 ]; then
        run_and_capture $PYTHON "$AI_FEATURES_PY" --commit "${FEAT_ARGS[@]}"
        RC_AI_FEAT=$?
      else
        run_and_capture $PYTHON "$AI_FEATURES_PY" --commit
        RC_AI_FEAT=$?
      fi

      echo "ai_features exit code: $RC_AI_FEAT" | tee -a "$LOG"

      # if ai_features changed files, attempt commit
      if ! git diff --quiet --exit-code; then
        CHANGED=$(git --no-pager diff --name-only)
        echo "🧾 Git changes detected after ai_features (raw):" | tee -a "$LOG"
        echo "$CHANGED" | tee -a "$LOG"
        CHANGED_USER=$(echo "$CHANGED" | grep -Ev '^Tools/' || true)
        if [ -n "$CHANGED_USER" ]; then
          git add $CHANGED_USER >/dev/null 2>&1 || git add -A
          if git commit -m "AI-features: add features (attempt $ATTEMPT)" >/dev/null 2>&1; then
            echo "Committed feature additions." | tee -a "$LOG"
            NO_MODIFY_COUNT=0
            STAGNANT_COUNT=0
          else
            echo "(feature commit failed)" | tee -a "$LOG"
            if [ "$EXIT_ON_COMMIT_FAIL" = "1" ]; then
              echo "Exiting loop due to commit failure (EXIT_ON_COMMIT_FAIL=1)." | tee -a "$LOG"
              exit 3
            fi
          fi
        else
          echo "Only tool/build changes after ai_features; skipping commit." | tee -a "$LOG"
          NO_MODIFY_COUNT=0
        fi
      else
        echo "No file changes made by ai_features." | tee -a "$LOG"
        NO_MODIFY_COUNT=0
      fi

    else
      echo "ai_features script not found at $AI_FEATURES_PY" | tee -a "$LOG"
      NO_MODIFY_COUNT=0
    fi
    sleep 1
  fi

  if [ "$STAGNANT_COUNT" -ge "$MAX_STAGNANT_ATTEMPTS" ] && [ "$MAX_STAGNANT_ATTEMPTS" -gt 0 ]; then
    echo "⚠️ No progress after $STAGNANT_COUNT repeats; stopping loop for manual inspection." | tee -a "$LOG"
    exit 2
  fi

  ATTEMPT=$((ATTEMPT+1))
  echo "Sleeping $SLEEP_BETWEEN seconds..." | tee -a "$LOG"
  sleep "$SLEEP_BETWEEN"
done
