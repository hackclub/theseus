export function RefreshPrintersButton() {
    return html`
        <button class="btn btn-tiny outlined" style="margin-bottom: 1em" ${use(qz_state.refresh_state)}
                on:click=${this.findPrinters} disabled=${qz_disconnected} class:success=${use(qz_state.refresh_state)}>
            ${use(qz_state.refresh_state, (s) => (s ? "✓" : '↻'))}
        </button>
    `
}