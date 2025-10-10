#!/bin/bash
# ===============================================================
# Iterative improver + backend recovery loop for ANCHOR app
# ===============================================================

set -euo pipefail

# Configuration
readonly CONFIG="Tools/.improver_config.json"
readonly WORKSPACE="./ANCHOR.xcodeproj/project.xcworkspace"
readonly SCHEME="ANCHOR"
readonly DESTINATION="platform=iOS Simulator,name=iPhone 16,OS=18.4"
readonly LOG_DIR="Tools/logs"
readonly BACKEND_DIR="backend"

# Initialize counters and state
COUNTER=0
ITERATIONS_BEFORE_RUN=5

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Git functions
git_commit_changes() {
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    if ! git diff --quiet || ! git diff --cached --quiet; then
        git add .
        git commit -m "Improver: Auto-commit changes at $timestamp"
        return 0
    fi
    return 1
}

git_push_changes() {
    local branch=$1
    local max_retries=3
    local attempt=0
    
    while [ $attempt -lt $max_retries ]; do
        echo "Pushing changes to origin/$branch... (Attempt $((attempt + 1))/$max_retries)"
        
        if git push origin "$branch"; then
            echo "✅ Successfully pushed changes to origin/$branch"
            return 0
        fi
        
        echo "⚠️  Push failed. Attempting to pull and rebase..."
        if ! git pull --rebase origin "$branch"; then
            echo "❌ Failed to rebase. Please resolve conflicts manually."
            return 1
        fi
        
        attempt=$((attempt + 1))
        if [ $attempt -lt $max_retries ]; then
            echo "Retrying in 5 seconds..."
            sleep 5
        fi
    done
    
    echo "❌ Failed to push changes after $max_retries attempts"
    return 1
}

run_improver() {
    local log_file status branch
    log_file="$LOG_DIR/improver_$(date +%Y%m%d_%H%M%S).log"
    
    echo "🚀 Running improver..."
    python3 Tools/improver_loop.py --config "$CONFIG" 2>&1 | tee "$log_file"
    status=${PIPESTATUS[0]}
    
    # Check for changes and commit/push if needed
    if [[ $status -eq 0 ]]; then
        if [[ "$(jq -r '.auto_commit // false' "$CONFIG" 2>/dev/null)" == "true" ]]; then
            if git_commit_changes; then
                if [[ "$(jq -r '.auto_push // false' "$CONFIG" 2>/dev/null)" == "true" ]]; then
                    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
                    git_push_changes "$branch"
                fi
            fi
        fi
    fi
    
    return $status
}

run_backend_fix() {
    echo "🔧 Running backend repair mode..."
    python3 Tools/improver_loop.py --config "$CONFIG" --path "$BACKEND_DIR" --focus backend
}

check_backend_errors() {
    local log_file=$1
    echo "🔍 Checking for backend-related errors in $log_file..."
    
    if [ ! -f "$log_file" ]; then
        echo "⚠️  Log file not found: $log_file"
        return 0
    fi
    
    if grep -q -E "connection refused|backend unavailable|Network error|failed to fetch" "$log_file"; then
        echo "⚠️  Backend seems offline or missing API routes."
        run_backend_fix
        return 1
    fi
    return 0
}

# Main loop
main() {
    local status delay max_iterations
    
    max_iterations=$(jq -r '.max_iterations // 50' "$CONFIG" 2>/dev/null || echo "50")
    
    while true; do
        echo "\n$(date) - Iteration $((COUNTER + 1))/$max_iterations"
        echo "=================================================="

        run_improver
        status=$?
        
        if [[ $status -ne 0 ]]; then
            echo "❌ Improver exited with code $status. Checking for backend issues..."
            check_backend_errors "$LOG_DIR/improver_$(date +%Y%m%d_%H%M%S).log" || true
        fi

        COUNTER=$((COUNTER + 1))
        
        if [[ $COUNTER -ge max_iterations ]]; then
            echo "✅ Reached maximum number of iterations ($COUNTER). Exiting..."
            break
        fi
        
        delay=$(jq -r '.retry_delay_seconds // 10' "$CONFIG" 2>/dev/null || echo "10")
        echo "⏳ Sleeping $delay seconds before next iteration..."
        sleep "$delay"
    done

    echo "🎉 Improver loop completed after $COUNTER iterations"
}

# Start the main loop
main "$@"
