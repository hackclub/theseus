import {connect_qz, qz, qzState, qzSettingsStore, print} from './qz'
import 'dreamland/dev'

import {QZStatusBanner} from "../js/components/qz/status_banner";
import {QZPrinterPicker} from "../js/components/qz/printer_picker";
import {DPIPicker} from "../js/components/qz/dpi_picker";
import {TestPrintButton} from "../js/components/qz/test_print_button";

let root = document.getElementById('dl_root')


function findPrinters() {
    qz.printers.find().then(function (data) {
        qzState.availablePrinters = data
    }).catch(function (e) {
        console.error(e);
    });
}

root.appendChild(h(QZStatusBanner, {in_settings: true}))
root.appendChild(html`
    <button on:click=${findPrinters} disabled=${qz_disconnected}>refresh printers</button>`)
root.appendChild(h(QZPrinterPicker))
root.appendChild(h(DPIPicker, {settings: qzSettingsStore, state: qzState}))
root.appendChild(h(TestPrintButton, {
    testPrint: () => {
        print("/qz_tray/test_print")
    }
}))
await connect_qz();
await findPrinters();
