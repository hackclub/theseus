<script>
  import { width, height, weight, processingCategory } from './stores.js';
  import { LETTER_LIMITS, FLAT_LIMITS, ABSOLUTE_LIMITS } from './constants.js';

  $: limits = $processingCategory === 'flat' ? FLAT_LIMITS : LETTER_LIMITS;

  $: widthNum = parseFloat($width);
  $: heightNum = parseFloat($height);
  $: weightNum = parseFloat($weight);

  $: widthError = !isNaN(widthNum) && widthNum > 0 && widthNum > ABSOLUTE_LIMITS.maxWidth
    ? `Max ${ABSOLUTE_LIMITS.maxWidth}\u2033` : null;

  $: heightError = !isNaN(heightNum) && heightNum > 0 && heightNum > ABSOLUTE_LIMITS.maxHeight
    ? `Max ${ABSOLUTE_LIMITS.maxHeight}\u2033` : null;

  $: weightError = !isNaN(weightNum) && weightNum > 0 && weightNum > limits.maxWeight
    ? `Max ${limits.maxWeight}oz` : null;
</script>

<div class="dims">
  <div class="dim-field">
    <label for="lap-width">Length</label>
    <div class="dim-input">
      <input
        id="lap-width"
        type="number"
        step="0.125"
        min="0"
        inputmode="decimal"
        class:invalid={widthError}
        bind:value={$width}
        placeholder="0"
      />
      <span class="unit">in</span>
    </div>
    {#if widthError}<span class="dim-error">{widthError}</span>{/if}
  </div>

  <span class="dim-sep">&times;</span>

  <div class="dim-field">
    <label for="lap-height">Height</label>
    <div class="dim-input">
      <input
        id="lap-height"
        type="number"
        step="0.125"
        min="0"
        inputmode="decimal"
        class:invalid={heightError}
        bind:value={$height}
        placeholder="0"
      />
      <span class="unit">in</span>
    </div>
    {#if heightError}<span class="dim-error">{heightError}</span>{/if}
  </div>

  <div class="dim-field">
    <label for="lap-weight">Weight</label>
    <div class="dim-input">
      <input
        id="lap-weight"
        type="number"
        step="0.1"
        min="0"
        inputmode="decimal"
        class:invalid={weightError}
        bind:value={$weight}
        placeholder="0"
      />
      <span class="unit">oz</span>
    </div>
    {#if weightError}<span class="dim-error">{weightError}</span>{/if}
  </div>
</div>

<style>
  .dims {
    display: flex;
    align-items: flex-end;
    gap: 0.5rem;
    flex-wrap: wrap;
  }

  .dim-field {
    display: flex;
    flex-direction: column;
    gap: 0.1875rem;
  }

  label {
    font-size: 0.6875rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.03em;
    color: var(--foreground2);
  }

  .dim-input {
    display: flex;
    align-items: center;
    border: 1px solid var(--background2);
    border-radius: 0.375rem;
    background: var(--background1);
    overflow: hidden;
    transition: border-color 0.15s, box-shadow 0.15s;
  }

  .dim-input:focus-within {
    border-color: var(--blue);
    box-shadow: 0 0 0 3px rgba(255, 255, 255, 0.1);
  }

  .dim-input:has(.invalid) {
    border-color: var(--red);
  }

  .dim-input:has(.invalid):focus-within {
    box-shadow: 0 0 0 3px rgba(255, 0, 0, 0.1);
  }

  input {
    width: 4.5rem;
    padding: 0.375rem 0.5rem;
    border: none;
    background: transparent;
    font-size: 0.875rem;
    color: var(--foreground0);
    outline: none;
    font-variant-numeric: tabular-nums;
  }

  .unit {
    padding-right: 0.5rem;
    font-size: 0.75rem;
    color: var(--foreground2);
    user-select: none;
    flex-shrink: 0;
  }

  .dim-sep {
    color: var(--foreground2);
    font-size: 0.875rem;
    padding-bottom: 0.375rem;
  }

  .dim-error {
    font-size: 0.6875rem;
    color: var(--red);
  }

  input[type='number']::-webkit-inner-spin-button,
  input[type='number']::-webkit-outer-spin-button {
    -webkit-appearance: none;
    margin: 0;
  }
  input[type='number'] {
    -moz-appearance: textfield;
  }
</style>
