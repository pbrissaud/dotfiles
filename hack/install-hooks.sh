#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

install_hook() {
    local name="$1"
    local target="$HOOKS_DIR/$name"

    cat > "$target" << EOF
#!/bin/bash
"\$(git rev-parse --show-toplevel)/hack/write-package-list.sh"
git add "\$(git rev-parse --show-toplevel)/packages.txt"
EOF
    chmod +x "$target"
    echo "✓ $name hook installed"
}

install_hook "pre-commit"
