import $ from "jquery";
window.$ = window.jQuery = $;
import '~/js/click-to-copy.js'
import '~/js/interactive-tables.js'
import '~/js/confetti.js'
import '@hotwired/turbo-rails'

Turbo.config.forms.mode = "optin";

// import "dreamland/dist/all.js"