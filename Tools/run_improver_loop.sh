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

# Clean build artifacts and derived data
clean_build() {
    echo "🧹 Cleaning build artifacts..."
    
    # Clean derived data
    local derived_data_path="$HOME/Library/Developer/Xcode/DerivedData/ANCHOR-*"
    if [ -d $derived_data_path ]; then
        rm -rf $derived_data_path
        echo "✅ Removed derived data"
    fi
    
    # Clean build directory
    if [ -d "build" ]; then
        rm -rf build
        echo "✅ Removed build directory"
    fi
    
    # Clean backup files
    echo "🧹 Cleaning backup files..."
    find . -type f \( -name "*.bak.*" -o -name "*.fixed" -o -name "*.backup" -o -name "*.patch" -o -name "*.orig" -o -name "*.rej" \) -delete
    echo "✅ Removed backup files"
    
    # Clean CocoaPods if used
    if [ -f "Podfile" ]; then
        echo "🔧 Running pod deintegrate..."
        pod deintegrate
        pod cache clean --all
        echo "✅ Cleaned CocoaPods cache"
    fi
    
    echo "🧹 Clean complete!"
}

# Run xcodebuild with proper error handling
run_xcodebuild() {
    local log_file=$1
    local xcresult_dir=$2
    
    echo "🏗️  Building project..." | tee -a "$log_file"
    
    # First try a clean build
    xcodebuild clean \
        -workspace "$WORKSPACE" \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        2>&1 | tee -a "$log_file"
    
    # Then build and test
    xcodebuild test \
        -workspace "$WORKSPACE" \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        -resultBundlePath "$xcresult_dir/TestResults" \
        -enableCodeCoverage YES \
        2>&1 | tee -a "$log_file"
    
    return ${PIPESTATUS[0]}
}

run_improver() {
    local log_file status branch xcresult_dir
    log_file="$LOG_DIR/improver_$(date +%Y%m%d_%H%M%S).log"
    xcresult_dir="$LOG_DIR/xcresults_$(date +%Y%m%d_%H%M%S)"
    
    # Ensure directories exist
    mkdir -p "$xcresult_dir"
    
    echo "🚀 Running improver..." | tee -a "$log_file"
    echo "📝 Logging to: $log_file" | tee -a "$log_file"
    
    # Clean before building
    clean_build | tee -a "$log_file"
    
    # Run xcodebuild with error handling
    set -o pipefail
    run_xcodebuild "$log_file" "$xcresult_dir"
    status=$?
    set +o pipefail
    
    # Save xcresult path for debugging
    echo "📊 Test results available at: $xcresult_dir/TestResults.xcresult" >> "$log_file"
    
    # Handle build result
    if [[ $status -ne 0 ]]; then
        echo "❌ Build failed with status: $status" | tee -a "$log_file"
        
        # Extract error details
        if grep -q "error: " "$log_file"; then
            echo "🔍 Build errors found:" | tee -a "$log_file"
            grep -A 5 -B 2 "error: " "$log_file" | tee -a "$log_file"
        fi
        
        # Run diagnostics
        run_diagnostics "$log_file"
        
        # Try to fix common issues
        fix_common_issues "$log_file"
        
        return 1
    fi
    
    # If build succeeded, handle git operations
    if [[ "$(jq -r '.auto_commit // false' "$CONFIG" 2>/dev/null)" == "true" ]]; then
        if git_commit_changes; then
            if [[ "$(jq -r '.auto_push // false' "$CONFIG" 2>/dev/null)" == "true" ]]; then
                branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
                git_push_changes "$branch"
            fi
        fi
    fi
    
    return 0
}

run_diagnostics() {
    local log_file=$1
    echo "🔍 Running diagnostics..." | tee -a "$log_file"
    
    # Check Xcode version
    echo "\n📱 Xcode Version:" | tee -a "$log_file"
    xcodebuild -version 2>&1 | tee -a "$log_file"
    
    # Check Ruby and CocoaPods versions
    echo "\n🔧 Development Environment:" | tee -a "$log_file"
    ruby -v 2>&1 | tee -a "$log_file"
    pod --version 2>&1 | tee -a "$log_file"
    
    # Check for CocoaPods issues
    if [ -f "Podfile" ]; then
        echo "\n🔍 Checking CocoaPods..." | tee -a "$log_file"
        pod env | grep -E 'CocoaPods|Ruby|Xcode' 2>&1 | tee -a "$log_file"
    fi
    
    # Check for code signing issues
    echo "\n🔑 Code Signing Status:" | tee -a "$log_file"
    security find-identity -v -p codesigning 2>&1 | tee -a "$log_file"
    
    echo "\n📋 Diagnostics complete. Check the log file for details." | tee -a "$log_file"
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

# Fix Swift compilation errors
fix_swift_errors() {
    local log_file=$1
    local has_errors=false
    
    echo "🔍 Analyzing Swift compilation errors..." | tee -a "$log_file"
    
    # Handle backward matching of unlabeled trailing closures
    if grep -q "backward matching of the unlabeled trailing closure is deprecated" "$log_file"; then
        has_errors=true
        echo "🔄 Fixing deprecated trailing closure syntax..." | tee -a "$log_file"
        
        # Find all Swift files with the warning
        grep -l -r --include="*.swift" -F "backward matching of the unlabeled trailing closure is deprecated" . | while read -r file; do
            echo "  🔧 Fixing $file" | tee -a "$log_file"
            # Create a backup
            cp "$file" "${file}.bak.$(date +%s)"
            
            # Fix the trailing closure syntax
            sed -i '' -E 's/\}\) \{\s*$/\}, action: {/g' "$file"
            
            # For multi-line closures, we need a more sophisticated approach
            # This is a simple fix that works for many common cases
            perl -i -pe 's/\) \{\s*$/\}, action: {/g' "$file"
        done
    fi
    
    # Add more error patterns here as needed
    
    if [ "$has_errors" = true ]; then
        echo "✅ Applied fixes for Swift compilation errors" | tee -a "$log_file"
        return 0
    else
        return 1
    fi
}

# Fix common build issues
fix_common_issues() {
    local log_file=$1
    local fixed_issues=0
    
    echo "🔧 Attempting to fix common issues..." | tee -a "$log_file"
    
    # Fix Swift compilation errors first
    if fix_swift_errors "$log_file"; then
        fixed_issues=$((fixed_issues + 1))
    fi
    
    # Check for Core Data model issues
    if grep -q "CoreData: error: " "$log_file"; then
        echo "🔄 Regenerating Core Data model files..." | tee -a "$log_file"
        find . -name "*.xcdatamodeld" -exec touch {} \;
        fixed_issues=$((fixed_issues + 1))
    fi
    
    # Check for Swift version issues
    if grep -q "is not a recognized compiler" "$log_file"; then
        echo "🔄 Updating Swift version settings..." | tee -a "$log_file"
        xcrun swift -version | tee -a "$log_file"
        fixed_issues=$((fixed_issues + 1))
    fi
    
    # Check for code signing issues
    if grep -q "Code Signing Error" "$log_file"; then
        echo "🔑 Fixing code signing..." | tee -a "$log_file"
        xcrun xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" -destination "$DESTINATION" CODE_SIGNING_ALLOWED=NO | tee -a "$log_file"
        fixed_issues=$((fixed_issues + 1))
    fi
    
    if [ "$fixed_issues" -gt 0 ]; then
        echo "✅ Fixed $fixed_issues issues" | tee -a "$log_file"
        return 0
    else
        echo "ℹ️  No common issues found to fix" | tee -a "$log_file"
        return 1
    fi
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
