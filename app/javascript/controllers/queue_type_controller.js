import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["instantFields", "paymentAccountField"]

  connect() {
    this.toggleFields()
  }

  toggleFields() {
    const type = this.element.querySelector('select[name="letter_queue[type]"]').value
    this.instantFieldsTarget.style.display = type === "Letter::InstantQueue" ? "block" : "none"
  }

  togglePaymentAccount(event) {
    const postageType = event.target.value
    this.paymentAccountFieldTarget.style.display = postageType === "indicia" ? "block" : "none"
  }
} 