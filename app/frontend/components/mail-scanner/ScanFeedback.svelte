<script>
  import { createEventDispatcher } from 'svelte';
  import { currentScan } from './stores.js';

  const dispatch = createEventDispatcher();

  let showFlash = false;

  export function triggerAngryFlash() {
    showFlash = true;
    setTimeout(() => {
      showFlash = false;
    }, 1500);
  }

  function handleUndo() {
    if ($currentScan && $currentScan.letter) {
      dispatch('undo', { publicId: $currentScan.letter.public_id });
    }
  }
</script>

{#if showFlash}
  <div style="position: fixed; top: 0; left: 0; width: 100vw; height: 100vh; background-color: rgba(220, 38, 38, 0.3); z-index: 9999; animation: flash-fade 1.5s ease-out forwards; pointer-events: none;">
  </div>
{/if}

<div style="background: var(--bgColor-default); border: 1px solid var(--borderColor-default); border-radius: 6px; padding: 24px; min-height: 200px; display: flex; flex-direction: column; align-items: center; justify-content: center; {$currentScan?.status === 'success' ? 'background: var(--bgColor-success-muted); border-color: var(--borderColor-success-emphasis);' : ''} {$currentScan?.status === 'error' ? 'background: var(--bgColor-attention-muted); border-color: var(--borderColor-attention-emphasis);' : ''} {$currentScan?.status === 'already-mailed' ? 'background: var(--bgColor-danger-muted); border-color: var(--borderColor-danger-emphasis);' : ''} {$currentScan?.status === 'processing' ? 'background: var(--bgColor-accent-muted); border-color: var(--borderColor-accent-emphasis);' : ''}">

  {#if !$currentScan}
    <div style="text-align: center;">
      <div style="font-size: 14px; color: var(--fgColor-muted); margin-bottom: 8px; text-transform: uppercase; letter-spacing: 0.5px; font-weight: 600;">Ready</div>
      <div style="font-size: 16px; color: var(--fgColor-muted);">Waiting for scan...</div>
    </div>
  {:else if $currentScan.status === 'processing'}
    <div style="text-align: center;">
      <div style="font-size: 14px; color: var(--fgColor-default); margin-bottom: 8px; text-transform: uppercase; letter-spacing: 0.5px; font-weight: 600;">Processing</div>
      <div style="font-size: 16px; color: var(--fgColor-muted);">Marking {$currentScan.publicId} as mailed...</div>
    </div>
  {:else if $currentScan.status === 'success'}
    <div style="text-align: center;">
      <div style="font-size: 14px; color: var(--fgColor-success); margin-bottom: 8px; text-transform: uppercase; letter-spacing: 0.5px; font-weight: 600;">✓ Success</div>
      {#if $currentScan.letter}
        <div style="font-size: 16px; font-weight: 500; margin-bottom: 4px;">{$currentScan.letter.public_id}</div>
        {#if $currentScan.letter.display_name}
          <div style="font-size: 14px; color: var(--fgColor-muted);">{$currentScan.letter.display_name}</div>
        {/if}
        {#if $currentScan.letter.recipient}
          <div style="font-size: 13px; color: var(--fgColor-muted); margin-top: 2px;">To: {$currentScan.letter.recipient}</div>
        {/if}
      {:else}
        <div style="font-size: 16px; color: var(--fgColor-muted);">Marked as mailed</div>
      {/if}
    </div>
  {:else if $currentScan.status === 'undone'}
    <div style="text-align: center;">
      <div style="font-size: 14px; color: var(--fgColor-success); margin-bottom: 8px; text-transform: uppercase; letter-spacing: 0.5px; font-weight: 600;">✓ Undone</div>
      {#if $currentScan.publicId}
        <div style="font-size: 16px; font-weight: 500; margin-bottom: 4px;">{$currentScan.publicId}</div>
        <div style="font-size: 14px; color: var(--fgColor-muted);">Unmarked as mailed</div>
      {/if}
    </div>
  {:else if $currentScan.status === 'already-mailed'}
    <div style="text-align: center; width: 100%;">
      <div style="font-size: 14px; color: var(--fgColor-danger); margin-bottom: 12px; text-transform: uppercase; letter-spacing: 0.5px; font-weight: 600;">Already Mailed</div>
      {#if $currentScan.letter}
        <div style="margin-bottom: 16px;">
          <div style="font-size: 16px; font-weight: 500; margin-bottom: 4px;">{$currentScan.letter.public_id}</div>
          {#if $currentScan.letter.display_name}
            <div style="font-size: 14px; color: var(--fgColor-muted);">{$currentScan.letter.display_name}</div>
          {/if}
          {#if $currentScan.letter.mailed_at}
            <div style="font-size: 13px; color: var(--fgColor-muted); margin-top: 6px;">
              Mailed: {new Date($currentScan.letter.mailed_at).toLocaleString()}
            </div>
          {/if}
        </div>
      {/if}
      <button
        style="padding: 8px 16px; background: var(--bgColor-danger-emphasis); color: var(--fgColor-onEmphasis); border: none; border-radius: 6px; font-size: 14px; font-weight: 600; cursor: pointer;"
        on:click={handleUndo}
      >
        Undo Mark as Mailed
      </button>
    </div>
  {:else if $currentScan.status === 'error'}
    <div style="text-align: center;">
      <div style="font-size: 14px; color: var(--fgColor-attention); margin-bottom: 8px; text-transform: uppercase; letter-spacing: 0.5px; font-weight: 600;">⚠ Error</div>
      <div style="font-size: 14px; color: var(--fgColor-muted);">{$currentScan.error || 'Unknown error occurred'}</div>
      {#if $currentScan.publicId}
        <div style="font-size: 13px; color: var(--fgColor-muted); margin-top: 4px; font-family: var(--fontStack-monospace);">{$currentScan.publicId}</div>
      {/if}
    </div>
  {/if}
</div>

<style>
  @keyframes flash-fade {
    0% {
      opacity: 1;
    }
    100% {
      opacity: 0;
    }
  }
</style>
