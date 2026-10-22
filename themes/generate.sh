#!/usr/bin/env bash
# Gera o CSS de um tema a partir do modelo e de uma paleta.
#
#   themes/generate.sh themes/theme.css.in themes/dracula.properties saida.css
#
# Na paleta, cada linha "chave=#RRGGBB" substitui {{chave}} pelo hex e
# {{chave:rgb}} por "r,g,b" (formato das preferências do Eclipse).
# Demais linhas "chave=valor" substituem apenas {{chave}}.
set -euo pipefail

TEMPLATE="$1"
PALETTE="$2"
OUTPUT="$3"

fail() { echo "ERRO: $*" >&2; exit 1; }

SED_SCRIPT="$(mktemp)"
trap 'rm -f "$SED_SCRIPT"' EXIT

while IFS='=' read -r key value; do
    [[ -z "$key" || "$key" == \#* ]] && continue
    key="${key//[[:space:]]/}"
    value="${value%%[[:space:]]}"
    if [[ "$value" =~ ^#([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})$ ]]; then
        rgb="$((16#${BASH_REMATCH[1]})),$((16#${BASH_REMATCH[2]})),$((16#${BASH_REMATCH[3]}))"
        echo "s/{{$key:rgb}}/$rgb/g" >> "$SED_SCRIPT"
    fi
    echo "s|{{$key}}|$value|g" >> "$SED_SCRIPT"
done < "$PALETTE"

sed -f "$SED_SCRIPT" "$TEMPLATE" > "$OUTPUT"

if missing="$(grep -o '{{[^}]*}}' "$OUTPUT" | sort -u)" && [[ -n "$missing" ]]; then
    rm -f "$OUTPUT"
    fail "$(basename "$PALETTE"): marcadores sem valor: $(echo $missing)"
fi
