function RadioButton() {
    return html`
        <label for="dpi_${this.dpi}">${this.dpi} DPI (${this.desc})
            <input type="radio" name="qz_dpi" id="dpi_${this.dpi}" value="${this.dpi}"
                   checked=${this.settings.dpi == this.dpi} on:change=${() => this.settings.dpi = this.dpi}
        </label>
    `
}

export function DPIPicker() {
    const DPI_OPTS = {
        203: "most common",
        300: "fancier!",
        305: "sometimes?"
    }
    return html`
        <fieldset disabled=${qz_disconnected}>
            <legend><strong>DPI</strong></legend>
            ${Object.entries(DPI_OPTS).map(([a, b]) => (h(RadioButton, {dpi: a, desc: b, settings: this.settings})))}
        </fieldset>`
}