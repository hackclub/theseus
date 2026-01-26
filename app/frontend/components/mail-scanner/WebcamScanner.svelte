<script>
  import { createEventDispatcher, onMount, onDestroy } from 'svelte';
  import { Html5Qrcode } from 'html5-qrcode';
  import { isProcessing } from './stores.js';

  const dispatch = createEventDispatcher();

  let html5QrCode;
  let cameras = [];
  let selectedCamera = null;
  let isScanning = false;
  let errorMessage = '';
  let lastScanTime = 0;
  const SCAN_DEBOUNCE_MS = 1000;

  export function activate() {
    if (!isScanning) {
      startScanning();
    }
  }

  export function deactivate() {
    if (isScanning) {
      stopScanning();
    }
  }

  function extractPublicIdFromUrl(text) {
    // Match: https://mail.hack.club/{public_id}?qr=1
    const match = text.match(/https?:\/\/mail\.hack\.club\/([^?\/\s]+)/);
    return match ? match[1] : null;
  }

  async function loadCameras() {
    try {
      const devices = await Html5Qrcode.getCameras();
      cameras = devices;

      if (devices.length > 0) {
        // Prefer back camera on mobile
        const backCamera = devices.find(d =>
          d.label.toLowerCase().includes('back') ||
          d.label.toLowerCase().includes('rear')
        );
        selectedCamera = backCamera ? backCamera.id : devices[0].id;
      } else {
        errorMessage = 'No cameras found';
      }
    } catch (err) {
      errorMessage = 'Failed to load cameras: ' + err.message;
      console.error('Camera loading error:', err);
    }
  }

  async function startScanning() {
    if (!selectedCamera) {
      errorMessage = 'Please select a camera';
      return;
    }

    try {
      html5QrCode = new Html5Qrcode("qr-reader");

      await html5QrCode.start(
        selectedCamera,
        {
          fps: 10,
          qrbox: { width: 250, height: 250 }
        },
        onScanSuccess,
        onScanFailure
      );

      isScanning = true;
      errorMessage = '';
    } catch (err) {
      errorMessage = 'Failed to start camera: ' + err.message;
      console.error('Camera start error:', err);

      if (err.message.includes('Permission')) {
        errorMessage = 'Camera permission denied. Please grant camera access and try again.';
      }
    }
  }

  async function stopScanning() {
    if (html5QrCode && isScanning) {
      try {
        await html5QrCode.stop();
        html5QrCode.clear();
      } catch (err) {
        console.error('Error stopping scanner:', err);
      }
      isScanning = false;
    }
  }

  function onScanSuccess(decodedText) {
    // Debounce scans
    const now = Date.now();
    if (now - lastScanTime < SCAN_DEBOUNCE_MS) {
      return;
    }

    // Don't scan if already processing
    if ($isProcessing) {
      return;
    }

    lastScanTime = now;

    const publicId = extractPublicIdFromUrl(decodedText);
    if (publicId) {
      dispatch('scan', { publicId });
    } else {
      dispatch('error', { message: 'Invalid QR code format' });
    }
  }

  function onScanFailure(error) {
    // Ignore these - they're expected when no QR code is in frame
  }

  async function handleCameraChange() {
    if (isScanning) {
      await stopScanning();
      await startScanning();
    }
  }

  onMount(() => {
    loadCameras();
  });

  onDestroy(() => {
    stopScanning();
  });
</script>

<div class="webcam-scanner">
  {#if errorMessage}
    <div class="error-message">
      {errorMessage}
    </div>
  {/if}

  {#if cameras.length > 0}
    <div class="camera-controls">
      <label for="camera-select">Camera:</label>
      <select
        id="camera-select"
        bind:value={selectedCamera}
        on:change={handleCameraChange}
        disabled={isScanning}
      >
        {#each cameras as camera}
          <option value={camera.id}>{camera.label || `Camera ${camera.id}`}</option>
        {/each}
      </select>

      {#if !isScanning}
        <button class="btn btn-primary" on:click={startScanning}>
          Start Camera
        </button>
      {:else}
        <button class="btn" on:click={stopScanning}>
          Stop Camera
        </button>
      {/if}
    </div>
  {/if}

  <div id="qr-reader" class="qr-reader"></div>

  {#if isScanning}
    <div class="scan-instructions">
      Position QR code within the box to scan
    </div>
  {/if}
</div>

<style>
  .webcam-scanner {
    display: flex;
    flex-direction: column;
    gap: 1rem;
    padding: 1rem;
  }

  .error-message {
    padding: 1rem;
    background-color: var(--bgColor-attention-muted);
    border: 1px solid var(--borderColor-attention-emphasis);
    border-radius: 6px;
    color: var(--fgColor-default);
  }

  .camera-controls {
    display: flex;
    align-items: center;
    gap: 1rem;
    padding: 1rem;
    background-color: var(--bgColor-muted);
    border-radius: 6px;
  }

  .camera-controls label {
    font-weight: 600;
  }

  .camera-controls select {
    flex: 1;
    padding: 0.5rem;
    border: 1px solid var(--borderColor-default);
    border-radius: 6px;
    background-color: var(--bgColor-default);
    color: var(--fgColor-default);
  }

  .qr-reader {
    width: 100%;
    max-width: 500px;
    margin: 0 auto;
  }

  .qr-reader :global(video) {
    border-radius: 6px;
  }

  .scan-instructions {
    text-align: center;
    color: var(--fgColor-muted);
    font-size: 0.875rem;
  }

  .btn {
    padding: 0.5rem 1rem;
    border: 1px solid var(--borderColor-default);
    border-radius: 6px;
    background-color: var(--bgColor-default);
    color: var(--fgColor-default);
    cursor: pointer;
    font-weight: 600;
  }

  .btn:hover {
    background-color: var(--bgColor-muted);
  }

  .btn-primary {
    background-color: var(--bgColor-accent-emphasis);
    color: var(--fgColor-onEmphasis);
    border-color: var(--bgColor-accent-emphasis);
  }

  .btn-primary:hover {
    opacity: 0.9;
  }

  .btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
</style>
