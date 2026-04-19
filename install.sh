#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BREWFILE="$SCRIPT_DIR/Brewfile"
CURL_TXT="$SCRIPT_DIR/curl-installs.txt"
ASSETS_DIR="$SCRIPT_DIR/assets"
HOME_DIR="$HOME"
SYNC_MODE="install"

# Parse flags
YES_MODE=0
SYNC_SYMLINK=0
for arg in "$@"; do
    case "$arg" in
        --yes|-y)     YES_MODE=1 ;;
        --symlink|-s) SYNC_SYMLINK=1 ;;
    esac
done
export YES_MODE SYNC_SYMLINK

source "$SCRIPT_DIR/lib/common.sh"

# ============================================================================
# SECTION 0: Git hooks
# ============================================================================

echo -e "${BLUE}🪝 Installing git hooks${NC}"
echo "=================================="
"$SCRIPT_DIR/hack/install-hooks.sh"
echo ""

# ============================================================================
# SECTION 1: Homebrew
# ============================================================================

echo -e "${BLUE}📦 Installing packages${NC}"
echo "=================================="

if ! xcode-select -p &>/dev/null; then
    echo -e "${YELLOW}⚠ Xcode Command Line Tools not found, installing...${NC}"
    xcode-select --install
    echo -e "${YELLOW}  Re-run this script after the Xcode CLT installation completes.${NC}"
    exit 1
fi

if ! command -v brew &>/dev/null; then
    echo -e "${YELLOW}⚠ Homebrew not found, installing...${NC}"
    BREW_PKG=$(mktemp -t homebrew).pkg
    curl -fsSL "https://github.com/Homebrew/brew/releases/latest/download/Homebrew.pkg" -o "$BREW_PKG"
    sudo installer -pkg "$BREW_PKG" -target /
    rm -f "$BREW_PKG"
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    if ! command -v brew &>/dev/null; then
        echo -e "${RED}❌ Homebrew installation failed${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Homebrew installed${NC}"
fi

if [ ! -f "$BREWFILE" ]; then
    echo -e "${RED}❌ Brewfile not found — run hack/write-package-list.sh first${NC}"
    exit 1
fi

brew bundle --file="$BREWFILE"
echo -e "${GREEN}✓ Brew packages up to date${NC}"

# ============================================================================
# SECTION 2: curl | bash installers
# ============================================================================

if [ -f "$CURL_TXT" ] && [ -s "$CURL_TXT" ]; then
    echo ""
    echo -e "${BLUE}🌐 curl installers${NC}"
    echo "=================================="
    while IFS= read -r entry; do
        [ -z "$entry" ] && continue
        bin="${entry%%:*}"
        url="${entry#*:}"
        if command -v "$bin" &>/dev/null; then
            echo -e "${GREEN}  ✓ Already installed: $bin${NC}"
        else
            echo -e "${YELLOW}  ⚠ Installing $bin from $url${NC}"
            curl -fsSL "$url" | bash
            echo -e "${GREEN}  ✓ Installed: $bin${NC}"
        fi
    done < "$CURL_TXT"
fi

# ============================================================================
# SECTION 3: Config files
# ============================================================================

echo ""
if [ "${SYNC_SYMLINK}" = "1" ]; then
    echo -e "${BLUE}🔗 Linking config files${NC}"
else
    echo -e "${BLUE}📋 Copying config files${NC}"
fi
echo "========================================="

if [ ! -d "$ASSETS_DIR" ]; then
    echo -e "${YELLOW}⚠️  Directory $ASSETS_DIR not found${NC}"
    exit 0
fi

RESULTS_FILE=$(mktemp)
FILES_LIST=$(mktemp)
trap "rm -f $RESULTS_FILE $FILES_LIST" EXIT

find "$ASSETS_DIR" -type f | sort > "$FILES_LIST"

while IFS= read -r file <&3; do
    [ -z "$file" ] && continue
    relative_path="${file#$ASSETS_DIR/}"
    destination="$HOME_DIR/$relative_path"
    copy_with_conflict_handling "$file" "$destination" "$HOME_DIR/.dotfiles_backup" "$RESULTS_FILE" "existing → new" "Override file (kept)"
done 3< "$FILES_LIST"

count_results "$RESULTS_FILE"
print_summary "Installation complete"

# ============================================================================
# SECTION 4: mise install (if mise is available)
# ============================================================================

if command -v mise &>/dev/null; then
    echo ""
    echo -e "${BLUE}🔧 Installing mise tools${NC}"
    echo "=================================="
    mise install
    echo -e "${GREEN}✓ mise tools up to date${NC}"
fi

# ============================================================================
# SECTION 5: Reload zsh
# ============================================================================

echo ""
echo -e "${BLUE}🔄 Reloading zsh configuration${NC}"
echo "=========================================="

if [ -f "$HOME/.zshrc" ] && [ -t 1 ]; then
    echo -e "${GREEN}✓ Running: exec zsh -l${NC}"
    exec zsh -l
elif [ -f "$HOME/.zshrc" ]; then
    echo -e "${YELLOW}⚠️  Non-interactive shell — run 'exec zsh -l' manually to reload${NC}"
else
    echo -e "${YELLOW}⚠️  File ~/.zshrc not found, skipping reload${NC}"
fi
