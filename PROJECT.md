# MARCHA — Museu, arquivo e pesquisa

## Identidade e propósito

MARCHA — Marcha Lenta para Pés Desbravadores — é uma pesquisa continuada sobre cultura, produção artística, memória, documentação, curadoria e circulação de conhecimento. O Museu Virtual Multidisciplinar é a instituição/plataforma que a abriga. O projeto reúne e relaciona obras, projetos, pessoas, lugares, documentos, imagens, textos e dados.

A pergunta orientadora é: **como construir uma infraestrutura digital capaz de documentar, relacionar, pesquisar e tornar pública uma produção cultural multidisciplinar ao longo do tempo?** O site é a face pública de uma estrutura maior de conhecimento.

## Referência do protótipo

A pasta original `02 Projeto/MLPD/10_Site` no iCloud foi inspecionada como referência e permanece intacta. Esta cópia de trabalho restaura a direção aprovada nela: fundo branco/off-white, Georgia e sans do sistema, títulos amplos, espaço negativo, linhas discretas e o menu editorial em cortina. A lógica de hierarquia editorial vem de publicações culturais e jornalísticas, sem reproduzir a identidade de uma publicação específica.

O protótipo anterior desta conversa usava cartões ilustrados, acento vermelho e composição de landing page; a direção atual substitui essa linguagem pela referência original.

## Arquitetura do site

- `index.html`: capa, pesquisa, índice do acervo, curadoria, publicações/dados e instituição.
- `assets/css/base/style.css`: tokens, tipografia e regras globais, copiados da estrutura de referência.
- `assets/css/components/menu.css`: navegação editorial e transição em cortina, copiados da referência.
- `assets/css/pages/home.css`: composição da Home e estilos das seções editoriais.
- `assets/js/menu.js`: abertura/fechamento do índice e suporte a teclado.
- `assets/js/catalog.js`: renderização do índice de pesquisa.
- `data/catalog.json`: registros estruturados da MLPD 2019, 2022 e 2026.

O catálogo é uma primeira entidade reutilizável, com ID, tipo, ano, estado, resumo e relações. Os registros históricos permanecem descritos como em organização até revisão documental.

## Organização futura do acervo

A estrutura local existente já separa pesquisas, dados, ensaios, fotografia, entrevistas, cronologias, referências, exposições futuras, relatórios institucionais e o site. A migração para GitHub deve preservar essa organização, acrescentando convenções claras para código, dados de origem, dados processados, documentação e materiais selecionados para exposição pública.

Antes de publicar qualquer documento, imagem ou conjunto de dados, o material será inventariado e classificado para distinguir fontes, outputs de pesquisa, itens de trabalho e conteúdos aprovados para exibição.

## Princípios técnicos

A primeira versão usa HTML, CSS, JavaScript puro e JSON. Não requer compilação. O objetivo é publicar o site como conteúdo estático, mantendo o acervo versionado e as pesquisas reproduzíveis. Projetos quantitativos devem preservar fonte, data de acesso, metodologia, código de tratamento e outputs; R faz parte da infraestrutura de análise quando pertinente.

## Próximos passos

1. Inventariar a árvore completa de `02 Projeto/MLPD` e mapear cada projeto e produção.
2. Decidir o repositório canônico e a separação entre acervo de trabalho e seleção pública.
3. Registrar esta homepage como primeira versão no Git, depois de estabelecer a pasta local canônica.
4. Migrar os materiais por grupos, preservando originais e documentando metadados.
5. Preparar a exposição digital apenas com conteúdos revisados e selecionados.
