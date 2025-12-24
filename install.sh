#!/bin/bash

# Script pour installer tous les packages listés dans packages.txt
# et copier les fichiers de configuration du dossier assets vers le home

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_FILE="$SCRIPT_DIR/packages.txt"
ASSETS_DIR="$SCRIPT_DIR/assets"
HOME_DIR="$HOME"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# SECTION 1: Installation des packages
# ============================================================================

echo -e "${BLUE}📦 Installation des packages${NC}"
echo "=================================="

# Vérifier que packages.txt existe
if [ ! -f "$PACKAGES_FILE" ]; then
    echo -e "${RED}❌ Le fichier $PACKAGES_FILE n'existe pas${NC}"
    exit 1
fi

# Vérifier que brew est installé
if ! command -v brew &> /dev/null; then
    echo -e "${RED}❌ Homebrew n'est pas installé${NC}"
    exit 1
fi

# Lire les packages depuis le fichier et les installer
packages=$(grep -v '^$' "$PACKAGES_FILE" | tr '\n' ' ')

if [ -z "$packages" ]; then
    echo -e "${YELLOW}⚠️  Aucun package à installer${NC}"
else
    echo "Installation de: $packages"
    brew install $packages
    echo -e "${GREEN}✓ Packages installés${NC}"
fi

# ============================================================================
# SECTION 2: Copie des fichiers de configuration
# ============================================================================

echo ""
echo -e "${BLUE}📋 Copie des fichiers de configuration${NC}"
echo "========================================="

if [ ! -d "$ASSETS_DIR" ]; then
    echo -e "${YELLOW}⚠️  Le dossier $ASSETS_DIR n'existe pas${NC}"
    exit 0
fi

# Compteurs
COPIED=0
BACKED_UP=0
SKIPPED=0
RESULTS_FILE=$(mktemp)
trap "rm -f $RESULTS_FILE" EXIT

# Fonction pour copier un fichier avec backup
copy_file_with_backup() {
    local src="$1"
    local dst="$2"
    local filename=$(basename "$src")
    
    # Créer le répertoire de destination s'il n'existe pas
    local dst_dir=$(dirname "$dst")
    mkdir -p "$dst_dir"
    
    if [ -f "$dst" ]; then
        # Le fichier existe déjà
        read -p "Le fichier $filename existe déjà. [s]auter, [b]ackup+remplacer, [r]emplacer: " -n 1 -r choice
        echo
        
        case $choice in
            b|B)
                # Créer un backup avec timestamp
                local backup_dir="$HOME_DIR/.dotfiles_backup"
                mkdir -p "$backup_dir"
                local timestamp=$(date +%Y%m%d_%H%M%S)
                local backup_file="$backup_dir/${filename}_${timestamp}.bak"
                cp "$dst" "$backup_file"
                echo -e "${YELLOW}  💾 Backup créé: $backup_file${NC}"
                cp "$src" "$dst"
                echo -e "${GREEN}  ✓ Fichier remplacé: $filename${NC}"
                echo "BACKED_UP" >> "$RESULTS_FILE"
                ;;
            r|R)
                # Remplacer sans backup
                cp "$src" "$dst"
                echo -e "${GREEN}  ✓ Fichier remplacé: $filename${NC}"
                echo "COPIED" >> "$RESULTS_FILE"
                ;;
            *)
                # Par défaut: sauter
                echo -e "${YELLOW}  ⊘ Fichier ignoré: $filename${NC}"
                echo "SKIPPED" >> "$RESULTS_FILE"
                ;;
        esac
    else
        # Le fichier n'existe pas, le copier
        cp "$src" "$dst"
        echo -e "${GREEN}  ✓ Fichier copié: $filename${NC}"
        echo "COPIED" >> "$RESULTS_FILE"
    fi
}

# Parcourir tous les fichiers du dossier assets
find "$ASSETS_DIR" -type f | sort | while read -r file; do
    # Obtenir le chemin relatif par rapport à assets
    relative_path="${file#$ASSETS_DIR/}"
    
    # Déterminer la destination (dans le home)
    destination="$HOME_DIR/$relative_path"
    
    copy_file_with_backup "$file" "$destination"
done

# Compter les résultats
while read -r action; do
    case $action in
        COPIED) ((COPIED++)) ;;
        BACKED_UP) ((BACKED_UP++)) ;;
        SKIPPED) ((SKIPPED++)) ;;
    esac
done < "$RESULTS_FILE"

echo ""
echo -e "${GREEN}✓ Installation complétée${NC}"
echo "  - Fichiers copiés: $COPIED"
echo "  - Fichiers sauvegardés puis remplacés: $BACKED_UP"
echo "  - Fichiers ignorés: $SKIPPED"
