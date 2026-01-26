<script>
  import { createEventDispatcher, onMount, onDestroy } from 'svelte';
  import { Html5Qrcode } from 'html5-qrcode';
  import { isProcessing } from './stores.js';
  import { extractPublicId } from './utils.js';

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

  async function loadCameras() {
    try {
      const devices = await Html5Qrcode.getCameras();
      cameras = devices;

      if (devices.length > 0) {
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
    const now = Date.now();
    if (now - lastScanTime < SCAN_DEBOUNCE_MS) {
      return;
    }

    if ($isProcessing) {
      return;
    }

    lastScanTime = now;

    const publicId = extractPublicId(decodedText);
    if (publicId) {
      dispatch('scan', { publicId });
    } else {
      dispatch('error', { message: 'Invalid QR code format' });
    }
  }

  function onScanFailure(error) {
    // Ignore - expected when no QR code in frame
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

<div style="background: var(--bgColor-default); border: 1px solid var(--borderColor-default); border-radius: 6px; padding: 20px;">
  {#if errorMessage}
    <div style="padding: 12px; background: var(--bgColor-attention-muted); border: 1px solid var(--borderColor-attention-emphasis); border-radius: 6px; margin-bottom: 16px; font-size: 14px;">
      {errorMessage}
    </div>
  {/if}

  {#if cameras.length > 0}
    <div style="display: flex; gap: 12px; align-items: center; margin-bottom: 16px; flex-wrap: wrap;">
      <label for="camera-select" style="font-size: 14px; font-weight: 600;">Camera:</label>
      <select
        id="camera-select"
        bind:value={selectedCamera}
        on:change={handleCameraChange}
        disabled={isScanning}
        style="flex: 1; min-width: 200px; padding: 8px; border: 1px solid var(--borderColor-default); border-radius: 6px; background: var(--bgColor-default); font-size: 14px;"
      >
        {#each cameras as camera}
          <option value={camera.id}>{camera.label || `Camera ${camera.id}`}</option>
        {/each}
      </select>

      {#if !isScanning}
        <button
          style="padding: 8px 16px; background: var(--bgColor-accent-emphasis); color: var(--fgColor-onEmphasis); border: 1px solid var(--bgColor-accent-emphasis); border-radius: 6px; font-size: 14px; font-weight: 600; cursor: pointer;"
          on:click={startScanning}
        >
          Start Camera
        </button>
      {:else}
        <button
          style="padding: 8px 16px; background: var(--bgColor-default); color: var(--fgColor-default); border: 1px solid var(--borderColor-default); border-radius: 6px; font-size: 14px; font-weight: 600; cursor: pointer;"
          on:click={stopScanning}
        >
          Stop Camera
        </button>
      {/if}
    </div>
  {/if}

  <div id="qr-reader" style="width: 100%; max-width: 500px; margin: 0 auto;"></div>

  {#if isScanning}
    <div style="text-align: center; color: var(--fgColor-muted); font-size: 13px; margin-top: 12px;">
      Position QR code within the box to scan
    </div>
  {/if}
</div>
