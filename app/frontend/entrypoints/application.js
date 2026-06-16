import Alpine from 'alpinejs'
import '@hotwired/turbo-rails'
import '~/js/click-to-copy.js'
import '~/js/mount-svelte.js'
window.Alpine = Alpine
Alpine.start()

// Prevent double-submission: disable submit buttons on form submit
document.addEventListener('submit', (e) => {
  e.target.querySelectorAll('button[type="submit"], input[type="submit"]').forEach(btn => {
    btn.dataset.originalText = btn.textContent
    btn.disabled = true
    btn.textContent = btn.dataset.disableWith || 'Submitting…'
  })
})
// Re-enable on page show (bfcache restore or redirect-back)
window.addEventListener('pageshow', () => {
  document.querySelectorAll('button[disabled][data-original-text], input[disabled][data-original-text]').forEach(btn => {
    btn.disabled = false
    btn.textContent = btn.dataset.originalText
  })
})