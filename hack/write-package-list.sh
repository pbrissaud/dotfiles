#!/bin/bash

# Script pour extraire les noms de packages depuis les commentaires # pkg:
# et écrire la liste dans packages.txt

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PACKAGES_FILE="$PROJECT_ROOT/packages.txt"

# Créer un fichier temporaire
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

# Rechercher tous les commentaires # pkg: dans l'arborescence
# en excluant .git, node_modules et hack (pour éviter les meta-comments)
grep -rh "# pkg:" "$PROJECT_ROOT" \
    --exclude-dir=.git \
    --exclude-dir=node_modules \
    --exclude-dir=.vscode \
    --exclude-dir=hack \
    --exclude="*.swp" \
    --exclude="*.swo" \
    2>/dev/null | while read -r line; do
    # Extraire la partie après "# pkg:"
    rest="${line##*# pkg:}"
    
    # Traiter les packages séparés par des virgules
    IFS=',' read -ra packages <<< "$rest"
    for pkg in "${packages[@]}"; do
        # Nettoyer les espaces avant et après
        pkg=$(printf '%s' "$pkg" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [ -n "$pkg" ]; then
            echo "$pkg"
        fi
    done
done | sort -u > "$TEMP_FILE"

# Écrire le fichier final
mv "$TEMP_FILE" "$PACKAGES_FILE"

echo "✓ packages.txt généré avec $(wc -l < "$PACKAGES_FILE") packages"
