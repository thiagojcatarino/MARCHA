# Código de pesquisa — Lei Paulo Gustavo

Esta pasta reúne os scripts R da pesquisa sobre a execução municipal dos recursos da Lei Paulo Gustavo e os indicadores de emprego, renda e contexto municipal analisados na monografia.

## Prioridade e ordem de execução

A ordem documentada é `built.R` → `group_balance.R` → `estimation.R` → `heterogeneity_estimation.R` → `electoral_estimation.R` → `fig_built.R`. `master.R` é o orquestrador planejado para essa sequência. A descrição dos insumos, produtos e pendências de execução está em [PIPELINE.md](PIPELINE.md).

## Arquivos

- `master.R` — orquestração da análise; revisado para respeitar a ordem dos produtos intermediários e isolar o ambiente de cada etapa.
- `config.R` — escopo, diretórios, parâmetros e funções gerais.
- `functions.R` — funções auxiliares usadas pelos demais scripts.
- `groundhog_init.R` — versões do ambiente de pacotes, fixadas em 21/04/2025.
- `built.R` — preparação e integração das bases.
- `group_balance.R` — construção do painel e grupos de análise.
- `estimation.R` — estimações principais.
- `heterogeneity_estimation.R` — análises educacionais e regionais.
- `electoral_estimation.R` — análises eleitorais.
- `fig_built.R` — tabelas e figuras.
- `MLPD.Rproj` — configuração do projeto no RStudio.

## Insumos locais

Os arquivos de entrada ficam em `data/` quando disponíveis localmente. Por padrão, essa pasta é ignorada pelo Git para evitar publicar bases brutas ou volumosas sem inventário, licença e decisão editorial. A lista esperada está em [data/README.md](data/README.md). Os produtos intermediários e finais ficam em `output/`, também ignorado pelo Git.

O código de origem usa caminhos relativos ao diretório do projeto. Abra `MLPD.Rproj` no RStudio e confirme que a pasta de trabalho é esta pasta `codigo/` antes de executar qualquer script. Se os insumos estiverem em outro local, configure `MARCHA_DATA_DIR`; os arquivos referenciados diretamente pelo pipeline ainda precisam estar acessíveis em `data/`.

## Ambiente e acesso externo

Os pacotes são inicializados por `groundhog_init.R`. Partes de `built.R` consultam SICONFI, Base dos Dados/BigQuery, SIDRA e outros serviços. A reprodução dessas consultas pode exigir acesso à internet, credenciais ou um projeto de faturamento BigQuery. Não inclua chaves, tokens ou credenciais no repositório. O identificador de faturamento foi removido dos scripts e deve ser configurado localmente pela variável de ambiente `BD_BILLING_PROJECT_ID` antes das consultas BigQuery.

## Estado editorial

Os scripts foram copiados da pasta `Downloads/Base_de_Dados` em 07/10/2026. A pasta de origem foi preservada. Esta inclusão organiza e documenta o código; não constitui validação das estimativas, auditoria de segurança ou reprodução integral dos resultados. Pendências conhecidas estão em [PIPELINE.md](PIPELINE.md).
