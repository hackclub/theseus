<script>
  import { createEventDispatcher, onMount, onDestroy } from 'svelte';
  import { isProcessing } from './stores.js';

  const dispatch = createEventDispatcher();

  let buffer = '';
  let debounceTimer;
  let isActive = false;

  $: if (isActive) {
    attachListener();
  }

  export function activate() {
    isActive = true;
  }

  export function deactivate() {
    isActive = false;
    detachListener();
  }

  function extractPublicIdFromUrl(text) {
    // Match: https://mail.hack.club/{public_id}?qr=1
    const match = text.match(/https?:\/\/mail\.hack\.club\/([^?\/\s]+)/);
    return match ? match[1] : null;
  }

  function processBuffer() {
    clearTimeout(debounceTimer);

    if (buffer.length === 0) return;

    const publicId = extractPublicIdFromUrl(buffer);

    if (publicId) {
      dispatch('scan', { publicId });
    }

    buffer = '';
  }

  function handleKeydown(event) {
    // Ignore if typing in input/textarea
    if (event.target.tagName === 'INPUT' || event.target.tagName === 'TEXTAREA') {
      return;
    }

    // Ignore if currently processing a scan
    if ($isProcessing) {
      return;
    }

    // Add character to buffer
    if (event.key.length === 1) {
      buffer += event.key;
    }

    // Process on Enter
    if (event.key === 'Enter' && buffer.length > 0) {
      processBuffer();
      return;
    }

    // Debounce processing
    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(processBuffer, 200);
  }

  function attachListener() {
    document.addEventListener('keydown', handleKeydown);
  }

  function detachListener() {
    document.removeEventListener('keydown', handleKeydown);
    clearTimeout(debounceTimer);
    buffer = '';
  }

  onMount(() => {
    if (isActive) {
      attachListener();
    }
  });

  onDestroy(() => {
    detachListener();
  });
</script>

<div class="keyboard-wedge-status">
  {#if isActive}
    <span class="status-indicator status-indicator--active"></span>
    Keyboard scanner active
  {:else}
    <span class="status-indicator status-indicator--inactive"></span>
    Keyboard scanner inactive
  {/if}
</div>

<style>
  .keyboard-wedge-status {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.5rem;
    font-size: 0.875rem;
    color: var(--fgColor-muted);
  }

  .status-indicator {
    width: 8px;
    height: 8px;
    border-radius: 50%;
  }

  .status-indicator--active {
    background-color: var(--bgColor-success-emphasis);
    box-shadow: 0 0 8px var(--bgColor-success-emphasis);
  }

  .status-indicator--inactive {
    background-color: var(--bgColor-neutral-muted);
  }
</style>
