<script>
  import { width, height } from './stores.js';

  // Fixed container size — never changes
  const BOX = 160;

  $: w = parseFloat($width) || 0;
  $: h = parseFloat($height) || 0;
  $: hasSize = w > 0 && h > 0;

  $: scale = hasSize ? Math.min(BOX / w, BOX / h) * 0.7 : 0;
  $: previewW = Math.max(Math.round(w * scale), 24);
  $: previewH = Math.max(Math.round(h * scale), 16);
</script>

<div class="preview-box">
  {#if hasSize}
    <div class="envelope" style="width: {previewW}px; height: {previewH}px;">
      <div class="stamp"></div>
    </div>
    <span class="dims">{w}&Prime; &times; {h}&Prime;</span>
  {:else}
    <div class="empty-envelope">
      <svg width="32" height="24" viewBox="0 0 32 24" fill="none">
        <rect x="1" y="1" width="30" height="22" rx="2" stroke="currentColor" stroke-width="1.5" stroke-dasharray="3 2"/>
        <path d="M1 1l15 11L31 1" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
      </svg>
    </div>
  {/if}
</div>

<style>
  .preview-box {
    width: 160px;
    height: 120px;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 0.375rem;
    background: var(--bgColor-muted, var(--color-canvas-subtle, #f6f8fa));
    border: 1px solid var(--borderColor-default, var(--color-border-default, #d0d7de));
    border-radius: 0.5rem;
    flex-shrink: 0;
  }

  .envelope {
    border: 1.5px solid var(--fgColor-muted, var(--color-fg-muted, #656d76));
    border-radius: 2px;
    background: var(--bgColor-default, var(--color-canvas-default, #fff));
    transition: width 0.2s ease, height 0.2s ease;
    position: relative;
  }

  .stamp {
    position: absolute;
    top: 3px;
    right: 3px;
    width: 10px;
    height: 13px;
    border: 1px dashed var(--borderColor-default, var(--color-border-default, #d0d7de));
    border-radius: 1px;
  }

  .dims {
    font-size: 0.6875rem;
    color: var(--fgColor-muted, var(--color-fg-muted, #656d76));
    font-variant-numeric: tabular-nums;
  }

  .empty-envelope {
    color: var(--borderColor-default, var(--color-border-default, #d0d7de));
  }
</style>
