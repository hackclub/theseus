export function TestPrintButton() {
    this.disabled = false
    this.printing = false

    useChange([qz_settings.printer, qz_state.status, this.printing], () => {
        this.disabled = this.printing || qz_state.status !== 'connected' || qz_settings.printer === 'pick a printer...' || !qz_settings.printer
    })
    return html`
    <button class="btn success" on:click=${() => {
        this.printing = true;
        setTimeout(()=>{this.printing = false}, 700);
        this.testPrint()
    }}
            disabled=${use(this.disabled)}> ${ use(this.printing, (p) => (p ? "printing..." : "test print?"))}
    </button>
`
}