#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

install_hook() {
    local name="$1"
    local target="$HOOKS_DIR/$name"

    cat > "$target" << 'EOF'
#!/bin/bash
set -e
ROOT="$(git rev-parse --show-toplevel)"
"$ROOT/hack/write-package-list.sh"
git add "$ROOT/Brewfile" "$ROOT/curl-installs.txt" "$ROOT/assets/.config/mise/config.toml"
EOF
    chmod +x "$target"
    echo "✓ $name hook installed"
}

install_hook "pre-commit"
