import qz from 'qz-tray'
import 'dreamland'

let qzState = $state({
    status: "connecting", availablePrinters: []
})

window.qz_state = qzState

let qzSettingsStore = $store({
    printer: undefined, dpi: 203,
}, {ident: "theseus-qz-settings", backing: "localstorage", autosave: "auto"})

window.qz_settings = qzSettingsStore

window.qz_disconnected = use(qz_state.status, s => (s !== "connected"))

qz.security.setCertificatePromise(function (resolve, reject) {
    fetch("/qz_tray/cert", {cache: 'no-store', headers: {'Content-Type': 'text/plain'}})
        .then(function (data) {
            data.ok ? resolve(data.text()) : reject(data.text());
        });
});

qz.security.setSignatureAlgorithm("SHA512"); // Since 2.1
qz.security.setSignaturePromise(function (toSign) {
    return function (resolve, reject) {
        fetch("/qz_tray/sign?request=" + toSign, {
            method: 'POST', cache: 'no-store', headers: {'Content-Type': 'text/plain'}
        })
            .then(function (data) {
                data.ok ? resolve(data.text()) : reject(data.text());
            });
    };
});

async function connect_qz() {
    await qz.websocket.connect().then(function () {
        qzState.status = "connected"
    }).catch(function (error) {
        qzState.status = "error"
    })
}

function make_qz_config() {
    return qz.configs.create(qzSettingsStore.printer, {
        colorType: 'blackwhite',
        density: +qzSettingsStore.dpi,
        units: 'in',
        rasterize: true,
        interpolation: 'nearest-neighbor',
        size: {
            width: 4, height: 6
        }
    })
}

function print(input, flavor = 'file', onSuccess = () => {}) {
    var data = [{
        type: 'pixel', format: 'pdf', flavor: 'file', data: input
    }];
    qz.print(make_qz_config(), data)
        .then(function() {
            qzState.error = null;
            if (onSuccess) onSuccess();
        })
        .catch(function (e) {
            qzState.error = e;
        });
}

export {qz, connect_qz, qzState, qzSettingsStore, print}
