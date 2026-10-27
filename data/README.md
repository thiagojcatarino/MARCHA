# Dados da pesquisa

Os seguintes arquivos de entrada fazem parte do projeto e ficam versionados nesta pasta:

- `PauloGustavo - 6 - Painel de Utilização - Lista Município_Detalhamento Municípios_Tabela.csv` — detalhamento municipal da utilização dos recursos da Lei Paulo Gustavo.
- `br_inep_ideb_municipio.csv` — indicadores municipais do IDEB.
- `highereduc.xlsx` — distribuição da população de 18 anos ou mais por nível de instrução e município, Censo 2022.

Os três arquivos contêm registros agregados, sem identificadores pessoais. Os resultados intermediários são produzidos em `output/` e permanecem ignorados pelo Git.

A execução integral ainda depende de internet para baixar pacotes e consultar algumas APIs. Se os caches de RAIS ou resultados eleitorais não estiverem disponíveis, o script também consulta BigQuery e requer um projeto com faturamento configurado.
