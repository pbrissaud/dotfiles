#!/bin/bash

# Install all packages listed in packages.txt
# and copy config files from assets folder to home

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_FILE="$SCRIPT_DIR/packages.txt"
ASSETS_DIR="$SCRIPT_DIR/assets"
HOME_DIR="$HOME"

# Load common functions
source "$SCRIPT_DIR/lib/common.sh"

# ============================================================================
# SECTION 1: Package installation
# ============================================================================

echo -e "${BLUE}📦 Installing packages${NC}"
echo "=================================="

# Check that packages.txt exists
if [ ! -f "$PACKAGES_FILE" ]; then
    echo -e "${RED}❌ File $PACKAGES_FILE not found${NC}"
    exit 1
fi

# Check that brew is installed
if ! command -v brew &> /dev/null; then
    echo -e "${RED}❌ Homebrew is not installed${NC}"
    exit 1
fi

# Read packages from file and install them
packages=$(grep -v '^$' "$PACKAGES_FILE" | tr '\n' ' ')

if [ -z "$packages" ]; then
    echo -e "${YELLOW}⚠️  No packages to install${NC}"
else
    echo "Installing: $packages"
    brew install $packages
    echo -e "${GREEN}✓ Packages installed${NC}"
fi

# ============================================================================
# SECTION 2: Config files copy
# ============================================================================

echo ""
echo -e "${BLUE}📋 Copying config files${NC}"
echo "========================================="

if [ ! -d "$ASSETS_DIR" ]; then
    echo -e "${YELLOW}⚠️  Directory $ASSETS_DIR not found${NC}"
    exit 0
fi

RESULTS_FILE=$(mktemp)
trap "rm -f $RESULTS_FILE" EXIT

# Iterate through all files in assets folder
_files_list=$(mktemp)
trap "rm -f $_files_list" RETURN
find "$ASSETS_DIR" -type f | sort > "$_files_list"

while IFS= read -r file <&3; do
    [ -z "$file" ] && continue

    # Get relative path from assets
    relative_path="${file#$ASSETS_DIR/}"

    # Determine destination (in home)
    destination="$HOME_DIR/$relative_path"

    copy_with_conflict_handling "$file" "$destination" "$HOME_DIR/.dotfiles_backup" "$RESULTS_FILE" "existing → new" "Override file (kept)"
done 3< "$_files_list"

count_results "$RESULTS_FILE"
print_summary "Installation complete"

# ============================================================================
# SECTION 3: Reload zsh configuration
# ============================================================================

echo ""
echo -e "${BLUE}🔄 Reloading zsh configuration${NC}"
echo "=========================================="

if [ -f "$HOME/.zshrc" ]; then
    echo -e "${GREEN}✓ Running: source \$HOME/.zshrc${NC}"
    # Note: source in a bash script doesn't persist in the parent shell.
    # We use exec to replace the current process with a new zsh shell.
    exec zsh -l
else
    echo -e "${YELLOW}⚠️  File ~/.zshrc not found, skipping reload${NC}"
fi
