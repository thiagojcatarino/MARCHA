# MARCHA

MARCHA é uma plataforma editorial, museu e arquivo de pesquisa. Este repositório reúne o site institucional e o código da pesquisa sobre a Lei Paulo Gustavo.

## Site institucional

O site é estático e usa HTML, CSS, JavaScript e JSON, sem framework ou etapa de compilação. Para visualizar localmente, abra `index.html` ou sirva a pasta por HTTP para carregar o catálogo de `data/catalog.json`.

- `index.html` — homepage editorial;
- `assets/` — estilos, scripts, imagens, publicações e mídia;
- `data/catalog.json` — catálogo inicial da MLPD;
- `DOC/` — documentação do site e do acervo.

## Pesquisa da Lei Paulo Gustavo

Os scripts R ficam na raiz do projeto, junto de `MLPD.Rproj`. A sequência de execução, os produtos esperados e as pendências de reprodução estão descritos em [`PIPELINE.md`](PIPELINE.md). O código depende de insumos locais em `data/`, pacotes R e, em algumas etapas, serviços externos. Não inclua bases brutas ou resultados intermediários sem revisar origem, licença e tamanho; os arquivos locais de entrada e a pasta `output/` são ignorados pelo Git.

## Publicação

O site é publicado pelo GitHub Pages via `.github/workflows/pages.yml`. Os scripts R e os dados de trabalho permanecem no repositório, mas não fazem parte do artefato do site.
