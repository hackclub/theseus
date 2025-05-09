export function QZPrinterPicker() {
    console.log()
    return html`
        <div>
            <label for="printer_picker">pick a printer:</label>
            <select id="printer_picker" bind:value=${use(qz_settings.printer)} disabled=${qz_disconnected}>
                <option value="">pick a printer...</option>
                ${use(qz_state.availablePrinters,
                        (printers) => printers.map(printer => (html`
                            <option value="${printer}" selected=${printer == qz_settings.printer}>${printer}</option>`)
                        ))}
            </select>
        </div>
    `
}
