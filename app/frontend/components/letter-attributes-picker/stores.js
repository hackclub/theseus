import { writable, derived } from 'svelte/store';
import { LETTER_LIMITS } from './constants.js';

// Core state
export const width = writable('');
export const height = writable('');
export const weight = writable('1');
export const processingCategory = writable('letter');
export const nonMachinable = writable(false);

// Whether dimensions exceed letter limits
export const exceedsLetterLimits = derived(
  [width, height],
  ([$width, $height]) => {
    const w = parseFloat($width);
    const h = parseFloat($height);
    if (isNaN(w) && isNaN(h)) return false;
    return (
      (!isNaN(w) && w > LETTER_LIMITS.maxWidth) ||
      (!isNaN(h) && h > LETTER_LIMITS.maxHeight)
    );
  }
);

// Whether dimensions fit within letter limits
export const fitsLetterLimits = derived(
  [width, height],
  ([$width, $height]) => {
    const w = parseFloat($width);
    const h = parseFloat($height);
    if (isNaN(w) || isNaN(h)) return true;
    return w <= LETTER_LIMITS.maxWidth && h <= LETTER_LIMITS.maxHeight;
  }
);

// Smart suggestion: detect mismatch between selected category and dimensions
export const suggestion = derived(
  [processingCategory, exceedsLetterLimits, fitsLetterLimits, width, height],
  ([$category, $exceeds, $fits, $width, $height]) => {
    const w = parseFloat($width);
    const h = parseFloat($height);
    // Don't suggest anything if no dimensions entered
    if (isNaN(w) || isNaN(h)) return null;

    if ($category === 'letter' && $exceeds) {
      return { suggestedCategory: 'flat', message: 'These dimensions exceed letter limits.' };
    }
    if ($category === 'flat' && $fits && w <= LETTER_LIMITS.maxWidth && h <= LETTER_LIMITS.maxHeight) {
      return { suggestedCategory: 'letter', message: 'These dimensions fit within letter limits.' };
    }
    return null;
  }
);
