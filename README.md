# MARCHA — pesquisa sobre a Lei Paulo Gustavo

Este repositório contém o projeto de pesquisa quantitativa sobre a implementação da Lei Paulo Gustavo nos municípios brasileiros e seus arquivos de análise em R.

## Projeto RStudio

Abra `MLPD.Rproj` no RStudio. Os scripts `.R` e as configurações da pesquisa ficam na raiz. `config.R` reúne parâmetros e caminhos locais.

## Dados de entrada

As três bases de entrada atualmente usadas pelo projeto estão versionadas em `data/` como cópias estáticas. Elas foram copiadas para este repositório; não há sincronização nem vínculo com iCloud ou outra nuvem pessoal.

- `data/PauloGustavo - 6 - Painel de Utilização - Lista Município_Detalhamento Municípios_Tabela.csv` — detalhamento municipal da utilização dos recursos da Lei Paulo Gustavo.
- `data/br_inep_ideb_municipio.csv` — indicadores municipais do IDEB.
- `data/highereduc.xlsx` — distribuição da população de 18 anos ou mais por nível de instrução e município, Censo 2022.

Os arquivos contêm dados agregados, sem identificadores pessoais. Consulte `data/README.md` para detalhes sobre fontes e execução. A execução integral dos scripts ainda pode exigir internet para consultar APIs e um projeto com faturamento no BigQuery, caso os caches de RAIS e resultados eleitorais não estejam disponíveis. Resultados intermediários em `output/` permanecem fora do controle de versão.

## Conteúdo

- `MLPD.Rproj` — projeto do RStudio.
- `*.R` — scripts, funções, construção de bases, estimações e geração de resultados.
- `config.R` — parâmetros e caminhos configuráveis.
- `data/` — bases de entrada da pesquisa e instruções de uso.
