import 'dreamland/dev'
let root = document.getElementById('instant_print_root')
import {InstantPrintWindow} from '~/js/components/instant_print_window'
import {connect_qz} from "./qz";
root.appendChild(h(InstantPrintWindow, {pdf_url: root.dataset.url}))
connect_qz();