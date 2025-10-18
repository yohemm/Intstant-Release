#!/bin/bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/paths.sh"

escape_regex_parts() {
    local string="$1"
    local IFS='|'
    local parts=($string)
    local escaped_parts=()
    
    for part in "${parts[@]}"; do
        # Échapper tous les caractères spéciaux dans chaque partie
        local escaped=$(echo "$part" | sed 's/\([\.^$*+?{}[\]\\()]\)/\\\1/g')
        escaped_parts+=("$escaped")
    done
    
    # Rejoindre avec | (sans l'échapper)
    echo "${escaped_parts[*]}" | sed 's/ /|/g'
}