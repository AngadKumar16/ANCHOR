#!/bin/bash
# ===============================================================
# Auto-Fix Script for ANCHOR
# Automatically detects and fixes common Swift/Xcode issues
# ===============================================================

set -euo pipefail

# Configuration
LOG_DIR="Tools/logs/auto_fix"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/auto_fix_${TIMESTAMP}.log"
MAX_ITERATIONS=10

# Ensure log directory exists
mkdir -p "$LOG_DIR"

echo "🚀 Starting automated code fixer" | tee "$LOG_FILE"

# Function to fix duplicate properties in Swift files
fix_duplicate_properties() {
    local file="$1"
    local log_file="$2"
    local has_changes=false
    
    # Create backup
    cp "$file" "${file}.bak.${TIMESTAMP}"
    
    # Find and fix duplicate properties
    grep -n "^[[:space:]]*\(var\|let\)[[:space:]]\+[a-zA-Z0-9_]\+" "$file" | \
    sort -t: -k3 | uniq -f2 -D | while read -r dup; do
        if [[ "$dup" =~ ^([0-9]+):[[:space:]]*(var|let)[[:space:]]+([a-zA-Z0-9_]+) ]]; then
            line_num="${BASH_REMATCH[1]}"
            prop_name="${BASH_REMATCH[3]}"
            
            if [ "$has_changes" = false ]; then
                echo "  🔧 Fixing issues in $file" | tee -a "$log_file"
                has_changes=true
            fi
            
            echo "    ➖ Commenting out duplicate property: $prop_name at line $line_num" | tee -a "$log_file"
            sed -i '' "${line_num}s/^/\/\//" "$file"
        fi
    done
    
    [ "$has_changes" = true ]
}

# Function to fix deprecated trailing closure syntax
fix_trailing_closures() {
    local file="$1"
    local log_file="$2"
    local has_changes=false
    
    # Check if file contains deprecated syntax
    if grep -q "backward matching of the unlabeled trailing closure" "$log_file"; then
        echo "  🔄 Fixing trailing closures in $file" | tee -a "$log_file"
        cp "$file" "${file}.bak.${TIMESTAMP}"
        
        # Fix single-line trailing closures
        sed -i '' -E 's/\) \{\s*$/\), action: {/g' "$file"
        
        # Fix multi-line trailing closures
        perl -i -pe 's/\) \{\s*$/\), action: {/g' "$file"
        
        has_changes=true
    fi
    
    [ "$has_changes" = true ]
}

# Main fix function
fix_all_issues() {
    local log_file="$1"
    local has_issues=false
    
    echo "🔍 Scanning for issues in Swift files..." | tee -a "$log_file"
    
    # Process all Swift files
    find . -name "*.swift" | while read -r file; do
        if fix_duplicate_properties "$file" "$log_file" || \
           fix_trailing_closures "$file" "$log_file"; then
            has_issues=true
        fi
    done
    
    [ "$has_issues" = true ]
}

# Run build and fix issues
run_build_and_fix() {
    local iteration=$1
    local log_file="$2"
    
    echo "\n🔄 Iteration $iteration/$MAX_ITERATIONS - $(date)" | tee -a "$log_file"
    echo "==================================================" | tee -a "$log_file"
    
    # Clean build
    echo "🧹 Cleaning build artifacts..." | tee -a "$log_file"
    xcodebuild clean -workspace ANCHOR.xcworkspace -scheme ANCHOR | tee -a "$log_file"
    
    # Run build
    echo "🏗️  Building project..." | tee -a "$log_file"
    if ! xcodebuild \
        -workspace ANCHOR.xcworkspace \
        -scheme ANCHOR \
        -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
        clean build \
        2>&1 | tee -a "$log_file"; then
        
        echo "⚠️  Build failed, attempting to fix issues..." | tee -a "$log_file"
        
        if fix_all_issues "$log_file"; then
            echo "✅ Applied automatic fixes, will rebuild..." | tee -a "$log_file"
            return 1  # Indicate rebuild needed
        else
            echo "❌ Could not automatically fix all issues" | tee -a "$log_file"
            return 2  # Indicate fatal error
        fi
    else
        echo "✅ Build successful!" | tee -a "$log_file"
        return 0  # Indicate success
    fi
}

# Main execution
main() {
    local iteration=1
    
    while [ $iteration -le $MAX_ITERATIONS ]; do
        if run_build_and_fix "$iteration" "$LOG_FILE"; then
            echo "\n🎉 Success! All issues fixed and project builds successfully." | tee -a "$LOG_FILE"
            return 0
        elif [ $? -eq 1 ]; then
            # Rebuild needed after fixes
            ((iteration++))
            continue
        else
            # Fatal error
            echo "\n❌ Failed to fix all issues after $iteration iterations" | tee -a "$LOG_FILE"
            return 1
        fi
    done
    
    echo "\n⚠️  Reached maximum number of iterations ($MAX_ITERATIONS)" | tee -a "$LOG_FILE"
    return 1
}

# Start the process
if ! main; then
    echo "\n❌ Auto-fix completed with issues. Check $LOG_FILE for details." >&2
    exit 1
fi

echo "\n✅ Auto-fix completed successfully!" | tee -a "$LOG_FILE"
exit 0