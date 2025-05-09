const text = {
    connecting: "connecting to QZ tray...",
    connected: "connected to QZ tray!",
    error: html`<span>couldn't connect – do you need to <a href='https://qz.io/download/' target="_blank">install</a> QZ tray?</span>`
}

const classes = {
    connecting: "banner-warning", connected: "banner-success", error: "banner-danger"
}

export function QZStatusBanner() {

    return html`<span>${$if(use(qz_state.status, (s) =>
            (this.in_settings ? true : s !== 'connected')
    ), html`
        <div class=${['banner', use(qz_state.status, (state) => classes[state])]}>
            ${use(qz_state.status, (state) => text[state])}
        </div>`)}</span>`
}