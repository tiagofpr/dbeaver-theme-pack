# DBeaver Dracula Theme

Temas escuros completos para o DBeaver Community, implementados como um plugin
Eclipse (tema CSS do e4). O plugin traz dois temas:

- **Dracula** — paleta oficial [Dracula](https://draculatheme.com/).
- **Solarized Dark** — mesmas cores do tema *Solarized Dark* do Antigravity/VS Code,
  sobre a paleta [Solarized](https://ethanschoonover.com/solarized/).

O objetivo é que toda a interface do DBeaver — janela principal, Database
Navigator, editor SQL, grade de resultados, abas, diálogos e diagramas ER —
utilize a paleta escolhida de forma consistente, sem modificar o código-fonte do
DBeaver e sem depender de APIs internas ou reflexão.

## Capturas de tela

_Em breve._ Componentes validados: janela principal, Database Navigator, editor SQL, grade de resultados (Grid e Text), diálogos, preferências e diagramas ER.

## Paletas de cores

As paletas completas (todos os papéis de cor) estão em
[`themes/dracula.properties`](themes/dracula.properties) e
[`themes/solarized-dark.properties`](themes/solarized-dark.properties).

### Dracula

| Cor          | Hex       | Uso no tema                                        |
|--------------|-----------|----------------------------------------------------|
| Background   | `#282A36` | Fundo principal, fundo do editor                   |
| Current Line | `#44475A` | Seleção                                            |
| Foreground   | `#F8F8F2` | Texto principal, colunas, delimitadores            |
| Comment      | `#6272A4` | Comentários, numeração de linhas, texto secundário |
| Cyan         | `#8BE9FD` | Tabelas, aliases, tipos de dados, links            |
| Green        | `#50FA7B` | Funções                                            |
| Orange       | `#FFB86C` | Parâmetros, variáveis, colunas derivadas           |
| Pink         | `#FF79C6` | Palavras-chave SQL                                 |
| Purple       | `#BD93F9` | Números, schemas, comandos                         |
| Red          | `#FF5555` | Erros                                              |
| Yellow       | `#F1FA8C` | Strings, avisos                                    |

Cores auxiliares: campos `#21222C`, elementos elevados `#303341`,
linha atual do editor `#343746`.

### Solarized Dark

| Cor     | Hex       | Uso no tema                                   |
|---------|-----------|-----------------------------------------------|
| base03  | `#002B36` | Fundo principal, fundo do editor              |
| base02  | `#073642` | Linha atual, linhas da grade                  |
| —       | `#00212B` | Barras, painel lateral, cabeçalhos            |
| —       | `#004052` | Abas inativas, faixas de título               |
| —       | `#005A6F` | Seleção em listas e na grade                  |
| base01  | `#586E75` | Comentários, numeração de linhas, desabilitado|
| base0   | `#839496` | Texto do editor                               |
| base1   | `#93A1A1` | Texto da interface, tipos de dados            |
| green   | `#859900` | Palavras-chave SQL                            |
| cyan    | `#2AA198` | Strings, destaque da aba ativa                |
| magenta | `#D33682` | Números                                       |
| blue    | `#268BD2` | Funções, variáveis, links                     |
| yellow  | `#B58900` | Tabelas, aliases, booleanos, avisos           |
| orange  | `#CB4B16` | Parâmetros, colunas derivadas                 |
| violet  | `#6C71C4` | Schemas, comandos, binários                   |
| red     | `#DC322F` | Erros                                         |

## Requisitos

- Linux (testado no Ubuntu 24.04).
- DBeaver Community instalado por pacote DEB ou arquivo compactado.
  Snap e Flatpak não são suportados pelo `install.sh` (veja abaixo).
- Para compilar: um JDK (qualquer versão ≥ 17, apenas para o utilitário `jar`).

## Versões compatíveis do DBeaver

| DBeaver | Status   |
|---------|----------|
| 26.1.5  | Testado (Ubuntu 24.04, pacote DEB) |

## Instalação

### A partir da release (recomendado)

1. Baixe `dbeaver-dracula-theme-<versão>-p2.zip` na página de
   [Releases](https://github.com/tiagofpr/dbeaver-dracula-theme/releases).
2. No DBeaver: **Help → Install New Software → Add… → Archive…** e selecione o zip.
3. Marque **DBeaver Dracula Theme**, conclua o assistente e reinicie.
4. Ative em **Window → Preferences → User Interface → Appearance → Theme** e
   escolha **Dracula** ou **Solarized Dark**.

### A partir do código-fonte

```bash
./build.sh      # gera dist/ e o repositório p2 em dist/repository
./install.sh    # instala com o DBeaver fechado
```

Depois, no DBeaver:
**Window → Preferences → User Interface → Appearance → Theme**, escolha
**Dracula** ou **Solarized Dark**, aplique e reinicie.

O `install.sh` usa o p2 director que acompanha o DBeaver. Em instalações somente
leitura (DEB em `/usr/share/dbeaver-ce`) o plugin é instalado no perfil do
usuário (`~/.local/share/DBeaverData/install-data/`), **sem sudo** e sem alterar
arquivos do DBeaver. Se o DBeaver estiver em outro local:

```bash
DBEAVER_HOME=/caminho/do/dbeaver ./install.sh
```

Alternativa pela interface: **Help → Install New Software → Add → Local…** e
selecione a pasta `dist/repository`.

> Copiar o JAR para `dropins/` ou `plugins/` **não funciona** no DBeaver: o
> reconciler de dropins vem desativado e os bundles são carregados a partir do
> `bundles.info` gerenciado pelo p2.

Para conferir: `./install.sh --status`.

## Desinstalação

```bash
./install.sh --uninstall
```

Se um dos temas estava ativo, o DBeaver volta ao tema padrão.

## Desenvolvimento

```text
.
├── META-INF/MANIFEST.MF   manifesto OSGi (sem dependências de bundles)
├── plugin.xml             registra os temas no ponto de extensão org.eclipse.e4.ui.css.swt.theme
├── themes/
│   ├── theme.css.in       modelo do CSS, com marcadores de papel ({{bg}}, {{sql_keyword:rgb}}…)
│   ├── dracula.properties paleta de cada tema (um arquivo por tema)
│   ├── solarized-dark.properties
│   └── generate.sh        gera css/<tema>.css a partir do modelo e da paleta
├── css/                   CSS gerados pelo build (não versionados)
├── feature/               feature Eclipse (unidade instalável pelo p2)
├── category.xml           categoria do repositório p2
├── build.sh               gera o plugin, a feature e o repositório p2
└── install.sh             instala/remove via p2 director
```

Ciclo de alteração: edite `themes/theme.css.in` (estrutura/seletores, vale para
todos os temas) ou `themes/<tema>.properties` (cores), feche o DBeaver, rode
`./build.sh && ./install.sh` e abra o DBeaver novamente. O `generate.sh` falha se
algum marcador do modelo não tiver valor na paleta.

**Novo tema:** crie `themes/<nome>.properties` com todas as chaves (copie uma
paleta existente), defina `theme.id` contendo `dark`, e registre o tema no
`plugin.xml` com `basestylesheeturi="css/<nome>.css"`. O `build.sh` confere
esse registro.

Cada build recebe um qualificador de data/hora (`1.0.0.vAAAAMMDDHHMMSS`), para
que o p2 nunca reaproveite um artefato antigo em cache.

### Como o CSS funciona

1. **Base escura.** Os plugins do DBeaver (editor SQL, grade, ERD, AI, GEF)
   associam suas folhas de estilo escuras apenas ao tema `e4_dark`. O
   CSS de cada tema importa essas folhas via `@import url("platform:/plugin/…")`
   e só depois aplica as regras do tema.
2. **Widgets SWT.** Regras como `Shell`, `Tree`, `CTabFolder` e `.MPartStack`
   definem fundo e texto dos componentes.
3. **Cores do editor e do DBeaver.** O editor de texto, o realce SQL e a grade
   não são pintados por seletores de widget, e sim por preferências do Eclipse.
   Elas são definidas com regras `IEclipsePreferences#<nó>:<id>`. O tema usa
   **o mesmo seletor** da folha original do DBeaver; como vem
   depois, a regra do tema substitui a original **por inteiro** — por isso todas as chaves
   precisam ser repetidas.

O DBeaver identifica se o tema é escuro pela cor de fundo do editor de texto
(`UIStyles.isDarkTheme`), não pelo ID do tema.

Os IDs dos temas são `com.tiago.dbeaver.dracula.theme.dark` e
`com.tiago.dbeaver.solarized.theme.dark`. A palavra `dark` é obrigatória: o motor de temas do Eclipse só pede ao GTK a variante escura
(`Display.setDarkThemePreferred`) quando o ID contém `dark`. Sem isso, menus,
barra de menus e realces de clique ficam claros no Linux.

## Problemas conhecidos

- **Menus no Linux (GTK)** são nativos e não aceitam cores via CSS; seguem o tema
  GTK do sistema.
- **Preferências do usuário têm prioridade sobre o tema.** Cores alteradas
  manualmente em *Colors and Fonts* ou importadas por `.epf` sobrescrevem o CSS.
  Para voltar ao tema, use *Restore Defaults* nessas páginas.
- **Atualização do DBeaver.** Após atualizar o pacote DEB, o DBeaver pode pedir
  para migrar os plugins instalados pelo usuário. Se o tema sumir, rode
  `./install.sh` novamente.
- **Cor de seleção em listas e árvores** (azul) vem do tema GTK do sistema e não
  é alcançada pelo CSS do Eclipse. É possível trocá-la iniciando o DBeaver com
  `-Dorg.eclipse.swt.internal.gtk.cssFile=<arquivo.css>` (folha GTK aplicada só
  ao DBeaver), mas isso exige alterar o `dbeaver.ini` ou o atalho de
  inicialização e não faz parte da instalação padrão.
- **Cores dos tipos de conexão** (Production, Test…) não são controladas pelo
  tema: ajuste em *Preferences → Connections → Connection Types → Color (Dark)*.
- Plugins de aparência que usam reflexão em classes internas (ex.: DevStyle)
  podem causar erros como `this.lastTabHeight is null`; este tema não usa
  reflexão nem código Java.

## Contribuição

- Branches: `main` (estável), `develop` (integração), `feature/*`, `fix/*`,
  `release/*`.
- Commits no padrão [Conventional Commits](https://www.conventionalcommits.org/)
  (`feat:`, `fix:`, `style:`, `docs:`, `build:`…).
- Antes de abrir um PR, valide no DBeaver real: build, instalação, ativação do
  tema e ausência de erros em `~/.local/share/DBeaverData/workspace6/.metadata/.log`.

## Licença

[MIT](LICENSE) © Tiago Ribeiro
