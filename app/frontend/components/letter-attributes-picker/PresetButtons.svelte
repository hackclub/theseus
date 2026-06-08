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
    gap: 0.5ch;
    flex-wrap: wrap;
  }

  .preset-label {
    font-size: 0.85em;
    color: var(--foreground2);
  }

  .btn {
    padding: 0 1ch;
    height: 1.5lh;
    border: 1px solid var(--background2);
    border-radius: 4px;
    background: var(--background1);
    color: var(--foreground1);
    font: inherit;
    font-size: 0.9em;
    cursor: pointer;
    transition: all 0.1s;
  }

  .btn:hover {
    background: var(--background2);
    color: var(--foreground0);
    border-color: var(--foreground2);
  }

  .btn.active {
    background: var(--background2);
    border-color: var(--blue);
    color: var(--foreground0);
    font-weight: bold;
  }
</style>
