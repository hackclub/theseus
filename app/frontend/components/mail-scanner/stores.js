import { writable, derived } from 'svelte/store';

export const scanHistory = writable([]);
export const currentScan = writable(null);
export const scannerMode = writable('keyboard');
export const isProcessing = writable(false);

export const stats = derived(scanHistory, $history => ({
  total: $history.length,
  successful: $history.filter(s => s.status === 'success').length,
  errors: $history.filter(s => s.status === 'error').length,
  alreadyMailed: $history.filter(s => s.status === 'already-mailed').length,
}));

export function addScanToHistory(scan) {
  scanHistory.update(history => [
    { ...scan, id: Date.now(), timestamp: new Date() },
    ...history
  ]);
}

export function removeScanFromHistory(scanId) {
  scanHistory.update(history => history.filter(s => s.id !== scanId));
}

export function clearHistory() {
  scanHistory.set([]);
}
