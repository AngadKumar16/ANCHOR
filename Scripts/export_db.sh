#!/bin/bash

# ANCHOR Database Export Script
# This script exports the Core Data SQLite database for backup or migration purposes

set -e  # Exit on any error

# Configuration
APP_NAME="ANCHOR"
SIMULATOR_UUID=${1:-""}  # Optional simulator UUID as first argument
EXPORT_DIR="./Exports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
EXPORT_FILE="anchor_db_export_${TIMESTAMP}.sqlite"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 ANCHOR Database Export Script${NC}"
echo "=================================="

# Function to find simulator data directory
find_simulator_data() {
    local sim_data_dir="$HOME/Library/Developer/CoreSimulator/Devices"
    
    if [ -n "$SIMULATOR_UUID" ]; then
        # Use specific simulator UUID if provided
        local target_dir="$sim_data_dir/$SIMULATOR_UUID/data/Containers/Data/Application"
        if [ -d "$target_dir" ]; then
            echo "$target_dir"
        else
            echo -e "${RED}❌ Simulator with UUID $SIMULATOR_UUID not found${NC}"
            exit 1
        fi
    else
        # Find most recently modified simulator data
        find "$sim_data_dir" -name "data" -type d -path "*/Containers/Data/Application" 2>/dev/null | head -1
    fi
}

# Function to find ANCHOR app data
find_anchor_data() {
    local sim_data_dir="$1"
    
    # Look for ANCHOR app directories
    for app_dir in "$sim_data_dir"/*; do
        if [ -d "$app_dir" ]; then
            # Check for ANCHOR-specific files or Core Data store
            if find "$app_dir" -name "*.sqlite" -o -name "*ANCHOR*" -o -name "Model.sqlite" 2>/dev/null | grep -q .; then
                echo "$app_dir"
                return 0
            fi
        fi
    done
    
    echo ""
}

# Create export directory
mkdir -p "$EXPORT_DIR"

echo -e "${YELLOW}📱 Searching for ANCHOR app data...${NC}"

# Find simulator data directory
SIM_DATA_DIR=$(find_simulator_data)

if [ -z "$SIM_DATA_DIR" ]; then
    echo -e "${RED}❌ Could not find simulator data directory${NC}"
    echo "Make sure you have run ANCHOR in the iOS Simulator at least once."
    exit 1
fi

echo -e "${BLUE}📂 Simulator data directory: $SIM_DATA_DIR${NC}"

# Find ANCHOR app data
ANCHOR_DATA_DIR=$(find_anchor_data "$SIM_DATA_DIR")

if [ -z "$ANCHOR_DATA_DIR" ]; then
    echo -e "${RED}❌ Could not find ANCHOR app data${NC}"
    echo "Make sure you have run ANCHOR in the iOS Simulator and created some data."
    echo -e "${YELLOW}💡 Try running the app and creating a journal entry first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Found ANCHOR app data: $ANCHOR_DATA_DIR${NC}"

# Find Core Data SQLite files
echo -e "${YELLOW}🔍 Searching for Core Data files...${NC}"

SQLITE_FILES=$(find "$ANCHOR_DATA_DIR" -name "*.sqlite" -o -name "*.sqlite-wal" -o -name "*.sqlite-shm" 2>/dev/null)

if [ -z "$SQLITE_FILES" ]; then
    echo -e "${RED}❌ No SQLite database files found${NC}"
    echo "The app may not have created any persistent data yet."
    exit 1
fi

# Export database files
echo -e "${GREEN}📦 Exporting database files...${NC}"

EXPORT_PATH="$EXPORT_DIR/$EXPORT_FILE"
EXPORT_INFO_FILE="$EXPORT_DIR/anchor_export_info_${TIMESTAMP}.txt"

# Create export info file
cat > "$EXPORT_INFO_FILE" << EOF
ANCHOR Database Export Information
==================================
Export Date: $(date)
Export Timestamp: $TIMESTAMP
Source Directory: $ANCHOR_DATA_DIR
Simulator UUID: ${SIMULATOR_UUID:-"Auto-detected"}

Files Exported:
EOF

# Copy main SQLite file
MAIN_SQLITE=$(echo "$SQLITE_FILES" | grep "\.sqlite$" | head -1)
if [ -n "$MAIN_SQLITE" ]; then
    cp "$MAIN_SQLITE" "$EXPORT_PATH"
    echo "✅ Main database: $(basename "$MAIN_SQLITE") -> $EXPORT_FILE"
    echo "- $(basename "$MAIN_SQLITE")" >> "$EXPORT_INFO_FILE"
else
    echo -e "${RED}❌ No main SQLite file found${NC}"
    exit 1
fi

# Copy WAL and SHM files if they exist
for file in $SQLITE_FILES; do
    if [[ "$file" == *.sqlite-wal ]] || [[ "$file" == *.sqlite-shm ]]; then
        ext="${file##*.}"
        cp "$file" "$EXPORT_DIR/anchor_db_export_${TIMESTAMP}.${ext}"
        echo "✅ Support file: $(basename "$file")"
        echo "- $(basename "$file")" >> "$EXPORT_INFO_FILE"
    fi
done

# Add database statistics
echo "" >> "$EXPORT_INFO_FILE"
echo "Database Statistics:" >> "$EXPORT_INFO_FILE"
echo "===================" >> "$EXPORT_INFO_FILE"

if command -v sqlite3 >/dev/null 2>&1; then
    # Get table information
    sqlite3 "$EXPORT_PATH" ".tables" >> "$EXPORT_INFO_FILE" 2>/dev/null || echo "Could not read table information" >> "$EXPORT_INFO_FILE"
    
    # Get row counts for main tables
    echo "" >> "$EXPORT_INFO_FILE"
    echo "Estimated Row Counts:" >> "$EXPORT_INFO_FILE"
    for table in "ZJOURNALENTRYENTITY" "ZRISKASSESSMENTENTITY" "ZUSERPROFILEENTITY"; do
        count=$(sqlite3 "$EXPORT_PATH" "SELECT COUNT(*) FROM $table;" 2>/dev/null || echo "N/A")
        echo "- $table: $count" >> "$EXPORT_INFO_FILE"
    done
fi

# Final summary
echo ""
echo -e "${GREEN}🎉 Export completed successfully!${NC}"
echo "=================================="
echo -e "${BLUE}📁 Export location: $EXPORT_PATH${NC}"
echo -e "${BLUE}📄 Export info: $EXPORT_INFO_FILE${NC}"
echo -e "${BLUE}📊 File size: $(du -h "$EXPORT_PATH" | cut -f1)${NC}"
echo ""
echo -e "${YELLOW}💡 Usage tips:${NC}"
echo "- Keep this export safe as a backup of your ANCHOR data"
echo "- You can use SQLite tools to inspect the database"
echo "- The export info file contains metadata about this export"
echo ""
echo -e "${GREEN}✨ Export complete!${NC}"