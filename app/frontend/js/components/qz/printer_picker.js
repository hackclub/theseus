export function QZPrinterPicker() {
    return html`
        <select id="printer_picker" style="width: 100%;" bind:value=${use(qz_settings.printer)} disabled=${qz_disconnected}>
            <option value="">pick a printer...</option>
            ${use(qz_state.availablePrinters,
                    (printers) => printers.map(printer => (html`
                        <option value="${printer}" selected=${printer == qz_settings.printer}>${printer}</option>`)
                    ))}
        </select>
    `
}
