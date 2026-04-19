#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/assets"
HOME_DIR="$HOME"
SYNC_MODE="export"
SYNC_SYMLINK=0
export SYNC_SYMLINK

source "$SCRIPT_DIR/lib/common.sh"

echo -e "${BLUE}📤 Exporting config files${NC}"
echo "========================================="

if [ ! -d "$ASSETS_DIR" ]; then
    echo -e "${YELLOW}⚠️  Directory $ASSETS_DIR not found${NC}"
    exit 1
fi

RESULTS_FILE=$(mktemp)
FILES_LIST=$(mktemp)
trap "rm -f $RESULTS_FILE $FILES_LIST" EXIT

find "$ASSETS_DIR" -type f | sort > "$FILES_LIST"

while IFS= read -r file <&3; do
    [ -z "$file" ] && continue
    relative_path="${file#$ASSETS_DIR/}"
    source_file="$HOME_DIR/$relative_path"
    dest_file="$file"
    copy_with_conflict_handling "$source_file" "$dest_file" "$SCRIPT_DIR/.backup" "$RESULTS_FILE" "repo → home" "Override file (not exported)"
done 3< "$FILES_LIST"

count_results "$RESULTS_FILE"
print_summary "Export complete"

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
        git add assets/ Brewfile curl-installs.txt
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
