function RadioButton() {
    return html`
        <label for="dpi_${this.dpi}" style="display: flex; align-items: center; gap: 0.5rem; padding: 0.35rem 0; cursor: pointer;">
            <input type="radio" name="qz_dpi" id="dpi_${this.dpi}" value="${this.dpi}"
                   checked=${this.settings.dpi == this.dpi} on:change=${() => this.settings.dpi = this.dpi} />
            <strong>${this.dpi} DPI</strong>
            <span class="text-muted">${this.desc}</span>
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
        <div style="margin-top: 0.5rem;">
            ${Object.entries(DPI_OPTS).map(([a, b]) => (h(RadioButton, {dpi: a, desc: b, settings: this.settings})))}
        </div>`
}
