# Common functions for install.sh and export.sh

# Colors for display
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Files that should never be synced automatically
NEVER_SYNC_FILES=(".zsh_override.zsh")

# Calculate file hash
get_file_hash() {
    shasum -a 256 "$1" 2>/dev/null | cut -d' ' -f1
}

# Display difference between two files
show_diff() {
    local src="$1"
    local dst="$2"
    local label="${3:-existing → new}"
    echo -e "${BLUE}  --- Differences ($label) ---${NC}"
    diff --color=auto -u "$dst" "$src" 2>/dev/null || diff -u "$dst" "$src"
    echo -e "${BLUE}  $(printf '%*s' ${#label} '' | tr ' ' '-')---------------------${NC}"
}

# Check if a file is in the never-sync list
is_never_sync() {
    local filename="$1"
    for f in "${NEVER_SYNC_FILES[@]}"; do
        if [ "$filename" = "$f" ]; then
            return 0
        fi
    done
    return 1
}

# Ask user which action to perform
# Returns: s=skip, b=backup, r=replace
ask_action() {
    local filename="$1"
    read -p "  Action? [s]kip, [b]ackup+replace, [r]eplace: " -n 1 -r choice
    echo
    case $choice in
        b|B) echo "b" ;;
        r|R) echo "r" ;;
        *)   echo "s" ;;
    esac
}

# Copy a file with conflict handling
# Arguments:
#   $1 - source file
#   $2 - destination file
#   $3 - backup directory
#   $4 - results file
#   $5 - diff label (optional)
#   $6 - never_sync message (optional)
copy_with_conflict_handling() {
    local src="$1"
    local dst="$2"
    local backup_dir="$3"
    local results_file="$4"
    local diff_label="${5:-existing → new}"
    local never_sync_msg="${6:-Override file (skipped)}"
    local filename=$(basename "$src")

    # File should never be synced
    if is_never_sync "$filename"; then
        if [ -f "$dst" ]; then
            echo -e "${BLUE}  ⊘ $never_sync_msg: $filename${NC}"
            echo "SKIPPED" >> "$results_file"
            return 0
        fi
    fi

    # Check that source file exists
    if [ ! -f "$src" ]; then
        echo -e "${YELLOW}  ⚠ Source file not found: $filename${NC}"
        echo "MISSING" >> "$results_file"
        return 1
    fi

    # Create destination directory if it doesn't exist
    local dst_dir=$(dirname "$dst")
    mkdir -p "$dst_dir" 2>/dev/null || {
        echo -e "${RED}  ❌ Cannot create directory: $dst_dir${NC}"
        echo "ERROR" >> "$results_file"
        return 1
    }

    if [ -f "$dst" ]; then
        # File exists - check if identical
        local src_hash=$(get_file_hash "$src")
        local dst_hash=$(get_file_hash "$dst")

        if [ "$src_hash" = "$dst_hash" ]; then
            echo -e "${GREEN}  ✓ Identical file (skipped): $filename${NC}"
            echo "IDENTICAL" >> "$results_file"
            return 0
        fi

        # Files differ - show diff
        echo -e "${YELLOW}  ⚠ File differs: $filename${NC}"
        show_diff "$src" "$dst" "$diff_label"

        local action=$(ask_action "$filename")

        case $action in
            b)
                mkdir -p "$backup_dir"
                local timestamp=$(date +%Y%m%d_%H%M%S)
                local backup_file="$backup_dir/${filename}_${timestamp}.bak"
                cp "$dst" "$backup_file"
                if cp "$src" "$dst" 2>/dev/null; then
                    echo -e "${YELLOW}  💾 Backup created: $backup_file${NC}"
                    echo -e "${GREEN}  ✓ File copied: $filename${NC}"
                    echo "BACKED_UP" >> "$results_file"
                else
                    echo -e "${RED}  ❌ Copy error: $filename${NC}"
                    echo "ERROR" >> "$results_file"
                fi
                ;;
            r)
                if cp "$src" "$dst" 2>/dev/null; then
                    echo -e "${GREEN}  ✓ File copied: $filename${NC}"
                    echo "COPIED" >> "$results_file"
                else
                    echo -e "${RED}  ❌ Copy error: $filename${NC}"
                    echo "ERROR" >> "$results_file"
                fi
                ;;
            *)
                echo -e "${YELLOW}  ⊘ File skipped: $filename${NC}"
                echo "SKIPPED" >> "$results_file"
                ;;
        esac
    else
        # File doesn't exist, copy it
        if cp "$src" "$dst" 2>/dev/null; then
            echo -e "${GREEN}  ✓ File copied: $filename${NC}"
            echo "COPIED" >> "$results_file"
        else
            echo -e "${RED}  ❌ Copy error: $filename${NC}"
            echo "ERROR" >> "$results_file"
        fi
    fi
}

# Count results from temporary file
# Sets variables: COPIED, BACKED_UP, SKIPPED, IDENTICAL, ERROR, MISSING
count_results() {
    local results_file="$1"
    COPIED=0
    BACKED_UP=0
    SKIPPED=0
    IDENTICAL=0
    ERROR=0
    MISSING=0

    if [ -f "$results_file" ]; then
        while IFS= read -r action; do
            case $action in
                COPIED) ((COPIED++)) ;;
                BACKED_UP) ((BACKED_UP++)) ;;
                SKIPPED) ((SKIPPED++)) ;;
                IDENTICAL) ((IDENTICAL++)) ;;
                ERROR) ((ERROR++)) ;;
                MISSING) ((MISSING++)) ;;
            esac
        done < "$results_file"
    fi
}

# Print operation summary
print_summary() {
    local title="$1"
    echo ""
    echo -e "${GREEN}✓ $title${NC}"
    echo "  - Files copied: $COPIED"
    echo "  - Files backed up and replaced: $BACKED_UP"
    echo "  - Identical files (skipped): $IDENTICAL"
    echo "  - Files skipped: $SKIPPED"
    if [ $MISSING -gt 0 ]; then
        echo -e "  - ${YELLOW}Missing files: $MISSING${NC}"
    fi
    if [ $ERROR -gt 0 ]; then
        echo -e "  - ${RED}Errors: $ERROR${NC}"
    fi
}
