export function TestPrintButton() {
    this.disabled = false
    useChange([qz_settings.printer, qz_state.status], () => {
        this.disabled = qz_state.status !== 'connected' || qz_settings.printer === 'pick a printer...' || !qz_settings.printer
    })
    return html`
    <button class="btn success" on:click=${this.testPrint}
            disabled=${use(this.disabled)}>test print!
    </button>
`
}