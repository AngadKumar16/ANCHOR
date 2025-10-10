#!/bin/bash
# ===============================================================
# Iterative improver + backend recovery loop for ANCHOR app
# ===============================================================

set -euo pipefail

# Configuration
CONFIG="Tools/.improver_config.json"
ITERATIONS_BEFORE_RUN=5
COUNTER=0
WORKSPACE="./ANCHOR.xcodeproj/project.xcworkspace"
SCHEME="ANCHOR"
DESTINATION="platform=iOS Simulator,name=iPhone 16,OS=18.4"
LOG_DIR="Tools/logs"
BACKEND_DIR="backend"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Git functions
git_commit_changes() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    git add .
    if ! git diff-index --quiet HEAD --; then
        git commit -m "Improver: Auto-commit changes at $timestamp"
        return 0
    fi
    return 1
}

git_push_changes() {
    local branch=$1
    echo "Pushing changes to origin/$branch..."
    if git push origin "$branch"; then
        echo "Successfully pushed changes to origin/$branch"
        return 0
    else
        echo "Failed to push changes. Attempting to pull and retry..."
        git pull --rebase origin "$branch"
        if git push origin "$branch"; then
            echo "Successfully pushed changes after pull"
            return 0
        fi
    fi
    return 1
}

run_improver() {
    echo "Running improver..."
    local log_file="$LOG_DIR/improver_$(date +%Y%m%d_%H%M%S).log"
    python3 Tools/improver_loop.py --config "$CONFIG" 2>&1 | tee "$log_file"
    local status=${PIPESTATUS[0]}
    
    # Check for changes and commit/push if needed
    if [[ $status -eq 0 ]] && [[ "$(jq -r '.auto_commit // false' "$CONFIG")" == "true" ]]; then
        if git_commit_changes; then
            if [[ "$(jq -r '.auto_push // false' "$CONFIG")" == "true" ]]; then
                local branch=$(git rev-parse --abbrev-ref HEAD)
                git_push_changes "$branch"
            fi
        fi
    fi
    
    return $status
}

run_backend_fix() {
    echo "Running backend repair mode..."
    python3 Tools/improver_loop.py --config "$CONFIG" --path "$BACKEND_DIR" --focus backend
}

check_backend_errors() {
    local log_file="$1"
    echo "Checking for backend-related errors..."
    if grep -q -E "connection refused|backend unavailable|Network error|failed to fetch" "$log_file"; then
        echo "Backend seems offline or missing API routes."
        run_backend_fix
        return 1
    fi
    return 0
}

# Main loop
while true; do
    echo "==================================================================="
    echo "Improver iteration $((COUNTER + 1)) started at $(date)"
    echo "==================================================================="

    run_improver
    local status=$?
    
    if [[ $status -ne 0 ]]; then
        echo "Improver exited with code $status. Checking for backend issues..."
        check_backend_errors "$LOG_DIR/improver_$(date +%Y%m%d_%H%M%S).log" || true
    fi

    COUNTER=$((COUNTER + 1))
    
    # Check if we've reached the maximum number of iterations
    if [[ $COUNTER -ge $(jq -r '.max_iterations // 50' "$CONFIG") ]]; then
        echo "Reached maximum number of iterations ($COUNTER). Exiting..."
        break
    fi
    
    # Wait before next iteration
    local delay=$(jq -r '.retry_delay_seconds // 10' "$CONFIG")
    echo "Sleeping $delay seconds before next iteration..."
    sleep "$delay"
done

echo "Improver loop completed after $COUNTER iterations"
