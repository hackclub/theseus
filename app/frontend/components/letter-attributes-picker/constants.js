// USPS mail classification limits and presets

export const LETTER_LIMITS = {
  maxWidth: 11.5,
  maxHeight: 6.125,
  minWidth: 5,
  minHeight: 3.5,
  maxWeight: 3.5, // oz
};

export const FLAT_LIMITS = {
  maxWidth: 15,
  maxHeight: 12,
  minWidth: 11.5,
  minHeight: 6.125,
  maxWeight: 13, // oz
};

export const ABSOLUTE_LIMITS = {
  maxWidth: 15,
  maxHeight: 12,
  maxWeight: 13,
  minWidth: 3.5,
  minHeight: 3.5,
  minWeight: 0,
};

export const NON_MACHINABLE_SURCHARGE = 0.49;

export const PRESETS = [
  { label: '5x7', width: 7, height: 5, category: 'letter' },
  { label: '#10', width: 9.5, height: 4.125, category: 'letter' },
  { label: '9x12', width: 12, height: 9, category: 'flat' },
  { label: '10x13', width: 13, height: 10, category: 'flat' },
];

// Field name helpers for Rails form integration
export function fieldName(formScope, isBatch, field) {
  const prefix = isBatch ? 'letter_' : '';
  return `${formScope}[${prefix}${field}]`;
}
