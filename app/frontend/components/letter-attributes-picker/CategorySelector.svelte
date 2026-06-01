<script>
  import { processingCategory, nonMachinable } from './stores.js';
  import { LETTER_LIMITS, FLAT_LIMITS } from './constants.js';

  const categories = [
    {
      value: 'letter',
      label: 'Letter',
      desc: `up to ${LETTER_LIMITS.maxWidth}\u00D7${LETTER_LIMITS.maxHeight}\u201D, ${LETTER_LIMITS.maxWeight}oz`,
    },
    {
      value: 'flat',
      label: 'Flat',
      desc: `up to ${FLAT_LIMITS.maxWidth}\u00D7${FLAT_LIMITS.maxHeight}\u201D, ${FLAT_LIMITS.maxWeight}oz`,
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
  <div class="category-selector">
    {#each categories as cat}
      <button
        type="button"
        class="category-card"
        class:selected={$processingCategory === cat.value}
        on:click={() => select(cat.value)}
      >
        <span class="radio-dot" class:checked={$processingCategory === cat.value}></span>
        <span class="category-info">
          <strong>{cat.label}</strong>
          <small>{cat.desc}</small>
        </span>
      </button>
    {/each}
  </div>
</div>

<style>
  .category-selector {
    display: flex;
    gap: 0.5rem;
  }

  .category-card {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.5rem 0.75rem;
    border: 1px solid var(--borderColor-default, var(--color-border-default, #d0d7de));
    border-radius: 0.375rem;
    background: var(--bgColor-default, var(--color-canvas-default, #fff));
    cursor: pointer;
    transition: border-color 0.15s, background-color 0.15s;
    text-align: left;
    font: inherit;
    color: inherit;
  }

  .category-card:hover {
    border-color: var(--borderColor-accent-emphasis, var(--color-accent-emphasis, #0969da));
  }

  .category-card.selected {
    border-color: var(--borderColor-accent-emphasis, var(--color-accent-emphasis, #0969da));
    background: var(--bgColor-accent-muted, var(--color-accent-subtle, #ddf4ff));
  }

  .radio-dot {
    width: 14px;
    height: 14px;
    border-radius: 50%;
    border: 2px solid var(--borderColor-default, var(--color-border-default, #d0d7de));
    flex-shrink: 0;
    position: relative;
    transition: border-color 0.15s;
  }

  .radio-dot.checked {
    border-color: var(--borderColor-accent-emphasis, var(--color-accent-emphasis, #0969da));
  }

  .radio-dot.checked::after {
    content: '';
    position: absolute;
    top: 2px;
    left: 2px;
    width: 6px;
    height: 6px;
    border-radius: 50%;
    background: var(--borderColor-accent-emphasis, var(--color-accent-emphasis, #0969da));
  }

  .category-info {
    display: flex;
    flex-direction: column;
  }

  .category-info strong {
    font-size: 0.875rem;
  }

  .category-info small {
    color: var(--fgColor-muted, var(--color-fg-muted, #656d76));
    font-size: 0.75rem;
  }
</style>
