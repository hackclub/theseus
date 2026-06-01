import "@selectize/selectize";

document.addEventListener('DOMContentLoaded', () => {
  if (document.body.classList.contains('not_prod')) {
    const devBorderOverlay = document.createElement('div');
    devBorderOverlay.className = 'dev-border-overlay';
    document.body.appendChild(devBorderOverlay);
  }
});
