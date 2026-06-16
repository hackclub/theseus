<script>
  import { headers, rows, mapping, usedFields, autoMapped, userModified, missingRequired, addressFields } from './stores.js';
  import { REQUIRED_FIELDS, FIELD_LABELS } from './constants.js';

  function handleChange(header, value) {
    mapping.update((m) => {
      const updated = { ...m };
      if (value) {
        updated[header] = value;
      } else {
        delete updated[header];
      }
      return updated;
    });
    userModified.update((s) => {
      const next = new Set(s);
      next.add(header);
      return next;
    });
  }

  function borderStyle(header) {
    const field = $mapping[header];
    if (!field) return '';
    if ($userModified.has(header)) return 'border-color: var(--borderColor-success-emphasis, #1a7f37);';
    if ($autoMapped.has(header)) return 'border-color: var(--borderColor-attention-emphasis, #bf8700);';
    return '';
  }

  function previewValue(header) {
    if (!$rows.length) return '';
    return $rows[0]?.[header] ?? '';
  }
</script>

<div class="mapper">
  {#if $missingRequired.length > 0}
    <div class="missing-banner">
      <strong>Missing required fields:</strong>
      {$missingRequired.map((f) => FIELD_LABELS[f] || f).join(', ')}
    </div>
  {/if}

  <div class="mapper-header">
    <span>CSV Column</span>
    <span>Maps To</span>
  </div>

  {#each $headers as header}
    <div class="mapper-row">
      <div class="csv-col">
        <span class="header-name">{header}</span>
        {#if previewValue(header)}
          <span class="preview">{previewValue(header)}</span>
        {/if}
      </div>
      <div class="field-select">
        <select
          value={$mapping[header] || ''}
          on:change={(e) => handleChange(header, e.target.value)}
          style={borderStyle(header)}
        >
          <option value="">-- skip --</option>
          {#each $addressFields as field}
            <option
              value={field}
              disabled={$usedFields.has(field) && $mapping[header] !== field}
            >
              {FIELD_LABELS[field] || field}
              {#if REQUIRED_FIELDS.includes(field)}*{/if}
            </option>
          {/each}
        </select>
      </div>
    </div>
  {/each}
</div>

<style>
  .mapper {
    display: flex;
    flex-direction: column;
    gap: 0;
  }

  .missing-banner {
    padding: 8px 12px;
    background: var(--warning-bg);
    border: 1px solid var(--warning-border);
    border-radius: 6px;
    color: var(--warning-fg);
    font-size: 13px;
    margin-bottom: 12px;
  }

  .mapper-header {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 12px;
    padding: 8px 12px;
    font-size: 12px;
    font-weight: 600;
    color: GrayText;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  .mapper-row {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 12px;
    padding: 8px 12px;
    border-top: 1px solid var(--background2);
    align-items: center;
  }

  .mapper-row:last-child {
    border-bottom: 1px solid var(--background2);
  }

  .csv-col {
    display: flex;
    flex-direction: column;
    gap: 2px;
    min-width: 0;
  }

  .header-name {
    font-weight: 600;
    font-size: 14px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .preview {
    font-size: 12px;
    color: GrayText;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  select {
    width: 100%;
    padding: 6px 8px;
    border: 2px solid var(--background2);
    border-radius: 6px;
    font-size: 14px;
    background: Canvas;
    color: inherit;
    transition: border-color 0.15s;
    cursor: pointer;
  }

  select:focus {
    outline: none;
    border-color: var(--blue);
    box-shadow: 0 0 0 3px color-mix(in srgb, var(--blue) 30%, transparent);
  }

  select option:disabled {
    color: GrayText;
  }

  @media (max-width: 540px) {
    .mapper-header,
    .mapper-row {
      grid-template-columns: 1fr;
      gap: 4px;
    }
  }
</style>
