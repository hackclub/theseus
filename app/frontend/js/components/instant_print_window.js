import {QZStatusBanner} from "./qz/status_banner";
import {QZErrorBanner} from "./qz/error_banner";
import {PrintButton} from "./qz/print_button";
export function InstantPrintWindow() {
    qz_state.pdf_url = this.pdf_url
    return html`<div>
        ${$if(
            use(qz_settings.printer, (p) => (qz_settings.printer === 'pick a printer...' || !qz_settings.printer)),
            html`
            <div class="banner banner-info">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                you need to <a href="/qz_tray/settings">set up your printer</a> :-P
            </div>
            `
        )}
        <${QZStatusBanner}/>
        <${QZErrorBanner}/>
        <${PrintButton}/>
    </div>`
}