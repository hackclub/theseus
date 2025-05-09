import {print} from "../../../entrypoints/qz";

export function PrintButton() {
    this.disabled = false
    this.printing = false;
    useChange([qz_settings.printer, qz_state.status, this.printing], () => {
        this.disabled = this.printing || qz_state.status !== 'connected' || qz_settings.printer === 'pick a printer...' || !qz_settings.printer
    })

    const handlePrintSuccess = () => {
        // Find and click the mark printed button by ID
        const markPrintedButton = document.getElementById('mark_printed');
        if (markPrintedButton) {
            markPrintedButton.click();
        }
    };

    return html`
        <button class="btn success" on:click=${() => {this.printing = true;print(qz_state.pdf_url, 'file', handlePrintSuccess)}}
                disabled=${use(this.disabled)}>🖨️ ${this.printing ? "printing..." : "print!"  }
        </button>
    `
}