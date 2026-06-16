<script>
  import { onMount } from 'svelte';
  import { headers, isValid, stats, rowWarnings, addressFields as addressFieldsStore } from './batch-csv-mapper/stores.js';
  import CsvDropzone from './batch-csv-mapper/CsvDropzone.svelte';
  import FieldMapper from './batch-csv-mapper/FieldMapper.svelte';
  import DataPreview from './batch-csv-mapper/DataPreview.svelte';
  import HiddenFormData from './batch-csv-mapper/HiddenFormData.svelte';

  export let addressFields = '[]';
  export let requiredFields = '[]';
  export let formFieldName = 'addresses_data';

  onMount(() => {
    const fields = typeof addressFields === 'string' ? JSON.parse(addressFields) : addressFields;
    addressFieldsStore.set(fields);
  });
</script>

<div class="batch-csv-mapper">
  <CsvDropzone />

  {#if $headers.length > 0}
    <div class="mapping-section">
      <FieldMapper />
      <DataPreview />
    </div>

    {#if !$isValid}
      <div class="validation-warning">
        Map all required fields before submitting.
      </div>
    {/if}

    {#if $rowWarnings.length > 0}
      <div class="row-warnings">
        <strong>{$rowWarnings.length} row{$rowWarnings.length !== 1 ? 's' : ''} missing required fields:</strong>
        <ul>
          {#each $rowWarnings.slice(0, 5) as warning}
            <li>Row {warning.row} ({warning.name}): missing {warning.missing.join(', ')}</li>
          {/each}
          {#if $rowWarnings.length > 5}
            <li>...and {$rowWarnings.length - 5} more</li>
          {/if}
        </ul>
      </div>
    {/if}

    {#if $isValid && $stats.valid > 0}
      <div class="ready-banner">
        Ready to import {$stats.valid} address{$stats.valid !== 1 ? 'es' : ''}.
        {#if $rowWarnings.length > 0}
          ({$rowWarnings.length} with warnings — they'll still be imported but may fail server-side validation.)
        {/if}
      </div>
    {/if}
  {/if}

  <HiddenFormData {formFieldName} />
</div>

<style>
  .batch-csv-mapper {
    display: flex;
    flex-direction: column;
    gap: 16px;
  }

  .mapping-section {
    border: 1px solid var(--background2);
    border-radius: 6px;
    padding: 16px;
    background: Canvas;
  }

  .validation-warning {
    padding: 8px 12px;
    background: var(--warning-bg);
    border: 1px solid var(--warning-border);
    border-radius: 6px;
    color: var(--warning-fg);
    font-size: 13px;
  }

  .row-warnings {
    padding: 8px 12px;
    background: var(--warning-bg);
    border: 1px solid var(--warning-border);
    border-radius: 6px;
    color: var(--warning-fg);
    font-size: 13px;
  }

  .row-warnings ul {
    margin: 4px 0 0 16px;
    padding: 0;
  }

  .row-warnings li {
    margin: 2px 0;
  }

  .ready-banner {
    padding: 8px 12px;
    background: var(--success-bg);
    border: 1px solid var(--success-border);
    border-radius: 6px;
    color: var(--success-fg);
    font-size: 13px;
    font-weight: 500;
  }
</style>
