<script>
  import { processingCategory, nonMachinable } from './stores.js';
  import { LETTER_LIMITS, FLAT_LIMITS } from './constants.js';

  const categories = [
    {
      value: 'letter',
      label: 'Letter',
      desc: `up to ${LETTER_LIMITS.maxWidth}×${LETTER_LIMITS.maxHeight}″, ${LETTER_LIMITS.maxWeight}oz`,
    },
    {
      value: 'flat',
      label: 'Flat',
      desc: `up to ${FLAT_LIMITS.maxWidth}×${FLAT_LIMITS.maxHeight}″, ${FLAT_LIMITS.maxWeight}oz`,
    },
  ];

  function select(value) {
    processingCategory.set(value);
    if (value === 'flat') {
      nonMachinable.set(false);
    }
  }
</script>

<div class="form-group">
  <label class="form-label">Processing Category</label>
  <div class="segmented">
    {#each categories as cat}
      <button
        type="button"
        class="segment"
        class:selected={$processingCategory === cat.value}
        on:click={() => select(cat.value)}
      >
        <strong>{cat.label}</strong>
        <small>{cat.desc}</small>
      </button>
    {/each}
  </div>
</div>

<style>
  .form-group { margin-bottom: 1lh; }
  .form-label {
    display: block;
    color: var(--foreground2);
    margin-bottom: 0.25lh;
  }

  .segmented {
    display: flex;
    gap: 0;
  }

  .segment {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 0;
    padding: 0.25lh 1ch;
    border: 1px solid var(--background2);
    background: var(--background0);
    color: var(--foreground2);
    cursor: pointer;
    text-align: left;
    font: inherit;
    transition: all 0.1s;
  }

  .segment:first-child { border-radius: 4px 0 0 4px; }
  .segment:last-child { border-radius: 0 4px 4px 0; border-left: none; }

  .segment:hover:not(.selected) {
    background: var(--background1);
    color: var(--foreground1);
  }

  .segment.selected {
    background: var(--background2);
    border-color: var(--foreground2);
    color: var(--foreground0);
  }

  .segment strong {
    font-size: 0.9em;
  }

  .segment small {
    font-size: 0.75em;
    color: var(--foreground2);
  }

  .segment.selected small {
    color: var(--foreground1);
  }
</style>
