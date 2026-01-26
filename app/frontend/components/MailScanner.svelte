<script>
  import { onMount, onDestroy } from 'svelte';
  import { Howl } from 'howler';
  import WebcamScanner from './mail-scanner/WebcamScanner.svelte';
  import KeyboardWedgeListener from './mail-scanner/KeyboardWedgeListener.svelte';
  import ScanFeedback from './mail-scanner/ScanFeedback.svelte';
  import ScanHistory from './mail-scanner/ScanHistory.svelte';
  import { scannerMode, currentScan, isProcessing, addScanToHistory, removeScanFromHistory } from './mail-scanner/stores.js';
  import { markLetterMailed, undoMarkMailed } from './mail-scanner/api.js';

  export let csrfToken;
  export let initialMode = 'keyboard';

  let webcamScanner;
  let keyboardListener;
  let scanFeedback;
  let autoResetTimer;
  let sounds;

  // Initialize scanner mode
  $: $scannerMode = initialMode;

  // Initialize audio
  onMount(() => {
    sounds = {
      success: new Howl({ src: ['/sounds/mail-scanner-success.mp3'], volume: 0.5 }),
      error: new Howl({ src: ['/sounds/mail-scanner-error.mp3'], volume: 0.5 }),
      angry: new Howl({ src: ['/sounds/mail-scanner-angry.mp3'], volume: 0.8 }),
    };

    // Activate initial scanner
    updateScannerMode();
  });

  onDestroy(() => {
    clearTimeout(autoResetTimer);
  });

  function updateScannerMode() {
    if ($scannerMode === 'webcam') {
      keyboardListener?.deactivate();
      webcamScanner?.activate();
    } else {
      webcamScanner?.deactivate();
      keyboardListener?.activate();
    }
  }

  function switchMode(mode) {
    $scannerMode = mode;
    updateScannerMode();
  }

  function playSound(soundName) {
    if (sounds && sounds[soundName]) {
      sounds[soundName].play();
    }
  }

  function scheduleAutoReset(delay = 2000) {
    clearTimeout(autoResetTimer);
    autoResetTimer = setTimeout(() => {
      resetCurrentScan();
    }, delay);
  }

  function resetCurrentScan() {
    clearTimeout(autoResetTimer);
    $currentScan = null;
    $isProcessing = false;
  }

  async function handleScan(event) {
    const { publicId } = event.detail;

    if ($isProcessing) {
      return;
    }

    $isProcessing = true;

    // Set processing state
    $currentScan = {
      status: 'processing',
      publicId,
      letter: null,
    };

    try {
      const result = await markLetterMailed(publicId, csrfToken);

      // Success
      $currentScan = {
        status: 'success',
        publicId,
        letter: result.letter,
      };

      playSound('success');

      addScanToHistory({
        status: 'success',
        publicId,
        letter: result.letter,
      });

      scheduleAutoReset(2000);
    } catch (error) {
      if (error.type === 'already_mailed') {
        // Already mailed - ANGRY state
        $currentScan = {
          status: 'already-mailed',
          publicId,
          letter: error.letter,
        };

        playSound('angry');
        scanFeedback?.triggerAngryFlash();

        addScanToHistory({
          status: 'already-mailed',
          publicId,
          letter: error.letter,
        });

        // Don't auto-reset for already-mailed - keep visible with undo button
        $isProcessing = false;
      } else {
        // Error
        $currentScan = {
          status: 'error',
          publicId,
          letter: null,
          error: error.message || 'Unknown error',
        };

        playSound('error');

        addScanToHistory({
          status: 'error',
          publicId,
          letter: null,
          error: error.message,
        });

        scheduleAutoReset(2000);
      }
    }
  }

  async function handleUndo(event) {
    const { publicId, scanId } = event.detail;

    try {
      await undoMarkMailed(publicId, csrfToken);

      // Reset current scan
      resetCurrentScan();

      // Remove from history if scanId provided
      if (scanId) {
        removeScanFromHistory(scanId);
      }

      // Show success feedback
      $currentScan = {
        status: 'success',
        publicId,
        letter: null,
      };

      playSound('success');
      scheduleAutoReset(2000);
    } catch (error) {
      console.error('Undo failed:', error);

      $currentScan = {
        status: 'error',
        publicId,
        letter: null,
        error: 'Failed to undo',
      };

      playSound('error');
      scheduleAutoReset(2000);
    }
  }

  function handleError(event) {
    const { message } = event.detail;

    $currentScan = {
      status: 'error',
      publicId: null,
      letter: null,
      error: message,
    };

    playSound('error');
    scheduleAutoReset(2000);
  }

  function handleKeyboardShortcut(event) {
    // Space to clear/reset
    if (event.code === 'Space' && !$isProcessing) {
      if (event.target.tagName !== 'INPUT' && event.target.tagName !== 'TEXTAREA') {
        event.preventDefault();
        resetCurrentScan();
      }
    }

    // Escape to reset
    if (event.code === 'Escape') {
      resetCurrentScan();
    }
  }
