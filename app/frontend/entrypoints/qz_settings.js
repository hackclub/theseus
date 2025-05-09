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
root.appendChild(h(QZStatusBanner, {in_settings: true}))
// root.appendChild(h(QZPrinterPicker))
root.appendChild(html`
    <div>
        <div class="grid">
            <div>
                <${QZPrinterPicker}/>
            </div>
            <div>
                ${h(RefreshPrintersButton, {findPrinters: findPrinters})}
            </div>
        </div>
    </div>

`)

// root.appendChild(h(RefreshPrintersButton, {findPrinters: findPrinters}))
root.appendChild(h(DPIPicker, {settings: qzSettingsStore, state: qzState}))
root.appendChild(h(TestPrintButton, {
    testPrint: () => {
        print("/qz_tray/test_print")
    }
}))
await connect_qz();
await findPrinters();
