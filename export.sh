#!/bin/bash

# Export config files from home to the repo
# Inverse of install.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/assets"
HOME_DIR="$HOME"
SYNC_MODE="export"

# Load common functions
source "$SCRIPT_DIR/lib/common.sh"

echo -e "${BLUE}📤 Exporting config files${NC}"
echo "========================================="

if [ ! -d "$ASSETS_DIR" ]; then
    echo -e "${YELLOW}⚠️  Directory $ASSETS_DIR not found${NC}"
    exit 1
fi

RESULTS_FILE=$(mktemp)
trap "rm -f $RESULTS_FILE" EXIT

# Iterate through all files in assets to find their equivalents in home
_files_list=$(mktemp)
trap "rm -f $_files_list" RETURN
find "$ASSETS_DIR" -type f | sort > "$_files_list"

while IFS= read -r file <&3; do
    [ -z "$file" ] && continue

    # Get relative path from assets
    relative_path="${file#$ASSETS_DIR/}"

    # Source file in home
    source_file="$HOME_DIR/$relative_path"

    # Destination file in repo
    dest_file="$file"

    copy_with_conflict_handling "$source_file" "$dest_file" "$SCRIPT_DIR/.backup" "$RESULTS_FILE" "repo → home" "Override file (not exported)"
done 3< "$_files_list"

count_results "$RESULTS_FILE"
print_summary "Export complete"

# Ask to commit and push if there are changes
if [ $COPIED -gt 0 ] || [ $BACKED_UP -gt 0 ]; then
    cd "$SCRIPT_DIR"
    
    echo ""
    echo -e "${BLUE}📝 Changes detected in repo${NC}"
    git status --short
    
    echo ""
    printf "Commit and push changes? [y]es, [n]o: "
    read -n 1 -r choice < /dev/tty
    echo
    
    if [[ $choice =~ ^[Yy]$ ]]; then
        git add -A
        printf "Commit message (default: 'Update dotfiles'): "
        read -r msg < /dev/tty
        msg="${msg:-Update dotfiles}"
        git commit -m "$msg"
        
        printf "Push to remote? [y]es, [n]o: "
        read -n 1 -r push_choice < /dev/tty
        echo
        
        if [[ $push_choice =~ ^[Yy]$ ]]; then
            git push
            echo -e "${GREEN}✓ Changes pushed${NC}"
        else
            echo -e "${YELLOW}Changes committed locally (not pushed)${NC}"
        fi
    fi
fi