<script>
  import { onMount } from 'svelte';
  import { width, height, weight, processingCategory, nonMachinable } from './letter-attributes-picker/stores.js';
  import CategorySelector from './letter-attributes-picker/CategorySelector.svelte';
  import DimensionInputs from './letter-attributes-picker/DimensionInputs.svelte';
  import PresetButtons from './letter-attributes-picker/PresetButtons.svelte';
  import EnvelopePreview from './letter-attributes-picker/EnvelopePreview.svelte';
  import SmartSuggestion from './letter-attributes-picker/SmartSuggestion.svelte';
  import MachinableToggle from './letter-attributes-picker/MachinableToggle.svelte';
  import HiddenFormFields from './letter-attributes-picker/HiddenFormFields.svelte';
  import PricePreview from './letter-attributes-picker/PricePreview.svelte';

  export let formScope = 'letter';
  export let isBatch = false;
  export let initialWidth = '';
  export let initialHeight = '';
  export let initialWeight = '1';
  export let initialProcessingCategory = 'letter';
  export let initialNonMachinable = false;

  onMount(() => {
    width.set(initialWidth);
    height.set(initialHeight);
    weight.set(initialWeight);
    processingCategory.set(initialProcessingCategory);
    nonMachinable.set(initialNonMachinable === true || initialNonMachinable === 'true');
  });
</script>

<div class="lap">
  <CategorySelector />

  <div class="lap-body">
    <div class="lap-controls">
      <PresetButtons />
      <DimensionInputs />
      <MachinableToggle />
      <PricePreview />
    </div>
    <div class="lap-preview">
      <span class="preview-label">Preview</span>
      <EnvelopePreview />
    </div>
  </div>

  <SmartSuggestion />
  <HiddenFormFields {formScope} {isBatch} />
</div>

<style>
  .lap {
    display: flex;
    flex-direction: column;
    gap: 0.75lh;
  }

  .lap-body {
    display: flex;
    gap: 2ch;
    align-items: flex-start;
  }

  .lap-controls {
    display: flex;
    flex-direction: column;
    gap: 0.5lh;
    flex: 1;
    min-width: 0;
  }

  .lap-preview {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 0.25lh;
    flex-shrink: 0;
  }

  .preview-label {
    font-size: 0.75em;
    color: var(--foreground2);
    text-transform: uppercase;
    letter-spacing: 0.1ch;
  }

  @media (max-width: 540px) {
    .lap-body { flex-direction: column; }
    .lap-preview { display: none; }
  }
</style>
