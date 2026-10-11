// Open the research page directly on the personal GitHub Pages domain.
if (window.location.hostname === 'thiagojcatarino.github.io' && window.location.pathname === '/') {
  window.addEventListener('load', () => {
    document.getElementById('pesquisa')?.scrollIntoView({ block: 'start' });
  }, { once: true });
}
