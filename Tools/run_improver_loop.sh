#!/bin/bash
# ===============================================================
# Iterative improver + backend recovery loop for ANCHOR app
# ===============================================================

CONFIG="Tools/.improver_config.json"
ITERATIONS_BEFORE_RUN=5
COUNTER=0
WORKSPACE="./ANCHOR.xcodeproj/project.xcworkspace"
SCHEME="ANCHOR"
DESTINATION="platform=iOS Simulator,name=iPhone 14,OS=17.0"
LOG_DIR="Tools/logs"
BACKEND_DIR="backend"

mkdir -p "$LOG_DIR"

run_improver() {
    echo "🧠 Running improver..."
    python3 Tools/improver_loop.py --config "$CONFIG"
    return $?
}

run_backend_fix() {
    echo "🧩 Running backend repair mode..."
    python3 Tools/improver_loop.py --config "$CONFIG" --path "$BACKEND_DIR" --focus backend
}

check_backend_errors() {
    LOGFILE="$1"
    echo "🔍 Checking for backend-related errors..."
    if grep -q -E "connection refused|backend unavailable|Network error|failed to fetch" "$LOGFILE"; then
        echo "❌ Backend seems offline or missing API routes."
        run_backend_fix
        return 1
    fi
    return 0
}

while true; do
    echo "==================================================================="
    echo "Improver iteration $((COUNTER + 1)) started at $(date)"
    echo "==================================================================="

    run_improver
    STATUS=$?
    if [ $STATUS -ne 0 ]; then
        echo "❌ Improver exited with code $STATUS. Retrying..."
        sleep 10
        continue
    fi

    COUNTER=$((COUNTER + 1))

    # After N iterations, test build
    if [ $COUNTER -ge $ITERATIONS_BEFORE_RUN ]; then
        TS=$(date +%Y%m%d_%H%M%S)
        LOGFILE="$LOG_DIR/xcodebuild_$TS.log"
        echo "-------------------------------------------------------------------"
        echo "Running app build/test after $COUNTER iterations..."
        echo "-------------------------------------------------------------------"

        xcodebuild test \
            -workspace "$WORKSPACE" \
            -scheme "$SCHEME" \
            -destination "$DESTINATION" \
            | tee "$LOGFILE"

        BUILD_STATUS=${PIPESTATUS[0]}

        if [ $BUILD_STATUS -ne 0 ]; then
            echo "❌ Build failed — running improver again to fix errors..."
            COUNTER=0
            sleep 10
            continue
        fi

        echo "✅ Build succeeded. Launching simulator..."
        xcrun simctl boot "iPhone 14" || true
        open -a Simulator
        xcrun simctl install booted build/Release-iphonesimulator/ANCHOR.app 2>&1 | tee -a "$LOGFILE"
        xcrun simctl launch booted com.yourcompany.ANCHOR 2>&1 | tee -a "$LOGFILE"

        check_backend_errors "$LOGFILE"
        BACKEND_STATUS=$?

        if [ $BACKEND_STATUS -eq 1 ]; then
            echo "⚙️ Backend repair triggered. Restarting loop..."
            COUNTER=0
            sleep 10
            continue
        fi

        echo "✅ App launch verified. Resetting iteration counter."
        COUNTER=0
    fi

    echo "Sleeping 10 seconds before next iteration..."
    sleep 10
done
