const menuButton = document.getElementById('menuButton');
const closeButton = document.getElementById('closeButton');
const editorialIndex = document.getElementById('editorialIndex');
const pageWrapper = document.getElementById('pageWrapper');

function openMenu() {
  if (!menuButton || !closeButton || !editorialIndex || !pageWrapper) return;
  editorialIndex.classList.add('open');
  editorialIndex.setAttribute('aria-hidden', 'false');
  pageWrapper.classList.add('menu-open');
  menuButton.setAttribute('aria-expanded', 'true');
  closeButton.focus();
}

function closeMenu(restoreFocus = true) {
  if (!menuButton || !closeButton || !editorialIndex || !pageWrapper) return;
  editorialIndex.classList.remove('open');
  editorialIndex.setAttribute('aria-hidden', 'true');
  pageWrapper.classList.remove('menu-open');
  menuButton.setAttribute('aria-expanded', 'false');
  if (restoreFocus) menuButton.focus();
}

if (menuButton && closeButton && editorialIndex && pageWrapper) {
  editorialIndex.setAttribute('aria-hidden', 'true');
  menuButton.addEventListener('click', openMenu);
  closeButton.addEventListener('click', () => closeMenu());
  editorialIndex.querySelectorAll('a[href^="#"]').forEach((link) => {
    link.addEventListener('click', () => closeMenu(false));
  });
  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && menuButton.getAttribute('aria-expanded') === 'true') {
      closeMenu();
    }
  });
}
