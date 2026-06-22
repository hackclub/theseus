// Grid picklist — click cells to select, shift-click for range, then apply bulk actions.
// Works with any .batch-grid that has [data-picklist] on it.

document.addEventListener('DOMContentLoaded', initPicklists)
document.addEventListener('turbo:load', initPicklists)

function initPicklists() {
  document.querySelectorAll('[data-picklist]:not([data-picklist-init])').forEach(initPicklist)
}

function initPicklist(grid) {
  grid.dataset.picklistInit = 'true'
  const cells = () => grid.querySelectorAll('.batch-cell[data-letter-id]')
  let lastClicked = null

  // Selection state
  const selected = new Set()

  function updateUI() {
    cells().forEach(cell => {
      const id = cell.dataset.letterId
      cell.classList.toggle('batch-cell-selected', selected.has(id))
    })
    const container = grid.closest('[data-picklist-container]')
    if (!container) return

    // Update count
    const counter = container.querySelector('[data-picklist-count]')
    if (counter) counter.textContent = selected.size

    // Enable/disable action buttons
    container.querySelectorAll('[data-picklist-action]').forEach(btn => {
      btn.disabled = selected.size === 0
    })

    // Update ALL hidden fields with selected IDs (multiple forms)
    const ids = Array.from(selected).join(',')
    container.querySelectorAll('[data-picklist-ids]').forEach(field => {
      field.value = ids
    })

    // Update selection preview
    const preview = container.querySelector('[data-picklist-preview]')
    if (preview) {
      if (selected.size === 0) {
        preview.style.display = 'none'
        preview.textContent = ''
      } else {
        preview.style.display = ''
        const names = []
        cells().forEach(cell => {
          if (selected.has(cell.dataset.letterId)) {
            names.push(cell.title || cell.dataset.letterId)
          }
        })
        // Show first 20, then "and N more"
        const shown = names.slice(0, 20)
        let text = shown.join('\n')
        if (names.length > 20) text += '\n… and ' + (names.length - 20) + ' more'
        preview.textContent = text
        preview.style.whiteSpace = 'pre-line'
      }
    }
  }

  grid.addEventListener('click', (e) => {
    const cell = e.target.closest('.batch-cell[data-letter-id]')
    if (!cell) return

    const id = cell.dataset.letterId

    if (e.shiftKey && lastClicked) {
      // Range select: from lastClicked to this cell
      const allCells = Array.from(cells())
      const startIdx = allCells.findIndex(c => c.dataset.letterId === lastClicked)
      const endIdx = allCells.findIndex(c => c.dataset.letterId === id)
      const [from, to] = startIdx < endIdx ? [startIdx, endIdx] : [endIdx, startIdx]
      for (let i = from; i <= to; i++) {
        selected.add(allCells[i].dataset.letterId)
      }
    } else {
      // Toggle single cell
      if (selected.has(id)) {
        selected.delete(id)
      } else {
        selected.add(id)
      }
    }

    lastClicked = id
    updateUI()
  })

  // Toolbar buttons
  const container = grid.closest('[data-picklist-container]')
  if (!container) return

  container.querySelector('[data-select-all]')?.addEventListener('click', () => {
    cells().forEach(c => selected.add(c.dataset.letterId))
    updateUI()
  })

  container.querySelector('[data-select-none]')?.addEventListener('click', () => {
    selected.clear()
    updateUI()
  })

  container.querySelector('[data-select-unprinted]')?.addEventListener('click', () => {
    selected.clear()
    cells().forEach(c => {
      if (c.classList.contains('batch-cell-pending')) selected.add(c.dataset.letterId)
    })
    updateUI()
  })

  container.querySelector('[data-select-printed]')?.addEventListener('click', () => {
    selected.clear()
    cells().forEach(c => {
      if (c.classList.contains('batch-cell-purchased') || c.classList.contains('batch-cell-valid')) selected.add(c.dataset.letterId)
    })
    updateUI()
  })

  updateUI()
}
