<script>
  import { width, height, processingCategory } from './stores.js';
  import { PRESETS } from './constants.js';

  $: activePreset = PRESETS.find(
    (p) => parseFloat($width) === p.width && parseFloat($height) === p.height
  ) || null;

  function apply(preset) {
    width.set(String(preset.width));
    height.set(String(preset.height));
    processingCategory.set(preset.category);
  }
</script>

<div class="preset-row">
  <span class="preset-label">Presets:</span>
  {#each PRESETS as preset}
    <button
      type="button"
      class="btn btn-tiny outlined"
      class:active={activePreset === preset}
      on:click={() => apply(preset)}
    >
      {preset.label}
    </button>
  {/each}
</div>

<style>
  .preset-row {
    display: flex;
    align-items: center;
    gap: 0.375rem;
    flex-wrap: wrap;
  }

  .preset-label {
    font-size: 0.8125rem;
    color: var(--fgColor-muted, var(--color-fg-muted, #656d76));
  }

  .btn.active {
    background: var(--bgColor-accent-muted, var(--color-accent-subtle, #ddf4ff));
    border-color: var(--borderColor-accent-emphasis, var(--color-accent-emphasis, #0969da));
    color: var(--fgColor-accent, var(--color-accent-fg, #0969da));
  }
</style>
