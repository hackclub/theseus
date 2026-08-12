<script>
  import { weight, processingCategory, nonMachinable } from './stores.js';
  import { NON_MACHINABLE_SURCHARGE } from './constants.js';

  // USPS domestic stamp rates (synced from USPS::PricingEngine)
  const STAMP_LETTER = [[1, 0.78], [2, 1.07], [3, 1.36], [3.5, 1.65]];
  const STAMP_FLAT   = [[1, 1.63], [2, 1.90], [3, 2.17], [4, 2.44], [5, 2.72], [6, 3.00], [7, 3.28], [8, 3.56], [9, 3.84], [10, 4.14], [11, 4.44], [12, 4.74], [13, 5.04]];
  const INDICIA_LETTER = [[1, 0.74], [2, 1.03], [3, 1.32], [3.5, 1.61]];
  const INDICIA_FLAT   = [[1, 1.63], [2, 1.90], [3, 2.17], [4, 2.44], [5, 2.72], [6, 3.00], [7, 3.28], [8, 3.56], [9, 3.84], [10, 4.14], [11, 4.44], [12, 4.74], [13, 5.04]];

  function lookup(rates, oz) {
    for (const [maxOz, price] of rates) {
      if (oz <= maxOz) return price;
    }
    return null;
  }

  function fmt(n) { return '$' + n.toFixed(2); }

  $: oz = parseFloat($weight) || 0;
  $: cat = $processingCategory;
  $: nm = $nonMachinable;

  $: stampRate = (() => {
    if (oz <= 0) return null;
    const rates = cat === 'flat' ? STAMP_FLAT : STAMP_LETTER;
    const base = lookup(rates, oz);
    if (base == null) return null;
    return (nm && cat === 'letter') ? base + NON_MACHINABLE_SURCHARGE : base;
  })();

  $: indiciaRate = (() => {
    if (oz <= 0) return null;
    const rates = cat === 'flat' ? INDICIA_FLAT : INDICIA_LETTER;
    const base = lookup(rates, oz);
    if (base == null) return null;
    return (nm && cat === 'letter') ? base + NON_MACHINABLE_SURCHARGE : base;
  })();

  $: tooHeavy = oz > 0 && stampRate == null;
</script>

{#if oz > 0}
  <div class="price-preview">
    {#if tooHeavy}
      <span class="price-over">Too heavy for {cat}</span>
    {:else}
      <span class="price-stamp" title="Stamps">{fmt(stampRate)}</span>
      {#if indiciaRate < stampRate}
        <span class="price-indicia" title="Indicia">{fmt(indiciaRate)} indicia</span>
      {/if}
    {/if}
  </div>
{/if}

<style>
  .price-preview {
    display: flex;
    align-items: baseline;
    gap: 0.5rem;
    margin-top: 0.25rem;
  }

  .price-stamp {
    font-size: 1.25em;
    font-weight: 700;
    font-variant-numeric: tabular-nums;
    color: var(--green);
  }

  .price-indicia {
    font-size: 0.85em;
    color: var(--foreground2);
    font-variant-numeric: tabular-nums;
  }

  .price-over {
    font-size: 0.85em;
    font-weight: 600;
    color: var(--red);
  }
</style>
