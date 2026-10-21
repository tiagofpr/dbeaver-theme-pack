#!/usr/bin/env bash
# Instala, atualiza ou remove o tema pelo p2 director do próprio DBeaver.
#
#   ./install.sh              instala (ou reinstala) a partir de dist/repository
#   ./install.sh --uninstall  remove o tema
#   ./install.sh --status     mostra se o tema está instalado
#
# O p2 registra a instalação no perfil do DBeaver. Numa instalação somente
# leitura (pacote DEB em /usr/share), o perfil fica na área do usuário, então
# não é preciso sudo e nenhum arquivo do DBeaver é alterado.
# Defina DBEAVER_HOME se o DBeaver não estiver em /usr/share/dbeaver-ce.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$ROOT/dist/repository"
IU="com.tiago.dbeaver.dracula.feature.feature.group"
THEME_ID="com.tiago.dbeaver.dracula.theme.dark"

fail() { echo "ERRO: $*" >&2; exit 1; }

detect_dbeaver() {
    if [[ -n "${DBEAVER_HOME:-}" ]]; then
        echo "$DBEAVER_HOME"; return
    fi
    local candidate
    for candidate in /usr/share/dbeaver-ce /opt/dbeaver "$HOME/dbeaver" \
                     "$(dirname "$(readlink -f "$(command -v dbeaver 2>/dev/null || echo /nonexistent)")")"; do
        [[ -x "$candidate/dbeaver" && -d "$candidate/plugins" ]] && { echo "$candidate"; return; }
    done
    if command -v snap >/dev/null && snap list dbeaver-ce >/dev/null 2>&1; then
        fail "DBeaver via Snap não é suportado (sistema de arquivos somente leitura)"
    fi
    if command -v flatpak >/dev/null && flatpak list 2>/dev/null | grep -qi dbeaver; then
        fail "DBeaver via Flatpak não é suportado por este script; use Help > Install New Software"
    fi
    fail "DBeaver não encontrado; defina DBEAVER_HOME"
}

DBEAVER_HOME="$(detect_dbeaver)"

if pgrep -u "$USER" -f "^$DBEAVER_HOME/+(jre/bin/java|dbeaver)" >/dev/null || pgrep -u "$USER" -x dbeaver >/dev/null; then
    fail "feche o DBeaver antes de continuar"
fi

director() {
    "$DBEAVER_HOME/dbeaver" -nosplash -consoleLog -data @none \
        -application org.eclipse.equinox.p2.director "$@"
}

case "${1:-}" in
    --status)
        director -listInstalledRoots | grep -F "$IU" || echo "Tema não instalado."
        ;;
    --uninstall)
        director -uninstallIU "$IU"
        echo
        echo "Tema removido. Se ele estava ativo, o DBeaver voltará ao tema padrão."
        ;;
    "")
        [[ -f "$REPO_DIR/content.jar" ]] || fail "repositório não encontrado; execute ./build.sh"
        # Reinstalação: remove a versão anterior, se existir, antes de instalar
        if director -listInstalledRoots | grep -qF "$IU"; then
            director -uninstallIU "$IU"
        fi
        director -repository "file:$REPO_DIR" -installIU "$IU"
        echo
        echo "Tema instalado em $DBEAVER_HOME (perfil p2)."
        echo "Abra o DBeaver e selecione:"
        echo "  Window > Preferences > User Interface > Appearance > Theme > Dracula"
        echo "ID do tema: $THEME_ID"
        echo "Para remover: ./install.sh --uninstall"
        ;;
    *)
        fail "opção desconhecida: $1"
        ;;
esac
