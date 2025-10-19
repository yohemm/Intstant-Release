#!/usr/bin/env bash
set -euo pipefail

# Chargement des chemins si nécessaire (inchangé)
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/paths.sh"

# ------------------------------------------------------------
# Fonction : escape_regex_parts
# Objectif : préparer une chaîne pour une utilisation dans un regex
# - Garde les espaces
# - Laisse les pipes '|' intacts
# - Transforme les virgules en ' | '
# - Échappe tous les autres caractères spéciaux regex
# ------------------------------------------------------------
escape_regex_parts() {
    local string="$1"

    # Remplacer les virgules par " | " (avec espaces)
    string="${string//,/ | }"

    # Liste : . ^ $ * + ? ( ) [ ] { } \
    local escaped
    escaped=$(echo "$string" | sed -E \
        -e 's/\\/\\\\/g' \
        -e 's/([][(){}.^$*+?])/\\\1/g'
    )

    echo "$escaped"
}