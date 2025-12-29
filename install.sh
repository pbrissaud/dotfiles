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
IDENTICAL=0
ERROR=0
RESULTS_FILE=$(mktemp)
trap "rm -f $RESULTS_FILE" EXIT

# Fonction pour calculer le hash d'un fichier
get_file_hash() {
    shasum -a 256 "$1" 2>/dev/null | cut -d' ' -f1
}

# Fonction pour afficher la différence entre deux fichiers
show_diff() {
    local src="$1"
    local dst="$2"
    echo -e "${BLUE}  --- Différences (existant → nouveau) ---${NC}"
    diff --color=auto -u "$dst" "$src" 2>/dev/null || diff -u "$dst" "$src"
    echo -e "${BLUE}  -----------------------------------------${NC}"
}

# Fichiers à ne jamais remplacer (seulement créer s'ils n'existent pas)
NEVER_REPLACE_FILES=(".zsh_override.zsh")

# Vérifie si un fichier est dans la liste des fichiers à ne jamais remplacer
is_never_replace() {
    local filename="$1"
    for f in "${NEVER_REPLACE_FILES[@]}"; do
        if [ "$filename" = "$f" ]; then
            return 0
        fi
    done
    return 1
}

# Fonction pour copier un fichier avec backup
copy_file_with_backup() {
    local src="$1"
    local dst="$2"
    local filename=$(basename "$src")

    # Vérifier que le fichier source existe
    if [ ! -f "$src" ]; then
        echo -e "${RED}  ❌ Fichier source introuvable: $src${NC}"
        echo "ERROR" >> "$RESULTS_FILE"
        return 1
    fi

    # Créer le répertoire de destination s'il n'existe pas
    local dst_dir=$(dirname "$dst")
    mkdir -p "$dst_dir" 2>/dev/null || {
        echo -e "${RED}  ❌ Impossible de créer le répertoire: $dst_dir${NC}"
        echo "ERROR" >> "$RESULTS_FILE"
        return 1
    }

    if [ -f "$dst" ]; then
        # Fichier à ne jamais remplacer - ignorer silencieusement
        if is_never_replace "$filename"; then
            echo -e "${BLUE}  ⊘ Fichier override existant (conservé): $filename${NC}"
            echo "SKIPPED" >> "$RESULTS_FILE"
            return 0
        fi

        # Le fichier existe déjà - vérifier s'il est identique
        local src_hash=$(get_file_hash "$src")
        local dst_hash=$(get_file_hash "$dst")

        if [ "$src_hash" = "$dst_hash" ]; then
            echo -e "${GREEN}  ✓ Fichier identique (ignoré): $filename${NC}"
            echo "IDENTICAL" >> "$RESULTS_FILE"
            return 0
        fi

        # Fichiers différents - afficher la diff
        echo -e "${YELLOW}  ⚠ Le fichier $filename existe et est différent:${NC}"
        show_diff "$src" "$dst"

        read -p "  Action? [s]auter, [b]ackup+remplacer, [r]emplacer: " -n 1 -r choice
        echo

        case $choice in
            b|B)
                # Créer un backup avec timestamp
                local backup_dir="$HOME_DIR/.dotfiles_backup"
                mkdir -p "$backup_dir"
                local timestamp=$(date +%Y%m%d_%H%M%S)
                local backup_file="$backup_dir/${filename}_${timestamp}.bak"
                cp "$dst" "$backup_file"
                cp "$src" "$dst" 2>/dev/null
                if [ $? -eq 0 ]; then
                    echo -e "${YELLOW}  💾 Backup créé: $backup_file${NC}"
                    echo -e "${GREEN}  ✓ Fichier remplacé: $filename${NC}"
                    echo "BACKED_UP" >> "$RESULTS_FILE"
                else
                    echo -e "${RED}  ❌ Erreur lors de la copie: $filename${NC}"
                    echo "ERROR" >> "$RESULTS_FILE"
                fi
                ;;
            r|R)
                # Remplacer sans backup
                cp "$src" "$dst" 2>/dev/null
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}  ✓ Fichier remplacé: $filename${NC}"
                    echo "COPIED" >> "$RESULTS_FILE"
                else
                    echo -e "${RED}  ❌ Erreur lors de la copie: $filename${NC}"
                    echo "ERROR" >> "$RESULTS_FILE"
                fi
                ;;
            *)
                # Par défaut: sauter
                echo -e "${YELLOW}  ⊘ Fichier ignoré: $filename${NC}"
                echo "SKIPPED" >> "$RESULTS_FILE"
                ;;
        esac
    else
        # Le fichier n'existe pas, le copier
        cp "$src" "$dst" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}  ✓ Fichier copié: $filename${NC}"
            echo "COPIED" >> "$RESULTS_FILE"
        else
            echo -e "${RED}  ❌ Erreur lors de la copie: $filename${NC}"
            echo "ERROR" >> "$RESULTS_FILE"
        fi
    fi
}

# Parcourir tous les fichiers du dossier assets
# Utiliser une redirection temporaire pour éviter les problèmes de pipe avec le vieux bash 3.2 de macOS
_files_list=$(mktemp)
trap "rm -f $_files_list" RETURN
find "$ASSETS_DIR" -type f | sort > "$_files_list"

while IFS= read -r file <&3; do
    [ -z "$file" ] && continue
    
    # Obtenir le chemin relatif par rapport à assets
    relative_path="${file#$ASSETS_DIR/}"
    
    # Déterminer la destination (dans le home)
    destination="$HOME_DIR/$relative_path"
    
    copy_file_with_backup "$file" "$destination"
done 3< "$_files_list"

# Compter les résultats si le fichier existe
if [ -f "$RESULTS_FILE" ]; then
    while IFS= read -r action; do
        case $action in
            COPIED) ((COPIED++)) ;;
            BACKED_UP) ((BACKED_UP++)) ;;
            SKIPPED) ((SKIPPED++)) ;;
            IDENTICAL) ((IDENTICAL++)) ;;
            ERROR) ((ERROR++)) ;;
        esac
    done < "$RESULTS_FILE"
fi

echo ""
echo -e "${GREEN}✓ Installation complétée${NC}"
echo "  - Fichiers copiés: $COPIED"
echo "  - Fichiers sauvegardés puis remplacés: $BACKED_UP"
echo "  - Fichiers identiques (ignorés): $IDENTICAL"
echo "  - Fichiers ignorés: $SKIPPED"
if [ $ERROR -gt 0 ]; then
    echo -e "  - ${RED}Erreurs: $ERROR${NC}"
fi

# ============================================================================
# SECTION 3: Rechargement de la configuration zsh
# ============================================================================

echo ""
echo -e "${BLUE}🔄 Rechargement de la configuration zsh${NC}"
echo "=========================================="

if [ -f "$HOME/.zshrc" ]; then
    echo -e "${GREEN}✓ Exécution de: source \$HOME/.zshrc${NC}"
    # Note: source dans un script bash ne persiste pas dans le shell parent.
    # On utilise exec pour remplacer le processus courant par un nouveau shell zsh.
    exec zsh -l
else
    echo -e "${YELLOW}⚠️  Fichier ~/.zshrc introuvable, rechargement ignoré${NC}"
fi
