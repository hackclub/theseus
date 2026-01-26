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

  function getStatusBadgeClass(status) {
    switch (status) {
      case 'success':
        return 'badge--success';
      case 'error':
        return 'badge--error';
      case 'already-mailed':
        return 'badge--angry';
      default:
        return 'badge--default';
    }
  }

  function getStatusText(status) {
    switch (status) {
      case 'success':
        return 'Success';
      case 'error':
        return 'Error';
      case 'already-mailed':
        return 'Already Mailed';
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

<div class="scan-history">
  <div class="history-header">
    <h3>Scan History</h3>
    {#if $scanHistory.length > 0}
      <button class="btn-clear" on:click={handleClearAll}>Clear All</button>
    {/if}
  </div>

  <div class="stats-grid">
    <div class="stat-card">
      <div class="stat-value">{$stats.total}</div>
      <div class="stat-label">Total</div>
    </div>
    <div class="stat-card stat-card--success">
      <div class="stat-value">{$stats.successful}</div>
      <div class="stat-label">Success</div>
    </div>
    <div class="stat-card stat-card--error">
      <div class="stat-value">{$stats.errors}</div>
      <div class="stat-label">Errors</div>
    </div>
    <div class="stat-card stat-card--angry">
      <div class="stat-value">{$stats.alreadyMailed}</div>
      <div class="stat-label">Already Mailed</div>
    </div>
  </div>

  <div class="history-list">
    {#if $scanHistory.length === 0}
      <div class="empty-state">
        No scans yet. Start scanning to see history here.
      </div>
    {:else}
      {#each $scanHistory as scan (scan.id)}
        <div class="history-item">
          <div class="item-time">{formatTime(scan.timestamp)}</div>
          <div class="item-id">{scan.letter?.public_id || scan.publicId || 'Unknown'}</div>
          <div class="item-name">{scan.letter?.display_name || '-'}</div>
          <div class="item-status">
            <span class="badge {getStatusBadgeClass(scan.status)}">
              {getStatusText(scan.status)}
            </span>
          </div>
          {#if scan.status === 'already-mailed' || scan.status === 'success'}
            <button
              class="item-undo"
              on:click={() => handleUndo(scan)}
              title="Undo"
            >
              Undo
            </button>
          {/if}
        </div>
      {/each}
    {/if}
  </div>
</div>

<style>
  .scan-history {
    display: flex;
    flex-direction: column;
    gap: 1rem;
    padding: 1rem;
    background-color: var(--bgColor-default);
    border: 1px solid var(--borderColor-default);
    border-radius: 8px;
  }

  .history-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .history-header h3 {
    margin: 0;
    font-size: 1.25rem;
    color: var(--fgColor-default);
  }

  .btn-clear {
    padding: 0.375rem 0.75rem;
    background-color: var(--bgColor-danger-muted);
    color: var(--fgColor-default);
    border: 1px solid var(--borderColor-danger-emphasis);
    border-radius: 6px;
    font-size: 0.875rem;
    cursor: pointer;
    transition: opacity 0.2s;
  }

  .btn-clear:hover {
    opacity: 0.8;
  }

  .stats-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(100px, 1fr));
    gap: 1rem;
  }

  .stat-card {
    display: flex;
    flex-direction: column;
    align-items: center;
    padding: 1rem;
    background-color: var(--bgColor-muted);
    border-radius: 6px;
    border: 2px solid var(--borderColor-default);
  }

  .stat-card--success {
    border-color: var(--borderColor-success-emphasis);
    background-color: var(--bgColor-success-muted);
  }

  .stat-card--error {
    border-color: var(--borderColor-attention-emphasis);
    background-color: var(--bgColor-attention-muted);
  }

  .stat-card--angry {
    border-color: var(--borderColor-danger-emphasis);
    background-color: var(--bgColor-danger-muted);
  }

  .stat-value {
    font-size: 2rem;
    font-weight: 700;
    color: var(--fgColor-default);
  }

  .stat-label {
    font-size: 0.875rem;
    color: var(--fgColor-muted);
  }

  .history-list {
    max-height: 400px;
    overflow-y: auto;
    border: 1px solid var(--borderColor-default);
    border-radius: 6px;
  }

  .empty-state {
    padding: 2rem;
    text-align: center;
    color: var(--fgColor-muted);
  }

  .history-item {
    display: grid;
    grid-template-columns: 100px 120px 1fr auto auto;
    gap: 1rem;
    padding: 0.75rem 1rem;
    border-bottom: 1px solid var(--borderColor-default);
    align-items: center;
    font-size: 0.875rem;
  }

  .history-item:last-child {
    border-bottom: none;
  }

  .history-item:hover {
    background-color: var(--bgColor-muted);
  }

  .item-time {
    color: var(--fgColor-muted);
    font-family: monospace;
  }

  .item-id {
    font-family: monospace;
    font-weight: 600;
    color: var(--fgColor-default);
  }

  .item-name {
    color: var(--fgColor-default);
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .item-status {
    display: flex;
    justify-content: flex-end;
  }

  .badge {
    display: inline-block;
    padding: 0.25rem 0.5rem;
    border-radius: 12px;
    font-size: 0.75rem;
    font-weight: 600;
    text-transform: uppercase;
  }

  .badge--success {
    background-color: var(--bgColor-success-emphasis);
    color: var(--fgColor-onEmphasis);
  }

  .badge--error {
    background-color: var(--bgColor-attention-emphasis);
    color: var(--fgColor-onEmphasis);
  }

  .badge--angry {
    background-color: var(--bgColor-danger-emphasis);
    color: var(--fgColor-onEmphasis);
  }

  .badge--default {
    background-color: var(--bgColor-neutral-muted);
    color: var(--fgColor-default);
  }

  .item-undo {
    padding: 0.25rem 0.5rem;
    background-color: var(--bgColor-accent-emphasis);
    color: var(--fgColor-onEmphasis);
    border: none;
    border-radius: 6px;
    font-size: 0.75rem;
    font-weight: 600;
    cursor: pointer;
    transition: opacity 0.2s;
  }

  .item-undo:hover {
    opacity: 0.8;
  }
</style>
