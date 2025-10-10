#!/bin/bash
# ===============================================================
# Auto-Fix Script for ANCHOR - Minimal Version
# Automatically detects and fixes common Swift/Xcode issues
# ===============================================================

set -euo pipefail

# Configuration
MAX_ITERATIONS=10

# Function to fix duplicate properties in Swift files
fix_duplicate_properties() {
    local file="$1"
    local has_changes=false
    
    # Find and fix duplicate properties
    grep -n "^[[:space:]]*\(var\|let\)[[:space:]]\+[a-zA-Z0-9_]\+" "$file" | \
    sort -t: -k3 | uniq -f2 -D | while read -r dup; do
        if [[ "$dup" =~ ^([0-9]+):[[:space:]]*(var|let)[[:space:]]+([a-zA-Z0-9_]+) ]]; then
            line_num="${BASH_REMATCH[1]}"
            prop_name="${BASH_REMATCH[3]}"
            
            if [ "$has_changes" = false ]; then
                has_changes=true
            fi
            
            # Comment out the duplicate declaration
            sed -i '' "${line_num}s/^/\/\//" "$file"
        fi
    done
    
    [ "$has_changes" = true ]
}

# Function to fix deprecated trailing closure syntax
fix_trailing_closures() {
    local file="$1"
    local has_changes=false
    
    # Check if file contains deprecated syntax
    if grep -q "backward matching of the unlabeled trailing closure" "$file"; then
        # Fix single-line and multi-line trailing closures
        sed -i '' -E 's/\) \{\s*$/\}, action: {/g' "$file"
        perl -i -pe 's/\) \{\s*$/\}, action: {/g' "$file"
        has_changes=true
    fi
    
    [ "$has_changes" = true ]
}

# Main fix function
fix_all_issues() {
    local has_issues=false
    
    # Process all Swift files
    find . -name "*.swift" | while read -r file; do
        if fix_duplicate_properties "$file" || \
           fix_trailing_closures "$file"; then
            has_issues=true
        fi
    done
    
    [ "$has_issues" = true ]
}

# Run build and fix issues
run_build_and_fix() {
    local iteration=$1
    
    # Clean and build
    xcodebuild clean -workspace ANCHOR.xcworkspace -scheme ANCHOR >/dev/null 2>&1
    
    if ! xcodebuild \
        -workspace ANCHOR.xcworkspace \
        -scheme ANCHOR \
        -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
        clean build \
        >/dev/null 2>&1; then
        
        if fix_all_issues; then
            return 1  # Rebuild needed
        else
            return 2  # Fatal error
        fi
    else
        return 0  # Success
    fi
}

# Main execution
main() {
    local iteration=1
    
    while [ $iteration -le $MAX_ITERATIONS ]; do
        if run_build_and_fix "$iteration"; then
            return 0
        elif [ $? -eq 1 ]; then
            ((iteration++))
            continue
        else
            return 1
        fi
    done
    
    return 1
}

# Start the process
if ! main; then
    exit 1
fi

exit 0