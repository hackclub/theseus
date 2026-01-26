<script>
  import { createEventDispatcher, onMount, onDestroy } from 'svelte';
  import { isProcessing } from './stores.js';
  import { extractPublicId } from './utils.js';

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

  function processBuffer() {
    clearTimeout(debounceTimer);

    if (buffer.length === 0) return;

    const publicId = extractPublicId(buffer);

    if (publicId) {
      dispatch('scan', { publicId });
    }

    buffer = '';
  }

  function handleKeydown(event) {
    if (event.target.tagName === 'INPUT' || event.target.tagName === 'TEXTAREA') {
      return;
    }

    if ($isProcessing) {
      return;
    }

    if (event.key.length === 1) {
      buffer += event.key;
    }

    if (event.key === 'Enter' && buffer.length > 0) {
      processBuffer();
      return;
    }

    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(processBuffer, 200);
  }

  function handlePaste(event) {
    if (event.target.tagName === 'INPUT' || event.target.tagName === 'TEXTAREA') {
      return;
    }

    if ($isProcessing) {
      return;
    }

    event.preventDefault();
    const pastedText = event.clipboardData.getData('text');

    if (pastedText) {
      buffer = pastedText;
      processBuffer();
    }
  }

  function attachListener() {
    document.addEventListener('keydown', handleKeydown);
    document.addEventListener('paste', handlePaste);
  }

  function detachListener() {
    document.removeEventListener('keydown', handleKeydown);
    document.removeEventListener('paste', handlePaste);
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

<div style="background: var(--bgColor-default); border: 1px solid var(--borderColor-default); border-radius: 6px; padding: 20px;">
  <div style="font-size: 14px; font-weight: 600; margin-bottom: 8px;">
    Listening for scans
  </div>
  <div style="font-size: 13px; color: var(--fgColor-muted); line-height: 1.6;">
    Scan a QR code with your barcode scanner or paste a letter URL.
  </div>
</div>
