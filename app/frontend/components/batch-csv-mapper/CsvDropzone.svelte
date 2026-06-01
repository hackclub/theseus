<script>
  import Papa from 'papaparse';
  import { csvFile, headers, rows, autoMap, addressFields } from './stores.js';

  let dragging = false;
  let fileInput;
  let fileName = '';
  let error = '';

  function handleFile(file) {
    if (!file) return;

    error = '';

    if (!file.name.endsWith('.csv')) {
      error = 'Please select a CSV file.';
      return;
    }

    fileName = file.name;
    csvFile.set(file);

    Papa.parse(file, {
      header: true,
      skipEmptyLines: true,
      transformHeader: (h) => h.trim(),
      transform: (val) => val?.trim() ?? '',
      complete(results) {
        if (results.errors.length > 0) {
          const firstError = results.errors[0];
          error = `CSV parse error (row ${firstError.row}): ${firstError.message}`;
        }

        if (results.meta.fields?.length) {
          headers.set(results.meta.fields);
          rows.set(results.data);

          // Auto-map once we have headers
          let fields;
          addressFields.subscribe((v) => (fields = v))();
          autoMap(results.meta.fields, fields);
        }
      },
      error(err) {
        error = `Failed to read file: ${err.message}`;
      },
    });
  }

  function onFileInput(e) {
    handleFile(e.target.files[0]);
  }

  function onDrop(e) {
    dragging = false;
    handleFile(e.dataTransfer.files[0]);
  }
</script>

<div
  class="dropzone"
  class:dragging
  class:has-file={fileName}
  on:dragenter|preventDefault={() => (dragging = true)}
  on:dragover|preventDefault={() => (dragging = true)}
  on:dragleave={() => (dragging = false)}
  on:drop|preventDefault={onDrop}
  on:click={() => fileInput.click()}
  on:keydown={(e) => e.key === 'Enter' && fileInput.click()}
  role="button"
  tabindex="0"
>
  <input
    bind:this={fileInput}
    type="file"
    accept=".csv"
    on:change={onFileInput}
    style="display: none;"
  />

  {#if fileName}
    <div class="file-info">
      <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor">
        <path fill-rule="evenodd" d="M3.75 1.5a.25.25 0 00-.25.25v11.5c0 .138.112.25.25.25h8.5a.25.25 0 00.25-.25V6H9.75A1.75 1.75 0 018 4.25V1.5H3.75zm5.75.56v2.19c0 .138.112.25.25.25h2.19L9.5 2.06zM2 1.75C2 .784 2.784 0 3.75 0h5.086c.464 0 .909.184 1.237.513l3.414 3.414c.329.328.513.773.513 1.237v8.086A1.75 1.75 0 0112.25 15h-8.5A1.75 1.75 0 012 13.25V1.75z"/>
      </svg>
      <span class="file-name">{fileName}</span>
      <span class="change-hint">click to change</span>
    </div>
  {:else}
    <div class="placeholder">
      <svg width="24" height="24" viewBox="0 0 16 16" fill="currentColor" opacity="0.4">
        <path fill-rule="evenodd" d="M8.53 1.22a.75.75 0 00-1.06 0L3.72 4.97a.75.75 0 001.06 1.06l2.47-2.47v6.69a.75.75 0 001.5 0V3.56l2.47 2.47a.75.75 0 101.06-1.06L8.53 1.22zM1.75 12a.75.75 0 01.75.75v1.5c0 .138.112.25.25.25h10.5a.25.25 0 00.25-.25v-1.5a.75.75 0 011.5 0v1.5A1.75 1.75 0 0113.25 16H2.75A1.75 1.75 0 011 14.25v-1.5a.75.75 0 01.75-.75z"/>
      </svg>
      <span>Drop a CSV file here, or click to browse</span>
    </div>
  {/if}
</div>

{#if error}
  <div class="error">{error}</div>
{/if}

<style>
  .dropzone {
    border: 2px dashed var(--borderColor-default, #d1d5db);
    border-radius: 6px;
    padding: 24px;
    text-align: center;
    cursor: pointer;
    transition: border-color 0.15s, background 0.15s;
    background: var(--bgColor-default, #fff);
  }

  .dropzone:hover,
  .dropzone.dragging {
    border-color: var(--borderColor-accent-emphasis, #0969da);
    background: var(--bgColor-accent-muted, #ddf4ff);
  }

  .dropzone.has-file {
    border-style: solid;
    border-color: var(--borderColor-success-emphasis, #1a7f37);
    background: var(--bgColor-success-muted, #dafbe1);
  }

  .placeholder {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 8px;
    color: var(--fgColor-muted, #656d76);
    font-size: 14px;
  }

  .file-info {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    color: var(--fgColor-success, #1a7f37);
    font-size: 14px;
  }

  .file-name {
    font-weight: 600;
  }

  .change-hint {
    color: var(--fgColor-muted, #656d76);
    font-size: 12px;
  }

  .error {
    margin-top: 8px;
    padding: 8px 12px;
    background: var(--bgColor-danger-muted, #ffebe9);
    border: 1px solid var(--borderColor-danger-muted, #ff8182);
    border-radius: 6px;
    color: var(--fgColor-danger, #d1242f);
    font-size: 13px;
  }
</style>
