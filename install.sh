#!/bin/bash

# Script pour installer tous les packages listés dans packages.txt

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_FILE="$SCRIPT_DIR/packages.txt"

# Vérifier que packages.txt existe
if [ ! -f "$PACKAGES_FILE" ]; then
    echo "❌ Le fichier $PACKAGES_FILE n'existe pas"
    exit 1
fi

# Vérifier que brew est installé
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew n'est pas installé"
    exit 1
fi

# Lire les packages depuis le fichier et les installer
packages=$(grep -v '^$' "$PACKAGES_FILE" | tr '\n' ' ')

if [ -z "$packages" ]; then
    echo "⚠️  Aucun package à installer"
    exit 0
fi

echo "📦 Installation des packages: $packages"
brew install $packages

echo "✓ Installation complétée"
