#!/usr/bin/env bash
# Gera o plugin, a feature e um repositório p2 local em dist/.
#
#   dist/com.tiago.dbeaver.dracula_<versão>.jar   plugin (tema)
#   dist/repository/                              repositório p2 (para install.sh
#                                                 ou Help > Install New Software)
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
for f in META-INF/MANIFEST.MF plugin.xml build.properties css/dracula.css \
         feature/feature.xml category.xml; do
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

# 2. Limpeza
rm -rf "$DIST"
mkdir -p "$DIST/site/plugins" "$DIST/site/features"

# 3. Plugin
PLUGIN_JAR="$DIST/site/plugins/${BUNDLE_ID}_${VERSION}.jar"
(cd "$ROOT" && jar --create --file "$PLUGIN_JAR" --manifest META-INF/MANIFEST.MF plugin.xml css)
cp "$PLUGIN_JAR" "$DIST/"

# 4. Feature
(cd "$ROOT/feature" && jar --create --file "$DIST/site/features/${FEATURE_ID}_${VERSION}.jar" feature.xml)

# 5. Repositório p2
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
rm -rf "$DIST/site"

# 6. Resultado
echo
echo "Build concluído (versão $VERSION):"
jar --list --file "$DIST/${BUNDLE_ID}_${VERSION}.jar" | sed 's/^/  /'
find "$DIST/repository" -type f | sed "s|$DIST/|  |"
