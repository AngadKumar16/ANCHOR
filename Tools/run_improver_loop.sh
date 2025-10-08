#!/bin/bash
# ===============================================================
# Iterative improver loop for ANCHOR app
# ===============================================================

CONFIG="Tools/.improver_config.json"
ITERATIONS_BEFORE_RUN=5
COUNTER=0
WORKSPACE="./ANCHOR.xcodeproj/project.xcworkspace"
SCHEME="ANCHOR"
DESTINATION="platform=iOS Simulator,name=iPhone 14,OS=17.0"

while true; do
    echo "==================================================================="
    echo "Improver iteration $((COUNTER + 1)) started at $(date)"
    echo "==================================================================="

    # Step 1: Run the improver (adds/enhances code)
    python3 Tools/improver_loop.py --config "$CONFIG"
    STATUS=$?
    if [ $STATUS -ne 0 ]; then
        echo "❌ Improver exited with error code $STATUS. Retrying..."
        sleep 10
        continue
    fi

    COUNTER=$((COUNTER + 1))

    # Step 2: Every 5 iterations, try building/running the app
    if [ $COUNTER -ge $ITERATIONS_BEFORE_RUN ]; then
        echo "-------------------------------------------------------------------"
        echo "Running app build/test after $COUNTER iterations..."
        echo "-------------------------------------------------------------------"

        xcodebuild test \
            -workspace "$WORKSPACE" \
            -scheme "$SCHEME" \
            -destination "$DESTINATION" \
            | tee "Tools/logs/xcodebuild_$(date +%Y%m%d_%H%M%S).log"

        BUILD_STATUS=${PIPESTATUS[0]}

        if [ $BUILD_STATUS -ne 0 ]; then
            echo "❌ Build failed — running improver again to fix errors..."
            COUNTER=0
            sleep 10
            continue
        fi

        echo "✅ Build succeeded! Now testing functionality..."

        # Optional: Run app on simulator for quick validation
        xcrun simctl boot "iPhone 14" || true
        open -a Simulator
        xcrun simctl install booted build/Release-iphonesimulator/ANCHOR.app
        xcrun simctl launch booted com.yourcompany.ANCHOR || echo "⚠️ App launch may need manual check"

        echo "✅ App appears to run. Resetting iteration counter."
        COUNTER=0
    fi

    echo "Sleeping 10 seconds before next iteration..."
    sleep 10
done
