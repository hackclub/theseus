<script>
  import { previewRows, stats, mapping, isValid } from './stores.js';
  import { FIELD_LABELS, REQUIRED_FIELDS } from './constants.js';

  $: activeFields = Object.values($mapping).filter(Boolean);

  function isMissing(row, field) {
    return REQUIRED_FIELDS.includes(field) && (!row[field] || row[field].trim() === '');
  }
</script>

{#if $previewRows.length > 0}
  <div class="preview-section">
    <div class="preview-header">
      <h3>Preview</h3>
      <span class="stats">
        {$stats.valid} valid row{$stats.valid !== 1 ? 's' : ''}
        {#if $stats.skipped > 0}
          <span class="skipped">({$stats.skipped} skipped — missing first name)</span>
        {/if}
      </span>
    </div>

    <div class="table-wrap">
      <table>
        <thead>
          <tr>
            {#each activeFields as field}
              <th>{FIELD_LABELS[field] || field}</th>
            {/each}
          </tr>
        </thead>
        <tbody>
          {#each $previewRows as row}
            <tr>
              {#each activeFields as field}
                <td class:empty={!row[field]} class:missing={isMissing(row, field)}>{row[field] || '—'}</td>
              {/each}
            </tr>
          {/each}
        </tbody>
      </table>
    </div>

    {#if $stats.total > 5}
      <div class="more">and {$stats.valid - 5} more row{$stats.valid - 5 !== 1 ? 's' : ''}...</div>
    {/if}
  </div>
{/if}

<style>
  .preview-section {
    margin-top: 16px;
  }

  .preview-header {
    display: flex;
    justify-content: space-between;
    align-items: baseline;
    margin-bottom: 8px;
  }

  h3 {
    margin: 0;
    font-size: 14px;
    font-weight: 600;
  }

  .stats {
    font-size: 13px;
    color: var(--fgColor-muted, #656d76);
  }

  .skipped {
    color: var(--fgColor-attention, #9a6700);
  }

  .table-wrap {
    overflow-x: auto;
    border: 1px solid var(--borderColor-default, #d1d5db);
    border-radius: 6px;
  }

  table {
    width: 100%;
    border-collapse: collapse;
    font-size: 13px;
  }

  th {
    text-align: left;
    padding: 6px 10px;
    background: var(--bgColor-muted, #f6f8fa);
    font-weight: 600;
    font-size: 12px;
    color: var(--fgColor-muted, #656d76);
    white-space: nowrap;
    border-bottom: 1px solid var(--borderColor-default, #d1d5db);
  }

  td {
    padding: 6px 10px;
    border-bottom: 1px solid var(--borderColor-muted, #d8dee4);
    white-space: nowrap;
    max-width: 200px;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  td.empty {
    color: var(--fgColor-muted, #656d76);
  }

  td.missing {
    background: var(--bgColor-danger-muted, #ffebe9);
    color: var(--fgColor-danger, #d1242f);
    font-weight: 500;
  }

  tr:last-child td {
    border-bottom: none;
  }

  .more {
    padding: 8px;
    text-align: center;
    font-size: 12px;
    color: var(--fgColor-muted, #656d76);
  }
</style>
