<script>
  import { createEventDispatcher } from 'svelte';
  import { currentScan } from './stores.js';

  const dispatch = createEventDispatcher();

  let showFlash = false;

  export function triggerAngryFlash() {
    showFlash = true;
    setTimeout(() => {
      showFlash = false;
    }, 1000);
  }

  function handleUndo() {
    if ($currentScan && $currentScan.letter) {
      dispatch('undo', { publicId: $currentScan.letter.public_id });
    }
  }

  function getStatusClass() {
    if (!$currentScan) return 'idle';
    return $currentScan.status;
  }

  function getStatusIcon() {
    if (!$currentScan) return '';
    switch ($currentScan.status) {
      case 'processing':
        return '⏳';
      case 'success':
        return '✓';
      case 'error':
        return '⚠';
      case 'already-mailed':
        return '🚫';
      default:
        return '';
    }
  }

  function getStatusMessage() {
    if (!$currentScan) return 'Ready to scan';

    switch ($currentScan.status) {
      case 'processing':
        return 'Processing...';
      case 'success':
        return 'Successfully marked as mailed!';
      case 'error':
        return $currentScan.error || 'Error occurred';
      case 'already-mailed':
        return 'ALREADY MAILED';
      default:
        return 'Ready to scan';
    }
  }
</script>

{#if showFlash}
  <div class="screen-flash-red"></div>
{/if}

<div class="scan-feedback scan-feedback--{getStatusClass()}">
  <div class="status-icon">
    {getStatusIcon()}
  </div>

  <div class="status-message">
    {getStatusMessage()}
  </div>

  {#if $currentScan && $currentScan.letter}
    <div class="letter-details">
      <div class="detail-row">
        <span class="detail-label">ID:</span>
        <span class="detail-value">{$currentScan.letter.public_id}</span>
      </div>
      {#if $currentScan.letter.display_name}
        <div class="detail-row">
          <span class="detail-label">Letter:</span>
          <span class="detail-value">{$currentScan.letter.display_name}</span>
        </div>
      {/if}
      {#if $currentScan.letter.recipient}
        <div class="detail-row">
          <span class="detail-label">To:</span>
          <span class="detail-value">{$currentScan.letter.recipient}</span>
        </div>
      {/if}
    </div>
  {/if}

  {#if $currentScan && $currentScan.status === 'already-mailed'}
    <button class="undo-button" on:click={handleUndo}>
      Undo Mark as Mailed
    </button>
  {/if}
</div>

<style>
  .screen-flash-red {
    position: fixed;
    top: 0;
    left: 0;
    width: 100vw;
    height: 100vh;
    background-color: rgba(255, 0, 0, 0.6);
    z-index: 9999;
    animation: flash-fade 1s ease-out forwards;
    pointer-events: none;
  }

  @keyframes flash-fade {
    0% {
      opacity: 1;
    }
    100% {
      opacity: 0;
    }
  }

  .scan-feedback {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 2rem;
    border-radius: 8px;
    min-height: 300px;
    transition: all 0.3s ease;
  }

  .scan-feedback--idle {
    background-color: var(--bgColor-muted);
    border: 2px dashed var(--borderColor-default);
  }

  .scan-feedback--processing {
    background-color: var(--bgColor-accent-muted);
    border: 2px solid var(--borderColor-accent-emphasis);
  }

  .scan-feedback--success {
    background-color: var(--bgColor-success-muted);
    border: 2px solid var(--borderColor-success-emphasis);
  }

  .scan-feedback--error {
    background-color: var(--bgColor-attention-muted);
    border: 2px solid var(--borderColor-attention-emphasis);
  }

  .scan-feedback--already-mailed {
    background-color: var(--bgColor-danger-muted);
    border: 2px solid var(--borderColor-danger-emphasis);
    animation: pulse 0.5s ease-in-out;
  }

  @keyframes pulse {
    0%, 100% {
      transform: scale(1);
    }
    50% {
      transform: scale(1.02);
    }
  }

  .status-icon {
    font-size: 4rem;
    margin-bottom: 1rem;
  }

  .status-message {
    font-size: 1.5rem;
    font-weight: 600;
    text-align: center;
    color: var(--fgColor-default);
    margin-bottom: 1rem;
  }

  .letter-details {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
    margin-top: 1rem;
    padding: 1rem;
    background-color: var(--bgColor-default);
    border-radius: 6px;
    width: 100%;
    max-width: 500px;
  }

  .detail-row {
    display: flex;
    gap: 0.5rem;
  }

  .detail-label {
    font-weight: 600;
    color: var(--fgColor-muted);
    min-width: 60px;
  }

  .detail-value {
    color: var(--fgColor-default);
    word-break: break-word;
  }

  .undo-button {
    margin-top: 1rem;
    padding: 0.75rem 1.5rem;
    background-color: var(--bgColor-danger-emphasis);
    color: var(--fgColor-onEmphasis);
    border: none;
    border-radius: 6px;
    font-size: 1rem;
    font-weight: 600;
    cursor: pointer;
    transition: opacity 0.2s;
  }

  .undo-button:hover {
    opacity: 0.9;
  }

  .undo-button:active {
    transform: scale(0.98);
  }
</style>
