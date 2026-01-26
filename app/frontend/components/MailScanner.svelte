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

  $: $scannerMode = initialMode;

  onMount(() => {
    sounds = {
      success: new Howl({ src: ['/sounds/mail-scanner-success.mp3'], volume: 0.4 }),
      error: new Howl({ src: ['/sounds/mail-scanner-error.mp3'], volume: 0.4 }),
      angry: new Howl({ src: ['/sounds/mail-scanner-angry.mp3'], volume: 0.6 }),
    };

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

    $currentScan = {
      status: 'processing',
      publicId,
      letter: null,
    };

    try {
      const result = await markLetterMailed(publicId, csrfToken);

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

        $isProcessing = false;
      } else {
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

      if (scanId) {
        removeScanFromHistory(scanId);
      }

      $currentScan = {
        status: 'undone',
        publicId,
        letter: null,
      };

      addScanToHistory({
        status: 'undone',
        publicId,
        letter: null,
      });

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
    if (event.code === 'Space' && !$isProcessing) {
      if (event.target.tagName !== 'INPUT' && event.target.tagName !== 'TEXTAREA') {
        event.preventDefault();
        resetCurrentScan();
      }
    }

    if (event.code === 'Escape') {
      resetCurrentScan();
    }
  }
</script>

<svelte:window on:keydown={handleKeyboardShortcut} />

<div style="max-width: 1400px; margin: 0 auto; padding: 24px;">
  <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 24px;">
    <div>
      <h1 style="font-size: 24px; font-weight: 600; margin: 0;">Mail Scanner</h1>
      <p style="color: var(--fgColor-muted); margin: 4px 0 0; font-size: 14px;">
        Scan QR codes to mark letters as mailed
      </p>
    </div>

    <div style="display: flex; gap: 8px;">
      <button
        style="padding: 8px 14px; background: {$scannerMode === 'keyboard' ? 'var(--bgColor-accent-emphasis)' : 'var(--bgColor-default)'}; border: 1px solid {$scannerMode === 'keyboard' ? 'var(--bgColor-accent-emphasis)' : 'var(--borderColor-default)'}; border-radius: 6px; color: {$scannerMode === 'keyboard' ? 'var(--fgColor-onEmphasis)' : 'inherit'}; font-size: 14px; cursor: pointer; font-weight: 500;"
        on:click={() => switchMode('keyboard')}
      >
        Keyboard Scanner
      </button>
      <button
        style="padding: 8px 14px; background: {$scannerMode === 'webcam' ? 'var(--bgColor-accent-emphasis)' : 'var(--bgColor-default)'}; border: 1px solid {$scannerMode === 'webcam' ? 'var(--bgColor-accent-emphasis)' : 'var(--borderColor-default)'}; border-radius: 6px; color: {$scannerMode === 'webcam' ? 'var(--fgColor-onEmphasis)' : 'inherit'}; font-size: 14px; cursor: pointer; font-weight: 500;"
        on:click={() => switchMode('webcam')}
      >
        Webcam Scanner
      </button>
    </div>
  </div>

  <div style="display: grid; grid-template-columns: 1fr 380px; gap: 24px;">
    <div style="display: flex; flex-direction: column; gap: 20px;">
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

      <ScanFeedback
        bind:this={scanFeedback}
        on:undo={handleUndo}
      />
    </div>

    <div>
      <ScanHistory on:undo={handleUndo} />
    </div>
  </div>

  <div style="margin-top: 24px; padding: 12px; background: var(--bgColor-muted); border-radius: 6px; text-align: center;">
    <span style="font-size: 13px; color: var(--fgColor-muted);">
      <kbd style="padding: 2px 6px; background: var(--bgColor-default); border: 1px solid var(--borderColor-default); border-radius: 4px; font-family: monospace; font-size: 12px;">Space</kbd>
      to clear ·
      <kbd style="padding: 2px 6px; background: var(--bgColor-default); border: 1px solid var(--borderColor-default); border-radius: 4px; font-family: monospace; font-size: 12px;">Esc</kbd>
      to reset
    </span>
  </div>
</div>
