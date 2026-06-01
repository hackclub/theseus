<script>
  import { nonMachinable, processingCategory } from './stores.js';
  import { NON_MACHINABLE_SURCHARGE } from './constants.js';

  $: disabled = $processingCategory !== 'letter';

  // Auto-uncheck when switching to flat
  $: if (disabled) nonMachinable.set(false);
</script>

<label class="machinable-toggle" class:disabled>
  <input
    type="checkbox"
    bind:checked={$nonMachinable}
    {disabled}
  />
  <span class="toggle-label">
    Non-machinable
    <small>(letters only, +${NON_MACHINABLE_SURCHARGE.toFixed(2)} surcharge)</small>
  </span>
</label>

<style>
  .machinable-toggle {
    display: flex;
    align-items: flex-start;
    gap: 0.5rem;
    cursor: pointer;
    font-size: 0.875rem;
    color: var(--fgColor-default, var(--color-fg-default, #1f2328));
  }

  .machinable-toggle.disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  input[type='checkbox'] {
    margin-top: 0.125rem;
    accent-color: var(--borderColor-accent-emphasis, var(--color-accent-emphasis, #0969da));
  }

  .toggle-label {
    display: flex;
    flex-direction: column;
    gap: 0.125rem;
  }

  .toggle-label small {
    font-size: 0.75rem;
    color: var(--fgColor-muted, var(--color-fg-muted, #656d76));
  }
</style>
