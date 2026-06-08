<script>
  import { onMount, onDestroy } from 'svelte';

  let cleanup;

  onMount(() => {
    function isInputFocused() {
      const el = document.activeElement;
      return el && (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA' || el.tagName === 'SELECT');
    }

    function handleKeyDown(e) {
      if (e.metaKey || e.ctrlKey) return;
      if (document.querySelector('dialog[open]')) return;

      const dataEl = document.getElementById('keyboard-shortcuts-data');
      let shortcuts = {};
      if (dataEl) {
        try { shortcuts = JSON.parse(dataEl.textContent); }
        catch { /* ignore */ }
      }

      if (e.key === 'Backspace' && !isInputFocused() && shortcuts.back) {
        e.preventDefault();
        window.location.href = shortcuts.back;
        return;
      }

      if (isInputFocused()) return;

      if (e.key === 'e' && shortcuts.edit) {
        e.preventDefault();
        window.location.href = shortcuts.edit;
        return;
      }

      if (e.key === 'n') {
        const nextLink = document.querySelector('.pagination a[rel="next"]');
        if (nextLink) { e.preventDefault(); window.location.href = nextLink.href; }
        return;
      }

      if (e.key === 'p') {
        const prevLink = document.querySelector('.pagination a[rel="prev"]');
        if (prevLink) { e.preventDefault(); window.location.href = prevLink.href; }
        return;
      }

      if (e.key === '/') {
        const searchInput = document.querySelector('input[type="search"], input[placeholder*="Search"]');
        if (searchInput) {
          e.preventDefault();
          searchInput.focus();
        }
        return;
      }
    }

    document.addEventListener('keydown', handleKeyDown);
    cleanup = () => document.removeEventListener('keydown', handleKeyDown);
  });

  onDestroy(() => cleanup?.());
</script>
