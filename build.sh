#!/usr/bin/env bash
# Gera o plugin, a feature e um repositório p2 local em dist/.
#
#   css/<tema>.css                                gerado de themes/theme.css.in +
#                                                 themes/<tema>.properties
#   dist/com.tiago.dbeaver.dracula_<versão>.jar   plugin (tema)
#   dist/repository/                              repositório p2 (para install.sh
#                                                 ou Help > Install New Software)
#   dist/dbeaver-dracula-theme-<versão>-p2.zip    mesmo repositório compactado
#                                                 (Install New Software > Archive)
#
# O repositório p2 é gerado com o publisher que acompanha o próprio DBeaver.
# Defina DBEAVER_HOME se o DBeaver não estiver em /usr/share/dbeaver-ce.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST="$ROOT/dist"
DBEAVER_HOME="${DBEAVER_HOME:-/usr/share/dbeaver-ce}"

BUNDLE_ID="com.tiago.dbeaver.dracula"
FEATURE_ID="com.tiago.dbeaver.dracula.feature"

fail() { echo "ERRO: $*" >&2; exit 1; }

# 1. Validação da estrutura
for f in META-INF/MANIFEST.MF plugin.xml build.properties themes/theme.css.in \
         themes/generate.sh feature/feature.xml category.xml; do
    [[ -f "$ROOT/$f" ]] || fail "arquivo obrigatório ausente: $f"
done
command -v jar >/dev/null || fail "'jar' não encontrado (instale um JDK)"
[[ -x "$DBEAVER_HOME/dbeaver" ]] || fail "DBeaver não encontrado em $DBEAVER_HOME (defina DBEAVER_HOME)"

VERSION="$(sed -n 's/^Bundle-Version: *//p' "$ROOT/META-INF/MANIFEST.MF" | tr -d '\r')"
[[ -n "$VERSION" ]] || fail "Bundle-Version não encontrado no MANIFEST.MF"
grep -q "version=\"$VERSION\"" "$ROOT/feature/feature.xml" \
    || fail "versão da feature diferente de $VERSION em feature/feature.xml"
if command -v xmllint >/dev/null; then
    xmllint --noout "$ROOT/plugin.xml" "$ROOT/feature/feature.xml" "$ROOT/category.xml"
fi

# Qualificador de build (convenção Eclipse): cada build tem versão maior que
# a anterior, assim o p2 nunca reaproveita um artefato antigo do cache.
QUALIFIED="$VERSION.v$(date +%Y%m%d%H%M%S)"

# 2. Limpeza
rm -rf "$DIST"
mkdir -p "$DIST/site/plugins" "$DIST/site/features" "$DIST/tmp"

# 3. CSS dos temas: um por paleta; cada um precisa estar registrado no plugin.xml
rm -rf "$ROOT/css"
mkdir -p "$ROOT/css"
for palette in "$ROOT"/themes/*.properties; do
    name="$(basename "$palette" .properties)"
    theme_id="$(sed -n 's/^theme.id=//p' "$palette")"
    grep -q "id=\"$theme_id\"" "$ROOT/plugin.xml" \
        || fail "tema $theme_id ($name) não registrado no plugin.xml"
    grep -q "basestylesheeturi=\"css/$name.css\"" "$ROOT/plugin.xml" \
        || fail "plugin.xml não aponta para css/$name.css"
    "$ROOT/themes/generate.sh" "$ROOT/themes/theme.css.in" "$palette" "$ROOT/css/$name.css"
done

# 4. Plugin
sed "s/^Bundle-Version: .*/Bundle-Version: $QUALIFIED/" "$ROOT/META-INF/MANIFEST.MF" > "$DIST/tmp/MANIFEST.MF"
PLUGIN_JAR="$DIST/site/plugins/${BUNDLE_ID}_${QUALIFIED}.jar"
(cd "$ROOT" && jar --create --file "$PLUGIN_JAR" --manifest "$DIST/tmp/MANIFEST.MF" plugin.xml css)
cp "$PLUGIN_JAR" "$DIST/${BUNDLE_ID}_${VERSION}.jar"

# 5. Feature
sed "s/version=\"$VERSION\"/version=\"$QUALIFIED\"/g" "$ROOT/feature/feature.xml" > "$DIST/tmp/feature.xml"
(cd "$DIST/tmp" && jar --create --file "$DIST/site/features/${FEATURE_ID}_${QUALIFIED}.jar" feature.xml)

# 6. Repositório p2
REPO="file:$DIST/repository"
P2_ARGS=(-nosplash -consoleLog -data @none)
"$DBEAVER_HOME/dbeaver" "${P2_ARGS[@]}" \
    -application org.eclipse.equinox.p2.publisher.FeaturesAndBundlesPublisher \
    -metadataRepository "$REPO" -artifactRepository "$REPO" \
    -source "$DIST/site" -publishArtifacts -compress
"$DBEAVER_HOME/dbeaver" "${P2_ARGS[@]}" \
    -application org.eclipse.equinox.p2.publisher.CategoryPublisher \
    -metadataRepository "$REPO" \
    -categoryDefinition "file:$ROOT/category.xml" -categoryQualifier "$BUNDLE_ID" -compress
[[ -f "$DIST/repository/content.jar" ]] || fail "repositório p2 não foi gerado"
rm -rf "$DIST/site" "$DIST/tmp"
(cd "$DIST/repository" && zip -qr "$DIST/dbeaver-dracula-theme-${VERSION}-p2.zip" .)

# 7. Resultado
echo
echo "Build concluído (versão $QUALIFIED):"
jar --list --file "$DIST/${BUNDLE_ID}_${VERSION}.jar" | sed 's/^/  /'
find "$DIST/repository" -type f | sed "s|$DIST/|  |"
echo "  dbeaver-dracula-theme-${VERSION}-p2.zip"
