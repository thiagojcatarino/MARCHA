# Estrutura do repositório

Árvore observada nesta versão. Arquivos locais ignorados pelo Git não aparecem.

```text
10_Site/
├── .github/workflows/pages.yml
├── assets/
│   ├── css/
│   │   ├── base/style.css
│   │   ├── components/menu.css
│   │   └── pages/home.css
│   ├── images/publicacoes/MARCHA_2026_Caderno_de_Pesquisa_Capa.png
│   ├── js/
│   │   ├── catalog.js
│   │   ├── menu.js
│   │   ├── root-landing.js
│   │   └── video-highlight.js
│   ├── publicacoes/
│   │   ├── MARCHA_2026_Caderno_de_Pesquisa.docx
│   │   └── MARCHA_2026_Caderno_de_Pesquisa.pdf
│   └── videos/IMG_2321-exposicao.m4v
├── data/
│   ├── catalog.json
│   └── README.md
├── DOC/
│   ├── README.md
│   ├── codigo-e-pesquisas.md
│   ├── estrutura-do-repositorio.md
│   ├── fluxo-editorial-e-curatorial.md
│   ├── registro-do-acervo.md
│   └── modelos/registro-de-midia.md
├── MLPD.Rproj
├── PIPELINE.md
├── [scripts R da pesquisa]
├── index.html
├── PROJECT.md
└── README.md
```

## Funções principais

- `index.html` — homepage institucional e editorial.
- `assets/css/` — estilos base, navegação e páginas.
- `assets/js/` — catálogo, navegação, destaque da homepage e mídia.
- `assets/images/` e `assets/publicacoes/` — capa, PDF e versão editável do caderno MARCHA 2026.
- `assets/videos/IMG_2321-exposicao.m4v` — vídeo de exposição em destaque.
- `data/catalog.json` — registros do catálogo público inicial.
- `DOC/` — documentação institucional, editorial, curatorial e de acervo.
- `*.R`, `MLPD.Rproj` e `PIPELINE.md` — scripts e instruções do pipeline quantitativo da Lei Paulo Gustavo, organizados na raiz.
- `.gitignore` — exclusões para arquivos temporários, dados locais e produtos de análise.
- `.github/workflows/pages.yml` — publicação do site pelo GitHub Pages.

O repositório reúne o site e o código de pesquisa, mas não contém as bases brutas nem os resultados intermediários locais.
