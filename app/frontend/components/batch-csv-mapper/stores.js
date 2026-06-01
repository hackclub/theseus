import { writable, derived } from 'svelte/store';
import { REQUIRED_FIELDS, DEFAULT_MAPPING } from './constants.js';

// Core state
export const csvFile = writable(null);
export const headers = writable([]);
export const rows = writable([]);
export const mapping = writable({}); // { csvHeader: addressField }
export const userModified = writable(new Set()); // headers the user manually changed

// Available address fields (set by prop)
export const addressFields = writable([]);

// Which fields have been auto-mapped vs user-mapped
export const autoMapped = writable(new Set());

// Derived: inverted mapping { addressField: csvHeader }
export const invertedMapping = derived(mapping, ($mapping) => {
  const inv = {};
  for (const [csvHeader, field] of Object.entries($mapping)) {
    if (field) inv[field] = csvHeader;
  }
  return inv;
});

// Derived: which address fields are already taken
export const usedFields = derived(mapping, ($mapping) =>
  new Set(Object.values($mapping).filter(Boolean))
);

// Derived: missing required fields
export const missingRequired = derived(invertedMapping, ($inv) =>
  REQUIRED_FIELDS.filter((f) => !$inv[f])
);

// Derived: is the mapping valid (all required fields mapped)?
export const isValid = derived(missingRequired, ($missing) => $missing.length === 0);

// Derived: transformed rows (apply mapping to produce clean address objects)
export const mappedRows = derived([rows, mapping], ([$rows, $mapping]) => {
  if (!$rows.length || !Object.keys($mapping).length) return [];

  return $rows
    .map((row) => {
      const obj = {};
      for (const [csvHeader, field] of Object.entries($mapping)) {
        if (field && row[csvHeader] !== undefined) {
          obj[field] = (row[csvHeader] ?? '').toString().trim();
        }
      }
      return obj;
    })
    .filter((obj) => obj.first_name && obj.first_name.trim() !== '');
});

// Derived: per-row warnings for rows missing required field values
export const rowWarnings = derived([mappedRows, missingRequired], ([$mapped, $missingCols]) => {
  // only check if all required columns are mapped
  if ($missingCols.length > 0) return [];

  const warnings = [];
  $mapped.forEach((row, i) => {
    const missing = REQUIRED_FIELDS.filter((f) => !row[f] || row[f].trim() === '');
    if (missing.length > 0) {
      warnings.push({ row: i + 1, name: row.first_name || '(blank)', missing });
    }
  });
  return warnings;
});

// Derived: preview rows (first 5)
export const previewRows = derived(mappedRows, ($mapped) => $mapped.slice(0, 5));

// Derived: row count stats
export const stats = derived([rows, mappedRows, rowWarnings], ([$rows, $mapped, $warnings]) => ({
  total: $rows.length,
  valid: $mapped.length,
  skipped: $rows.length - $mapped.length,
  warnings: $warnings.length,
}));

// Auto-map headers based on the default mapping dictionary
export function autoMap($headers, $addressFields) {
  const fieldSet = new Set($addressFields);
  const newMapping = {};
  const newAutoMapped = new Set();
  const taken = new Set();

  for (const header of $headers) {
    const key = header.toLowerCase().trim();
    const field = DEFAULT_MAPPING[key];
    if (field && fieldSet.has(field) && !taken.has(field)) {
      newMapping[header] = field;
      newAutoMapped.add(header);
      taken.add(field);
    }
  }

  mapping.set(newMapping);
  autoMapped.set(newAutoMapped);
  userModified.set(new Set());
}
