<script>
  import { onMount, onDestroy } from 'svelte';

  let dialogEl;
  let inputEl;
  let resultsContainerEl;
  let cleanup;

  let shortcuts = $state([]);
  let prefixes = $state({});
  let searchScopes = $state([]);
  let query = $state('');
  let activeScope = $state(null);
  let scopedResults = $state([]);
  let publicIdResult = $state(null);
  let activeIndex = $state(0);

  let scopedSearchTimeout;
  let publicIdTimeout;

  const scopeShortcuts = { '?l': 'letters', '?w': 'orders' };

  let visibleItems = $derived(computeVisibleItems());

  $effect(() => {
    query;
    scopedResults;
    publicIdResult;
    activeIndex = 0;
  });

  function open() {
    query = '';
    activeScope = null;
    scopedResults = [];
    publicIdResult = null;
    activeIndex = 0;
    dialogEl?.showModal();
    setTimeout(() => inputEl?.focus(), 10);
  }

  function close() {
    dialogEl?.close();
    query = '';
  }

  function computeVisibleItems() {
    const items = [];

    if (activeScope) {
      if (scopedResults.length > 0) {
        scopedResults.forEach(r => items.push({ label: r.label, sublabel: r.sublabel, icon: '⭢', path: r.path }));
      } else if (query.length >= 2) {
        items.push({ label: 'No results', disabled: true });
      } else {
        items.push({ label: `Type to search ${activeScope.label}...`, disabled: true });
      }
      return items;
    }

    if (publicIdResult) {
      if (publicIdResult.notFound) {
        items.push({ label: `${publicIdResult.model} not found`, icon: '✕', disabled: true });
      } else if (publicIdResult.data) {
        items.push({
          label: `Go to ${publicIdResult.model}`,
          sublabel: [publicIdResult.data.label, publicIdResult.data.sublabel].filter(Boolean).join(' · '),
          icon: '⭢',
          path: publicIdResult.data.path,
        });
      } else {
        items.push({ label: `Looking up ${publicIdResult.model}...`, icon: '⭢', disabled: true });
      }
    }

    const q = query.toLowerCase();
    const filtered = q
      ? shortcuts.filter(s => {
          const code = s.code.toLowerCase();
          const label = s.label.toLowerCase();
          if (code.includes(q) || label.includes(q)) return true;
          // fuzzy: match if all query chars appear in order in the label
          let ci = 0;
          for (const ch of label) {
            if (ch === q[ci]) ci++;
            if (ci === q.length) return true;
          }
          return false;
        })
      : shortcuts;

    // sort: exact code match first, then code startsWith, then label includes, then fuzzy
    const scored = filtered.map(s => {
      const code = s.code.toLowerCase();
      const label = s.label.toLowerCase();
      let score = 0;
      if (q) {
        if (code === q) score = 100;
        else if (code.startsWith(q)) score = 80;
        else if (code.includes(q)) score = 60;
        else if (label.startsWith(q)) score = 50;
        else if (label.includes(q)) score = 40;
        else score = 20; // fuzzy match
      }
      return { s, score };
    });
    scored.sort((a, b) => b.score - a.score);
    scored.forEach(({ s }) => items.push({ label: s.label, code: s.code, icon: s.icon, path: s.path, shortcut: s }));

    if (!publicIdResult) {
      const filteredScopes = q
        ? searchScopes.filter(s => s.label.toLowerCase().includes(q) || 'search'.includes(q))
        : searchScopes;
      filteredScopes.forEach(s => {
        const hint = Object.entries(scopeShortcuts).find(([, v]) => v === s.key)?.[0];
        items.push({ label: `Search ${s.label}`, hint, icon: '⌕', scope: s });
      });
    }

    return items;
  }

  function selectItem(item) {
    if (item.disabled) return;

    if (item.scope) {
      activeScope = item.scope;
      query = '';
      scopedResults = [];
      setTimeout(() => inputEl?.focus(), 0);
      return;
    }

    if (item.path) {
      close();
      window.location.href = item.path;
    }
  }

  function handleInput() {
    const q = query;

    const scopeKey = scopeShortcuts[q.toLowerCase()];
    if (scopeKey) {
      const scope = searchScopes.find(s => s.key === scopeKey);
      if (scope) {
        activeScope = scope;
        query = '';
        scopedResults = [];
        return;
      }
    }

    if (activeScope && q.length >= 2) {
      doScopedSearch(q, activeScope.key);
    } else if (activeScope) {
      scopedResults = [];
    }

    if (q.includes('!')) {
      const [prefix] = q.toLowerCase().split('!');
      const prefixData = prefixes[prefix];
      if (prefixData) {
        doPublicIdLookup(q, prefixData);
      } else {
        publicIdResult = null;
      }
    } else {
      publicIdResult = null;
      if (publicIdTimeout) clearTimeout(publicIdTimeout);
    }
  }

  function handleKeyDown(e) {
    if (e.key === 'Escape' || (e.key === 'c' && e.ctrlKey)) {
      e.preventDefault();
      if (activeScope) {
        activeScope = null;
        query = '';
        scopedResults = [];
      } else {
        close();
      }
      return;
    }

    if (e.key === 'Backspace' && query === '' && activeScope) {
      e.preventDefault();
      activeScope = null;
      scopedResults = [];
      return;
    }

    if (e.key === 'ArrowDown' || (e.key === 'n' && e.ctrlKey)) {
      e.preventDefault();
      activeIndex = Math.min(activeIndex + 1, visibleItems.length - 1);
      scrollToActive();
      return;
    }

    if (e.key === 'ArrowUp' || (e.key === 'p' && e.ctrlKey)) {
      e.preventDefault();
      activeIndex = Math.max(activeIndex - 1, 0);
      scrollToActive();
      return;
    }

    if (e.key === 'Enter') {
      e.preventDefault();
      const item = visibleItems[activeIndex];
      if (item) selectItem(item);
    }
  }

  function scrollToActive() {
    const el = resultsContainerEl?.querySelector('.active');
    if (el) el.scrollIntoView({ block: 'nearest' });
  }

  async function doScopedSearch(q, scopeKey) {
    if (scopedSearchTimeout) clearTimeout(scopedSearchTimeout);
    scopedSearchTimeout = setTimeout(async () => {
      try {
        const res = await fetch(`/back_office/kbar/search?q=${encodeURIComponent(q)}&scope=${scopeKey}`);
        if (!res.ok) throw new Error('Search failed');
        scopedResults = await res.json();
      } catch (err) {
        console.error('Scoped search failed:', err);
        scopedResults = [];
      }
    }, 150);
  }

  async function doPublicIdLookup(q, prefixData) {
    const hashPart = q.split('!')[1] || '';
    if (hashPart.length < 3) {
      publicIdResult = { model: prefixData.model, notFound: true };
      return;
    }

    publicIdResult = { model: prefixData.model, loading: true };
    if (publicIdTimeout) clearTimeout(publicIdTimeout);
    publicIdTimeout = setTimeout(async () => {
      try {
        const res = await fetch(`/back_office/kbar/search?q=${encodeURIComponent(q)}`);
        if (!res.ok) return;
        const results = await res.json();
        publicIdResult = results.length > 0
          ? { model: prefixData.model, data: results[0] }
          : { model: prefixData.model, notFound: true };
      } catch (err) {
        console.error('Public ID lookup failed:', err);
        publicIdResult = { model: prefixData.model, notFound: true };
      }
    }, 100);
  }

  onMount(() => {
    const dataEl = document.getElementById('kbar-data');
    if (dataEl) {
      try {
        const data = JSON.parse(dataEl.textContent);
        shortcuts = data.shortcuts || [];
        prefixes = data.prefixes || {};
        searchScopes = data.searchScopes || [];
      } catch (err) {
        console.error('Failed to parse kbar data:', err);
      }
    }

    window.openKbar = open;
    window.closeKbar = close;

    function globalKeyDown(e) {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        dialogEl?.open ? close() : open();
      }
    }

    document.addEventListener('keydown', globalKeyDown);
    cleanup = () => document.removeEventListener('keydown', globalKeyDown);
  });

  onDestroy(() => cleanup?.());
