<script>
  import { createEventDispatcher } from 'svelte';
  import { scanHistory, stats, clearHistory } from './stores.js';

  const dispatch = createEventDispatcher();

  function formatTime(timestamp) {
    const date = new Date(timestamp);
    return date.toLocaleTimeString('en-US', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit'
    });
  }

  function getStatusScheme(status) {
    switch (status) {
      case 'success':
        return 'success';
      case 'undone':
        return 'accent';
      case 'error':
        return 'attention';
      case 'already-mailed':
        return 'danger';
      default:
        return 'secondary';
    }
  }

  function getStatusText(status) {
    switch (status) {
      case 'success':
        return 'Mailed';
      case 'undone':
        return 'Undone';
      case 'error':
        return 'Error';
      case 'already-mailed':
        return 'Duplicate';
      default:
        return status;
    }
  }

  function handleUndo(scan) {
    if (scan.letter && scan.letter.public_id) {
      dispatch('undo', { publicId: scan.letter.public_id, scanId: scan.id });
    }
  }

  function handleClearAll() {
    if (confirm('Clear all scan history?')) {
      clearHistory();
    }
  }
</script>

<div>
  <!-- Stats -->
  <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 12px; margin-bottom: 20px;">
    <div style="padding: 14px; background: var(--bgColor-default); border: 1px solid var(--borderColor-default); border-radius: 6px;">
      <div style="font-size: 11px; color: var(--fgColor-muted); margin-bottom: 4px; text-transform: uppercase; letter-spacing: 0.3px;">Total</div>
      <div style="font-size: 28px; font-weight: 600; line-height: 1;">{$stats.total}</div>
    </div>
    <div style="padding: 14px; background: var(--bgColor-success-muted); border: 1px solid var(--borderColor-success-emphasis); border-radius: 6px;">
      <div style="font-size: 11px; color: var(--fgColor-muted); margin-bottom: 4px; text-transform: uppercase; letter-spacing: 0.3px;">Mailed</div>
      <div style="font-size: 28px; font-weight: 600; line-height: 1;">{$stats.successful}</div>
    </div>
    <div style="padding: 14px; background: var(--bgColor-attention-muted); border: 1px solid var(--borderColor-attention-emphasis); border-radius: 6px;">
      <div style="font-size: 11px; color: var(--fgColor-muted); margin-bottom: 4px; text-transform: uppercase; letter-spacing: 0.3px;">Errors</div>
      <div style="font-size: 28px; font-weight: 600; line-height: 1;">{$stats.errors}</div>
    </div>
    <div style="padding: 14px; background: var(--bgColor-danger-muted); border: 1px solid var(--borderColor-danger-emphasis); border-radius: 6px;">
      <div style="font-size: 11px; color: var(--fgColor-muted); margin-bottom: 4px; text-transform: uppercase; letter-spacing: 0.3px;">Duplicates</div>
      <div style="font-size: 28px; font-weight: 600; line-height: 1;">{$stats.alreadyMailed}</div>
    </div>
  </div>

  <!-- History -->
  <div style="background: var(--bgColor-default); border: 1px solid var(--borderColor-default); border-radius: 6px; overflow: hidden;">
    <div style="padding: 12px 16px; border-bottom: 1px solid var(--borderColor-default); background: var(--bgColor-muted); display: flex; justify-content: space-between; align-items: center;">
      <h3 style="font-size: 14px; font-weight: 600; margin: 0;">Recent Scans</h3>
      {#if $scanHistory.length > 0}
        <button
          style="padding: 4px 10px; background: transparent; border: none; color: var(--fgColor-danger); font-size: 13px; cursor: pointer; font-weight: 500;"
          on:click={handleClearAll}
        >
          Clear
        </button>
      {/if}
    </div>

    <div style="max-height: 500px; overflow-y: auto;">
      {#if $scanHistory.length === 0}
        <div style="padding: 40px 16px; text-align: center; color: var(--fgColor-muted); font-size: 14px;">
          No scans yet
        </div>
      {:else}
        {#each $scanHistory as scan (scan.id)}
          <div style="padding: 12px 16px; border-bottom: 1px solid var(--borderColor-default); display: flex; flex-direction: column; gap: 6px;">
            <div style="display: flex; justify-content: space-between; align-items: center;">
              <div style="font-family: var(--fontStack-monospace); font-size: 13px; font-weight: 500; color: var(--fgColor-accent);">
                {scan.letter?.public_id || scan.publicId || 'Unknown'}
              </div>
              <div style="font-size: 12px; color: var(--fgColor-muted); font-family: var(--fontStack-monospace);">
                {formatTime(scan.timestamp)}
              </div>
            </div>

            {#if scan.letter?.display_name}
              <div style="font-size: 13px; color: var(--fgColor-default);">
                {scan.letter.display_name}
              </div>
            {/if}

            <div style="display: flex; justify-content: space-between; align-items: center; gap: 8px;">
              <span style="display: inline-block; padding: 2px 8px; background: var(--bgColor-{getStatusScheme(scan.status)}-muted); border: 1px solid var(--borderColor-{getStatusScheme(scan.status)}-emphasis); border-radius: 4px; font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.3px; color: var(--fgColor-{getStatusScheme(scan.status)});">
                {getStatusText(scan.status)}
              </span>

              {#if scan.status === 'already-mailed' || scan.status === 'success'}
                <button
                  style="padding: 4px 10px; background: transparent; border: none; color: var(--fgColor-accent); font-size: 12px; cursor: pointer; font-weight: 500; text-decoration: underline;"
                  on:click={() => handleUndo(scan)}
                >
                  Undo
                </button>
              {/if}
            </div>
          </div>
        {/each}
      {/if}
    </div>
  </div>
</div>
