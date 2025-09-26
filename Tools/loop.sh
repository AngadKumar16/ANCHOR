#!/usr/bin/env bash
# Tools/loop.sh  (updated)
# Build -> (optional) test / launch -> parse log -> ai-fix -> commit -> repeat
# Usage: ./Tools/loop.sh
#
# Env:
#   FIXER_SCHEME       (optional) override scheme name
#   MAX_RETRIES        (optional) 0 = infinite (default 0)
#   PREFERRED_SIM      (optional) e.g. "iPhone 16" (default)
#   RUN_MODE           "build" (default) | "test" | "launch"   <-- choose mode
#   FIXER_DRY_RUN      "1" to dry-run ai-fix (no writes)
#   FIXER_DEBUG        "1" to enable ai-fix debug logs
#   FIXER_COMMIT       "1" to allow commits (default 1)
#   MAX_STAGNANT_ATTEMPTS (default 5)
#   PYTHON             path to python (default python3)

set -u

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TOOL_DIR="$PROJECT_DIR/Tools"
LOG="$TOOL_DIR/build.log"
LAST_HASH_FILE="$TOOL_DIR/.last_build_hash"
MAX_RETRIES="${MAX_RETRIES:-0}"
SLEEP_BETWEEN="${SLEEP_BETWEEN:-1}"
ATTEMPT=1
PREFERRED_SIM="${PREFERRED_SIM:-iPhone 16}"
PYTHON="${PYTHON:-python3}"
AI_FIX_PY="$TOOL_DIR/ai_fix.py"
AI_FIX_NODE="$TOOL_DIR/ai-fix.js"
FIXER_DRY_RUN="${FIXER_DRY_RUN:-0}"
FIXER_DEBUG="${FIXER_DEBUG:-0}"
FIXER_COMMIT="${FIXER_COMMIT:-1}"
MAX_STAGNANT_ATTEMPTS="${MAX_STAGNANT_ATTEMPTS:-5}"
RUN_MODE="${RUN_MODE:-build}"   # allowed: build | test | launch

cd "$PROJECT_DIR" || exit 1

echo "Starting auto-fixer in $PROJECT_DIR"
echo "Mode: $RUN_MODE"
echo "Logs -> $LOG"
echo "Ctrl-C to stop, or create $TOOL_DIR/STOP to stop."

# ---------------- helpers ----------------
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
    echo "⚠️ No scheme found. Please set FIXER_SCHEME to your scheme name or share a scheme in Xcode."
    "${LIST_CMD[@]}"
    exit 1
  fi
  echo "Using scheme: '$SCHEME'"
}

detect_simulator() {
  # pick preferred or first available iPhone simulator
  if xcrun simctl list devices available | grep -q "$PREFERRED_SIM"; then
    SIM_NAME="$PREFERRED_SIM"
  else
    SIM_NAME=$(xcrun simctl list devices available | grep -E 'iPhone' | sed -E 's/([^(]+) \(.*$/\1/' | sed -n '1p' | sed 's/ *$//')
  fi
  if [ -z "$SIM_NAME" ]; then
    echo "⚠️ No iPhone simulators available. Install runtimes in Xcode > Settings > Components."
    exit 1
  fi
  # get UDID for the simulator name (choose the first match)
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
  [ "$FIXER_DRY_RUN" = "1" ] && args+=("--dry-run")
  [ "$FIXER_DEBUG" = "1" ] && args+=("--debug")
  [ "$FIXER_COMMIT" = "1" ] && args+=("--commit")
  echo "${args[@]}"
}

trap 'echo "Interrupted"; exit 2' INT

detect_scheme_and_build_base
if [ "$RUN_MODE" = "launch" ] || [ "$RUN_MODE" = "test" ]; then
  detect_simulator
fi

STAGNANT_COUNT=0
PREV_LOG_HASH=""
[ -f "$LAST_HASH_FILE" ] && PREV_LOG_HASH="$(cat "$LAST_HASH_FILE" 2>/dev/null || true)"

