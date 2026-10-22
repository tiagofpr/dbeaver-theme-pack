#!/usr/bin/env bash
# Instala, atualiza ou remove o DBeaver Theme Pack pelo p2 director do próprio DBeaver.
#
#   ./install.sh              instala (ou reinstala) a partir de dist/repository
#   ./install.sh --uninstall  remove o plugin
#   ./install.sh --status     mostra se o plugin está instalado
#
# Migração do antigo "DBeaver Dracula Theme" (1.x): a instalação remove o plugin
# antigo, se presente, e troca nas preferências o ID do tema ativo pelo novo
# (com backup do arquivo de preferências).
#
# O p2 registra a instalação no perfil do DBeaver. Numa instalação somente
# leitura (pacote DEB em /usr/share), o perfil fica na área do usuário, então
# não é preciso sudo e nenhum arquivo do DBeaver é alterado.
# Defina DBEAVER_HOME se o DBeaver não estiver em /usr/share/dbeaver-ce.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$ROOT/dist/repository"
IU="com.tiago.dbeaver.themepack.feature.feature.group"
LEGACY_IU="com.tiago.dbeaver.dracula.feature.feature.group"
# ID antigo -> ID novo do tema
THEME_MIGRATION=(
    "com.tiago.dbeaver.dracula.theme.dark=com.tiago.dbeaver.themepack.dracula.dark"
    "com.tiago.dbeaver.solarized.theme.dark=com.tiago.dbeaver.themepack.solarized.dark"
)

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

# Troca o ID do tema ativo nas preferências de cada workspace do DBeaver
migrate_theme_preference() {
    local prefs entry old new backup
    for prefs in "$HOME"/.local/share/DBeaverData/workspace*/.metadata/.plugins/org.eclipse.core.runtime/.settings/org.eclipse.e4.ui.css.swt.theme.prefs; do
        [[ -f "$prefs" ]] || continue
        for entry in "${THEME_MIGRATION[@]}"; do
            old="${entry%%=*}"; new="${entry#*=}"
            if grep -qx "themeid=$old" "$prefs"; then
                backup="$prefs.bak-$(date +%Y%m%d%H%M%S)"
                cp -p "$prefs" "$backup"
                sed -i "s/^themeid=$old\$/themeid=$new/" "$prefs"
                echo "Tema ativo migrado: $old -> $new (backup: $backup)"
            fi
        done
    done
}

case "${1:-}" in
    --status)
        director -listInstalledRoots | grep -F -e "$IU" -e "$LEGACY_IU" || echo "Plugin não instalado."
        ;;
    --uninstall)
        director -uninstallIU "$IU"
        echo
        echo "Plugin removido. Se um dos temas estava ativo, o DBeaver voltará ao tema padrão."
        ;;
    "")
        [[ -f "$REPO_DIR/content.jar" ]] || fail "repositório não encontrado; execute ./build.sh"
        installed="$(director -listInstalledRoots)"
        # Plugin antigo (DBeaver Dracula Theme 1.x): registra os mesmos temas
        if grep -qF "$LEGACY_IU" <<< "$installed"; then
            echo "Removendo o plugin antigo DBeaver Dracula Theme..."
            director -uninstallIU "$LEGACY_IU"
        fi
        # Reinstalação: remove a versão anterior, se existir, antes de instalar
        if grep -qF "$IU" <<< "$installed"; then
            director -uninstallIU "$IU"
        fi
        director -repository "file:$REPO_DIR" -installIU "$IU"
        migrate_theme_preference
        echo
        echo "DBeaver Theme Pack instalado em $DBEAVER_HOME (perfil p2)."
        echo "Abra o DBeaver e selecione o tema em:"
        echo "  Window > Preferences > User Interface > Appearance > Theme"
        echo "  (Dracula ou Solarized Dark)"
        echo "Para remover: ./install.sh --uninstall"
        ;;
    *)
        fail "opção desconhecida: $1"
        ;;
esac
