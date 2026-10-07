# Estrutura do repositório

Árvore observada nesta versão. Diretórios sem arquivos rastreáveis aparecem como `(vazio)`; conteúdos locais ignorados ou ocultos não são enumerados.

```text
10_Site/
├── assets/
│   ├── css/
│   │   ├── base/
│   │   │   └── style.css
│   │   ├── components/
│   │   │   └── menu.css
│   │   └── pages/
│   │       └── home.css
│   ├── data/                 (vazio)
│   ├── fonts/                (vazio)
│   ├── images/               (vazio)
│   └── js/
│       ├── catalog.js
│       ├── menu.js
│       └── script.js
├── data/
│   └── catalog.json
├── pages/                    (vazio)
├── DOC/
│   ├── README.md
│   ├── estrutura-do-repositorio.md
│   ├── fluxo-editorial-e-curatorial.md
│   ├── registro-do-acervo.md
│   └── modelos/
│       └── registro-de-midia.md
├── index.html
├── PROJECT.md
└── README.md
```

## Funções principais

- `index.html` — documento da homepage, com as seções editoriais e os pontos de entrada para pesquisa e acervo.
- `assets/css/base/style.css` — estilos globais, tipografia e regras de base.
- `assets/css/components/menu.css` — aparência e comportamento visual da navegação.
- `assets/css/pages/home.css` — composição e estilos específicos da homepage.
- `assets/js/menu.js` — interação do menu de navegação.
- `assets/js/catalog.js` — lógica de apresentação do catálogo/índice.
- `assets/js/script.js` — script adicional da interface; sua função deve ser descrita com mais detalhe quando confirmada na revisão de código.
- `data/catalog.json` — dados estruturados do catálogo inicial exibido pelo site.
- `assets/data/`, `assets/fonts/`, `assets/images/` e `pages/` — diretórios disponíveis, ainda sem arquivos rastreáveis nesta árvore.
- `PROJECT.md` — propósito, arquitetura, princípios técnicos e orientação de organização do projeto.
- `README.md` — apresentação breve e instruções para abrir o protótipo localmente.
- `DOC/` — documentação de trabalho editorial, curatorial e de acervo.

Esta árvore descreve o repositório do site, não a totalidade do acervo de origem. Materiais originais podem permanecer fora dele até inventário, seleção e decisão de destino.
