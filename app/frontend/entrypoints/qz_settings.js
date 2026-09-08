import {connect_qz, qz, qzState, qzSettingsStore, print} from './qz'
import 'dreamland'

import {QZStatusBanner} from "../js/components/qz/status_banner";
import {QZPrinterPicker} from "../js/components/qz/printer_picker";
import {DPIPicker} from "../js/components/qz/dpi_picker";
import {TestPrintButton} from "../js/components/qz/test_print_button";
import {RefreshPrintersButton} from "~/js/components/qz/refresh_printers_button";
let root = document.getElementById('dl_root')


function findPrinters() {
    qz.printers.find().then(function (data) {
        qz_state.refresh_state=true;
        setTimeout(()=>(qz_state.refresh_state=false), 200);
        qzState.availablePrinters = data
    }).catch(function (e) {
        console.error(e);
    });
}
qz_state.refresh_state = false

root.appendChild(html`
    <div style="max-width: 32rem;">
        <${QZStatusBanner} in_settings=${true} />

        <section>
            <div class="detail-grid" style="grid-template-columns: auto 1fr auto;">
                <label class="detail-label" for="printer_picker">Printer</label>
                <${QZPrinterPicker}/>
                ${h(RefreshPrintersButton, {findPrinters: findPrinters})}
            </div>
        </section>

        <section>
            <strong>Resolution</strong>
            <${DPIPicker} settings=${qzSettingsStore} state=${qzState} />
        </section>

        ${h(TestPrintButton, {
            testPrint: () => { print("/qz_tray/test_print") }
        })}
    </div>
`)

await connect_qz();
await findPrinters();