</script>

<svelte:window on:keydown={handleKeyboardShortcut} />

<div class="mail-scanner">
  <div class="mail-scanner__header">
    <h1>Mail Scanner</h1>
    <div class="mode-toggle">
      <button
        class="mode-toggle__btn"
        class:mode-toggle__btn--active={$scannerMode === 'keyboard'}
        on:click={() => switchMode('keyboard')}
      >
        ⌨️ Keyboard
      </button>
      <button
        class="mode-toggle__btn"
        class:mode-toggle__btn--active={$scannerMode === 'webcam'}
        on:click={() => switchMode('webcam')}
      >
        📷 Webcam
      </button>
    </div>
  </div>

  <div class="mail-scanner__body">
    <div class="mail-scanner__main">
      <div class="scanner-container">
        {#if $scannerMode === 'webcam'}
          <WebcamScanner
            bind:this={webcamScanner}
            on:scan={handleScan}
            on:error={handleError}
          />
        {:else}
          <KeyboardWedgeListener
            bind:this={keyboardListener}
            on:scan={handleScan}
          />
        {/if}
      </div>

      <ScanFeedback
        bind:this={scanFeedback}
        on:undo={handleUndo}
      />
    </div>

    <div class="mail-scanner__sidebar">
      <ScanHistory on:undo={handleUndo} />
    </div>
  </div>

  <div class="mail-scanner__footer">
    <div class="keyboard-hints">
      <kbd>Space</kbd> Clear feedback
      <kbd>Esc</kbd> Reset
    </div>
  </div>
</div>

<style>
  .mail-scanner {
    display: flex;
    flex-direction: column;
    min-height: 100vh;
    background-color: var(--bgColor-default);
    color: var(--fgColor-default);
  }

  .mail-scanner__header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1.5rem 2rem;
    background-color: var(--bgColor-muted);
    border-bottom: 1px solid var(--borderColor-default);
  }

  .mail-scanner__header h1 {
    margin: 0;
    font-size: 1.75rem;
    font-weight: 600;
  }

  .mode-toggle {
    display: flex;
    gap: 0.5rem;
    background-color: var(--bgColor-default);
    border-radius: 6px;
    padding: 0.25rem;
  }

  .mode-toggle__btn {
    padding: 0.5rem 1rem;
    background-color: transparent;
    border: none;
    border-radius: 6px;
    cursor: pointer;
    font-size: 1rem;
    font-weight: 500;
    color: var(--fgColor-muted);
    transition: all 0.2s;
  }

  .mode-toggle__btn:hover {
    background-color: var(--bgColor-muted);
    color: var(--fgColor-default);
  }

  .mode-toggle__btn--active {
    background-color: var(--bgColor-accent-emphasis);
    color: var(--fgColor-onEmphasis);
  }

  .mail-scanner__body {
    display: grid;
    grid-template-columns: 1fr 400px;
    gap: 1rem;
    padding: 1.5rem;
    flex: 1;
  }

  @media (max-width: 1200px) {
    .mail-scanner__body {
      grid-template-columns: 1fr;
    }
  }

  .mail-scanner__main {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
  }

  .scanner-container {
    background-color: var(--bgColor-default);
    border: 1px solid var(--borderColor-default);
    border-radius: 8px;
    padding: 1rem;
  }

  .mail-scanner__sidebar {
    display: flex;
    flex-direction: column;
  }

  .mail-scanner__footer {
    padding: 1rem 2rem;
    background-color: var(--bgColor-muted);
    border-top: 1px solid var(--borderColor-default);
  }

  .keyboard-hints {
    display: flex;
    gap: 1.5rem;
    justify-content: center;
    font-size: 0.875rem;
    color: var(--fgColor-muted);
  }

  kbd {
    display: inline-block;
    padding: 0.25rem 0.5rem;
    background-color: var(--bgColor-default);
    border: 1px solid var(--borderColor-default);
    border-radius: 4px;
    font-family: monospace;
    font-size: 0.875rem;
    margin-right: 0.5rem;
  }
</style>
