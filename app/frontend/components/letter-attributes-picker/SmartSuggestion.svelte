<script>
  import { suggestion, processingCategory } from './stores.js';

  function switchCategory() {
    if ($suggestion) {
      processingCategory.set($suggestion.suggestedCategory);
    }
  }
</script>

{#if $suggestion}
  <div class="suggestion-banner" role="alert">
    <span class="icon">{$suggestion.suggestedCategory === 'flat' ? '\u26A0\uFE0F' : '\u{1F4A1}'}</span>
    <span class="message">{$suggestion.message}</span>
    <button type="button" class="switch-btn" on:click={switchCategory}>
      Switch to {$suggestion.suggestedCategory === 'flat' ? 'Flat' : 'Letter'}
    </button>
  </div>
{/if}

<style>
  .suggestion-banner {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.5rem 0.75rem;
    border-radius: 0.375rem;
    background: var(--bgColor-attention-muted, var(--color-attention-subtle, #fff8c5));
    border: 1px solid var(--borderColor-attention-muted, var(--color-attention-muted, #d4a72c66));
    font-size: 0.8125rem;
  }

  .icon {
    flex-shrink: 0;
  }

  .message {
    flex: 1;
    color: var(--fgColor-default, var(--color-fg-default, #1f2328));
  }

  .switch-btn {
    padding: 0.25rem 0.5rem;
    border: 1px solid var(--borderColor-default, var(--color-border-default, #d0d7de));
    border-radius: 0.375rem;
    background: var(--bgColor-default, var(--color-canvas-default, #fff));
    color: var(--fgColor-accent, var(--color-accent-fg, #0969da));
    font-size: 0.75rem;
    font-weight: 500;
    cursor: pointer;
    white-space: nowrap;
    font: inherit;
    line-height: 1.4;
  }

  .switch-btn:hover {
    background: var(--bgColor-accent-muted, var(--color-accent-subtle, #ddf4ff));
  }
</style>
