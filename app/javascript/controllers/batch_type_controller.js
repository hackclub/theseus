import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["warehouseTemplate"]

  connect() {
    this.toggleWarehouseTemplate()
  }

  toggleWarehouseTemplate() {
    const typeSelect = this.element.querySelector('select[name="batch[type]"]')
    const selectedType = typeSelect.value
    const isWarehouse = selectedType === 'Warehouse::Batch'
    
    this.warehouseTemplateTarget.style.display = isWarehouse ? 'block' : 'none'
  }

  change() {
    this.toggleWarehouseTemplate()
  }
} 