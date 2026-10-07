const videoHighlight = document.querySelector('.video-highlight');
const videoHighlightClose = document.querySelector('.video-highlight-close');

videoHighlightClose?.addEventListener('click', () => {
  videoHighlight?.remove();
});
