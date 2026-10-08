# Mapa do pipeline e prioridades de manutenção

## Sequência analítica

| Prioridade | Script | Entrada principal | Produto principal | Função |
|---|---|---|---|---|
| 0 | `groundhog_init.R`, `config.R`, `functions.R` | Ambiente R e configuração local | Pacotes, parâmetros e funções em memória | Preparar o ambiente antes das etapas analíticas |
| 1 | `built.R` | CSV/Excel em `data/`, APIs e BigQuery | `output/dados_<escopo>.RData` e bases auxiliares | Construir as bases integradas |
| 2 | `group_balance.R` | `dados_<escopo>.RData` | `painel_<escopo>.RData`, tabelas e arquivos `.rds`/`.csv` | Padronizar códigos municipais, painel e grupos |
| 3 | `estimation.R` | Painel da etapa 2 | `estimacao_<escopo>.RData` | Estimações principais |
| 4 | `heterogeneity_estimation.R` | Estimações principais e educação | `estimacao_heterogeneidade_<escopo>.RData` | Heterogeneidade educacional e regional |
| 5 | `electoral_estimation.R` | Resultados anteriores e dados eleitorais | Atualiza `estimacao_heterogeneidade_<escopo>.RData` e cria `figuras_<escopo>.RData` | Análises eleitorais e consolidação para figuras |
| 6 | `fig_built.R` | `figuras_<escopo>.RData` | `output/figures/` e `output/tables/` | Exportar tabelas e gráficos finais |

`<escopo>` é controlado por `SCOPE` em `config.R`: `cultura`, `audiovisual` ou `outras_artes`.

## Pendências antes de considerar o pipeline reproduzível

1. **Orquestrador revisado, execução ainda não validada.** A versão nesta pasta corrige a ordem inicial de carga e verifica os nomes de saída que as etapas efetivamente salvam. Ela não foi executada; a reprodução integral ainda depende dos insumos, pacotes, acessos externos e ajustes locais listados abaixo.
2. **Há dependências locais e externas.** `config.R` agora permite configurar `DIR.DATA.PROJECT` por `MARCHA_DATA_DIR` e o faturamento por `BD_BILLING_PROJECT_ID`; alguns insumos ainda são lidos diretamente de `data/`. `built.R` pode consultar APIs e BigQuery. Documentar completamente as origens e testar a configuração em outra máquina continuam prioritários.
3. **A instalação de pacote está dentro da geração de figuras.** `fig_built.R` chama `install.packages("ggrepel")` durante a execução; a instalação deveria ser parte documentada da preparação do ambiente, não ocorrer silenciosamente no relatório.
4. **Tempo e escopo.** O cabeçalho de `master.R` estima cerca de 910 minutos. A execução pode gerar consultas externas, consumir recursos e depender de limites dos serviços; não iniciar sem revisar escopo, cache e permissões.
5. **Metadados da pesquisa.** A pasta fonte contém `CITATION.cff.docx` e `LICENSE.docx`, ambos documentos Word, não arquivos CFF/LICENSE em formato de texto. A origem e a licença de cada base também precisam de registro antes de qualquer publicação de dados.
6. **README de origem inválido.** O `README.md` da pasta fonte é, pelos metadados do arquivo, um documento Word/ZIP com extensão `.md`, não Markdown legível. Ele não foi importado.

## Regra de manutenção

- Corrigir primeiro reprodutibilidade, caminhos, configuração de faturamento e verificações do orquestrador.
- Depois validar cada etapa na ordem acima usando cópias controladas dos insumos e outputs existentes.
- Só então atualizar resultados, tabelas ou figuras; registrar fontes, data de extração, transformações e limitações.
- Não misturar insumos de trabalho nem arquivos `.RData` intermediários com a seleção pública do site.
- Preservar a pasta de origem e registrar cada alteração analítica em histórico versionado.
