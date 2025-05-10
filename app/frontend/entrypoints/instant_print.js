import 'dreamland'
let root = document.getElementById('instant_print_root')
import {InstantPrintWindow} from '~/js/components/instant_print_window'
import {connect_qz} from "./qz";
root.appendChild(h(InstantPrintWindow, {pdf_url: root.dataset.url}))
await connect_qz();
if(root.dataset.printNow) {
    setTimeout(()=>{document.querySelector('[data-component="PrintButton"]>button').click()})
}
