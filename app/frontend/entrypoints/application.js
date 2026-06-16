import Alpine from 'alpinejs'
import * as Turbo from '@hotwired/turbo-rails'
Turbo.session.drive = false // only use Turbo Streams, not Drive
import '~/js/click-to-copy.js'
import '~/js/mount-svelte.js'
window.Alpine = Alpine
Alpine.start()

// Prevent double-submission: disable submit buttons on form submit
document.addEventListener('submit', (e) => {
  e.target.querySelectorAll('button[type="submit"], input[type="submit"]').forEach(btn => {
    btn.disabled = true
    btn.textContent = btn.dataset.disableWith || btn.textContent
  })
})