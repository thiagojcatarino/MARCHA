const localResearchIndex = [
  {
    id: 'mlpd-2019',
    type: 'research_edition',
    title: 'Marcha Lenta para Pés Desbravadores',
    year: 2019,
    status: 'Acervo em organização',
    summary: 'Primeiro período registrado no percurso da pesquisa. A descrição e os materiais serão vinculados após revisão do acervo.'
  },
  {
    id: 'mlpd-2022',
    type: 'research_edition',
    title: 'Marcha Lenta para Pés Desbravadores',
    year: 2022,
    status: 'Acervo em organização',
    summary: 'Segundo período registrado no percurso da pesquisa. A descrição e os materiais serão vinculados após revisão do acervo.'
  },
  {
    id: 'mlpd-2026',
    type: 'research_edition',
    title: 'Marcha Lenta para Pés Desbravadores',
    year: 2026,
    status: 'Em curso',
    summary: 'Etapa atual do percurso de pesquisa.'
  }
];

function renderResearchIndex(items) {
  const index = document.getElementById('edition-list');
  if (!index) return;

  const rows = items.map((item) => {
    const row = document.createElement('article');
    row.className = 'edition-row';
    row.dataset.id = item.id;

    const year = document.createElement('p');
    year.className = 'edition-year';
    year.textContent = item.year;

    const title = document.createElement('h3');
    title.className = 'edition-title';
    title.textContent = item.title;

    const description = document.createElement('p');
    description.className = 'edition-description';
    description.textContent = item.summary;

    const meta = document.createElement('p');
    meta.className = 'edition-meta';
    const status = document.createElement('span');
    status.textContent = item.status;
    meta.append(status, item.type.split('_').join(' '));

    row.append(year, title, description, meta);
    return row;
  });

  index.replaceChildren(...rows);
}

renderResearchIndex(localResearchIndex);

fetch('data/catalog.json')
  .then((response) => {
    if (!response.ok) throw new Error('Catálogo indisponível');
    return response.json();
  })
  .then((catalog) => renderResearchIndex(catalog.items))
  .catch(() => {});