</script>

<!-- svelte-ignore a11y_no_noninteractive_element_interactions -->
<dialog bind:this={dialogEl} id="command-palette" onclick={(e) => { if (e.target === dialogEl) close(); }} onkeydown={() => {}}>
  <div class="kbar-box" id="palette-content">
    <div class="kbar-row kbar-row-between">
      <kbd>⌘K Go anywhere</kbd>
      {#if activeScope}
        <div class="kbar-row">
          <span class="kbar-badge kbar-badge-blue">{activeScope.label}</span>
          <button class="kbar-btn" onclick={() => { activeScope = null; query = ''; scopedResults = []; }}>×</button>
        </div>
      {:else}
        <button class="kbar-btn" onclick={close}>×</button>
      {/if}
    </div>

    <div class="kbar-row" id="palette-search-row">
      <span style="color: var(--foreground2);">⌕</span>
      <input bind:this={inputEl} id="palette-input" placeholder={activeScope ? `Search ${activeScope.label}...` : 'Search or type a shortcode...'} autocomplete="off" bind:value={query} oninput={handleInput} onkeydown={handleKeyDown} />
    </div>
    <hr>

    <div id="palette-results">
      <div id="palette-results-container" bind:this={resultsContainerEl}>
        {#each visibleItems as item, i}
          <a class="palette-result" class:active={i === activeIndex} class:disabled={item.disabled} href={item.path || '#'} tabindex="0" onclick={(e) => { e.preventDefault(); selectItem(item); }} onmouseenter={() => { activeIndex = i; }}>
            <span class="palette-result-icon">{item.icon || '·'}</span>
            <span class="palette-result-text">
              {item.label}
              {#if item.sublabel}
                <span class="palette-result-sub">{item.sublabel}</span>
              {/if}
            </span>
            {#if item.code}
              <kbd>{item.code}</kbd>
            {/if}
            {#if item.hint}
              <span style="color: var(--foreground2);">{item.hint}</span>
            {/if}
          </a>
        {/each}
      </div>
    </div>

    <div class="kbar-row kbar-footer" style="color: var(--foreground2);">
      <div class="kbar-row">
        <kbd>↑</kbd>
        <kbd>↓</kbd>
        <span>navigate</span>
      </div>
      <div class="kbar-row">
        <kbd>↵</kbd>
        <span>select</span>
      </div>
      <div class="kbar-row">
        <kbd>esc</kbd>
        <span>close</span>
      </div>
    </div>
  </div>
</dialog>

<style>
  #command-palette {
    position: fixed;
    z-index: 1000;
    border: none;
    padding: 0;
    background: transparent;
    max-width: 40rem;
    width: 100%;
    max-height: 70vh;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
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
    overflow: hidden;
  }
  .kbar-row {
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }
  .kbar-row-between {
    justify-content: space-between;
    padding: 0.5rem;
  }
  .kbar-footer {
    gap: 1rem;
    justify-content: center;
    padding: 0.5rem 0;
  }
  kbd {
    font-family: monospace;
    font-size: 0.85em;
    padding: 0.1em 0.4em;
    border-radius: 3px;
    background: var(--background2);
    white-space: nowrap;
  }
  .kbar-badge {
    font-family: monospace;
    font-size: 0.85em;
    padding: 0.1em 0.4em;
    border-radius: 3px;
    background: var(--background2);
  }
  .kbar-badge-blue {
    background: var(--blue, #2563eb);
    color: white;
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
  }
  #palette-content {
    max-height: 70vh;
  }
  #palette-search-row {
    padding: 0 0.5rem;
  }
  #palette-input {
    background-color: var(--background0);
    border: none;
    flex: 1;
    outline: none;
    font-family: inherit;
    font-size: inherit;
    color: var(--foreground0);
  }
  #palette-results {
    flex-grow: 1;
    overflow: hidden;
    position: relative;
  }
  #palette-results-container {
    overflow-y: auto;
    max-height: 50vh;
    padding: 0 0.5rem;
  }
  .palette-result {
    text-decoration: none;
    color: var(--foreground1);
    display: flex;
    align-items: center;
    padding: 0 0.5rem;
    gap: 0.5rem;
    &.active {
      background-color: var(--background1);
      color: var(--foreground0);
    }
    &.disabled {
      color: var(--foreground2);
      pointer-events: none;
    }
  }
  .palette-result-icon {
    flex-shrink: 0;
    width: 1rem;
    text-align: center;
    color: var(--foreground2);
  }
  .palette-result-text {
    flex: 1;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  .palette-result-sub {
    color: var(--foreground2);
    margin-left: 0.5rem;
  }
</style>