while : ; do
  if [ -f "$TOOL_DIR/STOP" ]; then
    echo "STOP detected. Exiting."
    exit 0
  fi
  if [ "$MAX_RETRIES" -gt 0 ] && [ "$ATTEMPT" -gt "$MAX_RETRIES" ]; then
    echo "Max retries reached."
    exit 1
  fi

  echo
  echo "=============================="
  echo "Attempt $ATTEMPT - $(date)"
  echo "Running xcodebuild..."

  # choose build/test command
  if [ "$RUN_MODE" = "test" ]; then
    # run tests (this produces test failure logs that ai-fix can parse)
    "${BUILD_BASE[@]}" -scheme "$SCHEME" -sdk iphonesimulator -destination "platform=iOS Simulator,name=$SIM_NAME" test > "$LOG" 2>&1 || true
  else
    # build
    "${BUILD_BASE[@]}" -scheme "$SCHEME" -sdk iphonesimulator -destination "platform=iOS Simulator,name=$SIM_NAME" build > "$LOG" 2>&1 || true
  fi

  # If RUN_MODE=launch and build succeeded, attempt install+launch to capture runtime logs
  if [ "$RUN_MODE" = "launch" ]; then
    # parse build settings to find .app
    echo "Gathering build settings to locate built .app..."
    TMPSETTINGS="$TOOL_DIR/build_settings.txt"
    "${BUILD_BASE[@]}" -scheme "$SCHEME" -sdk iphonesimulator -destination "platform=iOS Simulator,name=$SIM_NAME" -showBuildSettings > "$TMPSETTINGS" 2>&1 || true
    BUILT_PRODUCTS_DIR=$(grep -m1 "BUILT_PRODUCTS_DIR" "$TMPSETTINGS" | awk -F'= ' '{print $2}' || true)
    FULL_PRODUCT_NAME=$(grep -m1 "FULL_PRODUCT_NAME" "$TMPSETTINGS" | awk -F'= ' '{print $2}' || true)
    APP_PATH=""
    if [ -n "$BUILT_PRODUCTS_DIR" ] && [ -n "$FULL_PRODUCT_NAME" ]; then
      APP_PATH="$BUILT_PRODUCTS_DIR/$FULL_PRODUCT_NAME"
    fi

    if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
      echo "Could not find built .app at $APP_PATH; check build output. Continuing to ai-fix with build log only."
    else
      echo "Found app: $APP_PATH"
      # ensure simulator is booted
      xcrun simctl bootstatus "$SIM_UDID" -b >/dev/null 2>&1 || xcrun simctl boot "$SIM_UDID" >/dev/null 2>&1 || true
      # install
      echo "Installing app to simulator..."
      xcrun simctl install "$SIM_UDID" "$APP_PATH" >> "$LOG" 2>&1 || true
      # read bundle id from Info.plist (best-effort)
      BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_PATH/Info.plist" 2>/dev/null || true)
      if [ -z "$BUNDLE_ID" ]; then
        echo "Could not read CFBundleIdentifier from app; skipping launch."
      else
        echo "Launching $BUNDLE_ID on simulator (console output appended to $LOG)..."
        # launch and stream console into log (backgrounded for capture)
        # use `simctl launch --console` if available, otherwise run spawn
        if xcrun simctl launch --help 2>&1 | grep -q -- '--console'; then
          xcrun simctl launch --console "$SIM_UDID" "$BUNDLE_ID" >> "$LOG" 2>&1 &
          LAUNCH_PID=$!
          sleep 5
          kill ${LAUNCH_PID} >/dev/null 2>&1 || true
        else
          # fallback: spawn and capture syslog for a brief window
          xcrun simctl spawn "$SIM_UDID" log stream --style compact --predicate 'processImagePath CONTAINS "'"$BUNDLE_ID"'"' >> "$LOG" 2>&1 &
          LOG_STREAM_PID=$!
          # start app normally
          xcrun simctl launch "$SIM_UDID" "$BUNDLE_ID" >> "$LOG" 2>&1 || true
          # allow the log stream to run briefly then kill it (so loop can continue)
          sleep 3
          kill ${LOG_STREAM_PID} >/dev/null 2>&1 || true
        fi
      fi
    fi
  fi

  # call ai-fix
  echo "Calling ai-fix on $LOG..."
  AI_FIX_ARGS="$(build_ai_fix_args)"
  if [ -f "$AI_FIX_PY" ]; then
    echo "Invoking: $PYTHON $AI_FIX_PY $LOG $AI_FIX_ARGS"
    # shellcheck disable=SC2086
    $PYTHON "$AI_FIX_PY" "$LOG" $AI_FIX_ARGS || echo "(ai-fix returned non-zero; continuing)"
  elif [ -f "$AI_FIX_NODE" ]; then
    echo "Invoking node ai-fix"
    node "$AI_FIX_NODE" "$LOG" || echo "(node ai-fix returned non-zero; continuing)"
  else
    echo "No ai-fix script found."
    exit 1
  fi

  # check git changes
  CUR_LOG_HASH="$(hash_log)"
  if ! git diff --quiet --exit-code; then
    CHANGED=$(git --no-pager diff --name-only)
    echo "🧾 Git changes detected:"
    echo "$CHANGED"
    git add -A
    if git commit -m "Auto-fixer: attempt $ATTEMPT" >/dev/null 2>&1; then
      echo "Committed fixes (attempt $ATTEMPT)."
    else
      echo "(commit failed or no changes staged)"
    fi
    STAGNANT_COUNT=0
    PREV_LOG_HASH="$CUR_LOG_HASH"
    echo "$PREV_LOG_HASH" > "$LAST_HASH_FILE"
  else
    echo "No file changes made by AI."
    if [ -n "$CUR_LOG_HASH" ] && [ "$CUR_LOG_HASH" = "$PREV_LOG_HASH" ]; then
      STAGNANT_COUNT=$((STAGNANT_COUNT+1))
      echo "Log repeated; stagnant count $STAGNANT_COUNT / $MAX_STAGNANT_ATTEMPTS"
    else
      STAGNANT_COUNT=0
    fi
    PREV_LOG_HASH="$CUR_LOG_HASH"
    echo "$PREV_LOG_HASH" > "$LAST_HASH_FILE"
  fi

  if [ "$STAGNANT_COUNT" -ge "$MAX_STAGNANT_ATTEMPTS" ] && [ "$MAX_STAGNANT_ATTEMPTS" -gt 0 ]; then
    echo "No progress after $STAGNANT_COUNT repeats; stopping loop for manual inspection."
    exit 2
  fi

  ATTEMPT=$((ATTEMPT+1))
  echo "Sleeping $SLEEP_BETWEEN seconds..."
  sleep "$SLEEP_BETWEEN"
done
