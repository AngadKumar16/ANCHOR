#!/usr/bin/env bash
# Tools/loop.sh
# Self-loop driver: build -> check -> ai-fix -> commit -> repeat
# Usage: from project root run: ./Tools/loop.sh
# Environment:
#   FIXER_SCHEME (optional) - override scheme name
#   MAX_RETRIES (optional) - 0 = infinite (default 0)
#   PREFERRED_SIM (optional) - e.g. "iPhone 16" default "iPhone 16"

set -u

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TOOL_DIR="$PROJECT_DIR/Tools"
LOG="$TOOL_DIR/build.log"
MAX_RETRIES="${MAX_RETRIES:-0}"   # 0 = infinite
SLEEP_BETWEEN="${SLEEP_BETWEEN:-1}"
ATTEMPT=1
PREFERRED_SIM="${PREFERRED_SIM:-iPhone 16}"

cd "$PROJECT_DIR" || exit 1

echo "Starting Anchor auto-fixer in $PROJECT_DIR"
echo "Logs will go to $LOG"
echo "Press Ctrl-C to stop, or create $TOOL_DIR/STOP to stop gracefully."

# helper: choose scheme/workspace
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
    SCHEMES=$("${LIST_CMD[@]}" 2>/dev/null | awk '/Schemes:/{flag=1; next} /^$/{flag=0} flag{print}' )
    if [ -z "$SCHEMES" ]; then
      echo "⚠️ No shared schemes detected. Share a scheme in Xcode: Product → Scheme → Manage Schemes → check 'Shared'."
      "${LIST_CMD[@]}"
      exit 1
    fi
    SCHEME=$(echo "$SCHEMES" | sed -n '1p' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  fi

  echo "Using scheme: '$SCHEME'"
}

# helper: pick a simulator name available on machine
detect_simulator() {
  # prefer PREFERRED_SIM if installed
  if xcrun simctl list devices available | grep -q "$PREFERRED_SIM"; then
    SIM_NAME="$PREFERRED_SIM"
  else
    SIM_NAME=$(xcrun simctl list devices available | grep -E 'iPhone' | sed -E 's/([^(]+) \(.*$/\1/' | sed -n '1p' | sed 's/ *$//')
  fi

  if [ -z "$SIM_NAME" ]; then
    echo "⚠️ No iPhone simulators found. Install simulator runtimes or open Xcode > Settings > Components."
    xcrun simctl list devices available
    exit 1
  fi

  echo "Using simulator: $SIM_NAME"
  DESTINATION="platform=iOS Simulator,name=$SIM_NAME"
}

# trap ctrl-c to exit gracefully
trap 'echo "Interrupted by user"; exit 2' INT

detect_scheme_and_build_base
detect_simulator

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
  echo "Attempt $ATTEMPT ${MAX_RETRIES:+/ $MAX_RETRIES} - $(date)"
  echo "Building..."
  # run build (do not exit on non-zero)
  "${BUILD_BASE[@]}" -scheme "$SCHEME" -sdk iphonesimulator -destination "$DESTINATION" build > "$LOG" 2>&1 || true

  # quick checks
  if ! grep -q "error:" "$LOG"; then
    echo "✅ Build succeeded on attempt $ATTEMPT"
    # optional: run tests here if you want
    exit 0
  fi

  echo "❌ Build failed — parsing build log and calling AI fixer..."
  # call ai-fix.js (it returns a JSON-like summary)
  node "$TOOL_DIR/ai-fix.js" "$LOG" || echo "(ai-fix returned non-zero; continuing)"

  # if there are git changes, create a checkpoint commit
  if ! git diff --quiet --exit-code; then
    CHANGED=$(git --no-pager diff --name-only)
    echo "🧾 Git changes detected (files changed):"
    echo "$CHANGED"
    git add -A
    git commit -m "Auto-fixer: attempt $ATTEMPT" || echo "(commit failed or no changes staged)"
  else
    echo "No file changes made by AI on this attempt."
  fi

  ATTEMPT=$((ATTEMPT+1))
  echo "Sleeping $SLEEP_BETWEEN seconds before next build..."
  sleep "$SLEEP_BETWEEN"
done
