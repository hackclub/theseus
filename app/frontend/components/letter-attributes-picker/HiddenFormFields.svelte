<script>
  import { width, height, weight, processingCategory, nonMachinable } from './stores.js';
  import { fieldName } from './constants.js';

  export let formScope = 'letter';
  export let isBatch = false;
</script>

<input type="hidden" name={fieldName(formScope, isBatch, 'width')} value={$width} />
<input type="hidden" name={fieldName(formScope, isBatch, 'height')} value={$height} />
<input type="hidden" name={fieldName(formScope, isBatch, 'weight')} value={$weight} />
<input type="hidden" name={fieldName(formScope, isBatch, 'processing_category')} value={$processingCategory} />
<input type="hidden" name={fieldName(formScope, isBatch, 'non_machinable')} value={$nonMachinable ? '1' : '0'} />
