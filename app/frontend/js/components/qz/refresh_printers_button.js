export function RefreshPrintersButton() {
    return html`
        <button class="btn-sm" on:click=${this.findPrinters}
                disabled=${qz_disconnected} class:btn-success=${use(qz_state.refresh_state)}>
            ${use(qz_state.refresh_state, (s) => (s ? "✓" : '↻'))}
        </button>
    `
}
