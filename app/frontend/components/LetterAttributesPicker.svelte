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
    </div>
    <EnvelopePreview />
  </div>

  <SmartSuggestion />
  <HiddenFormFields {formScope} {isBatch} />
</div>

<style>
  .lap {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
  }

  .lap-body {
    display: flex;
    gap: 1.25rem;
    align-items: flex-start;
  }

  .lap-controls {
    display: flex;
    flex-direction: column;
    gap: 0.625rem;
    flex: 1;
    min-width: 0;
  }

  @media (max-width: 540px) {
    .lap-body {
      flex-direction: column;
    }
  }
</style>
