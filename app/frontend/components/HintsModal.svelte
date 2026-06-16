<script>
  import { onMount, onDestroy } from 'svelte';

  let isOpen = $state(false);
  let hints = $state([]);
  let slugs = $state([]);
  let dialogEl;
  let cleanup;

  function open() {
    isOpen = true;
    dialogEl?.showModal();
    markSeen();
  }

  function close() {
    isOpen = false;
    dialogEl?.close();
  }

  async function markSeen() {
    if (slugs.length === 0) return;
    try {
      await fetch('/back_office/hints/mark_seen', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
        },
        body: JSON.stringify({ slugs })
      });
    } catch (err) {
      console.error('Failed to mark hints as seen:', err);
    }
  }

  onMount(() => {
    const dataEl = document.getElementById('hints-data');
    if (dataEl) {
      try {
        const data = JSON.parse(dataEl.textContent);
        hints = data.hints || [];
        slugs = data.slugs || [];
      } catch (err) {
        console.error('Failed to parse hints data:', err);
      }
    }

    window.openHints = open;

    function handleKeyDown(e) {
      if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA' || e.target.tagName === 'SELECT') return;
      if (e.metaKey || e.ctrlKey) return;

      if (e.key === '?') {
        e.preventDefault();
        isOpen ? close() : open();
      }
      if (e.key === 'Escape' && isOpen) {
        e.preventDefault();
        close();
      }
    }

    document.addEventListener('keydown', handleKeyDown);
    cleanup = () => document.removeEventListener('keydown', handleKeyDown);
  });

  onDestroy(() => cleanup?.());
</script>

<!-- svelte-ignore a11y_no_noninteractive_element_interactions -->
<dialog
  bind:this={dialogEl}
  id="hints-dialog"
  onclick={(e) => { if (e.target === dialogEl) close(); }}
  onkeydown={() => {}}
>
  <div class="kbar-box" id="hints-content">
    <div class="kbar-row kbar-row-between">
      <b>Keyboard shortcuts</b>
      <button class="kbar-btn" onclick={close}>×</button>
    </div>

    <hr>

    <span style="color: var(--foreground2);">Global</span>
    <div class="hints-grid">
      {#each [{ keys: ['⌘K'], action: 'command bar' }, { keys: ['?'], action: 'this dialog' }, { keys: ['/'], action: 'focus search' }, { keys: ['n'], action: 'next page' }, { keys: ['p'], action: 'prev page' }] as shortcut}
        <div class="kbar-row">
          {#each shortcut.keys as key}
            <kbd>{key}</kbd>
          {/each}
          {shortcut.action}
        </div>
      {/each}
    </div>

    {#if hints.length > 0}
      <hr>
      <span style="color: var(--foreground2);">This page</span>
      <div class="hints-grid">
        {#each hints as hint}
          {#each hint.shortcuts as shortcut}
            <div class="kbar-row">
              {#each shortcut.keys as key}
                <kbd>{key}</kbd>
              {/each}
              {shortcut.action}
            </div>
          {/each}
        {/each}
      </div>
    {/if}

    <hr>
    <div class="kbar-row" style="color: var(--foreground2);">
      <kbd>esc</kbd>
      close
    </div>
  </div>
</dialog>

<style>
  #hints-dialog {
    position: fixed;
    z-index: 1000;
    border: none;
    padding: 0;
    background: transparent;

    &::backdrop {
      backdrop-filter: grayscale(100%);
      background: rgba(0, 0, 0, 0.3);
    }
  }

  .kbar-box {
    display: flex;
    flex-direction: column;
    border: 1px solid var(--foreground2);
    border-radius: 4px;
    background: var(--background0);
    padding: 0.5rem;
    gap: 0.25rem;
  }

  #hints-content {
    min-width: 22rem;
    max-width: 32rem;
  }

  .kbar-row {
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }

  .kbar-row-between {
    justify-content: space-between;
  }

  kbd {
    font-family: monospace;
    font-size: 0.85em;
    padding: 0.1em 0.4em;
    border-radius: 3px;
    background: var(--background2);
    white-space: nowrap;
  }

  .kbar-btn {
    background: none;
    border: 1px solid var(--foreground2);
    border-radius: 3px;
    color: var(--foreground0);
    cursor: pointer;
    font-family: inherit;
    font-size: 0.85em;
    padding: 0.1em 0.4em;
    line-height: 1;
  }

  hr {
    border: none;
    border-top: 1px solid var(--background2);
    margin: 0;
    width: 100%;
  }

  .hints-grid {
    display: flex;
    flex-wrap: wrap;
    gap: 0.25rem 1rem;
    padding: 0.25rem 0;
  }
</style>
