<script>
  import { mappedRows, isValid } from './stores.js';

  export let formFieldName = 'addresses_data';

  $: jsonData = JSON.stringify($mappedRows);
</script>

{#if $isValid && $mappedRows.length > 0}
  <textarea
    name={formFieldName}
    style="display: none;"
    aria-hidden="true"
  >{jsonData}</textarea>
{/if}
