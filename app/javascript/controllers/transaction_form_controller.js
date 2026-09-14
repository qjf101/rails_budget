import { Controller } from "@hotwired/stimulus"

// The Add/Edit Transaction form: the Expense/Income segmented control, and the
// "Split across goals" section that only applies to Savings transactions.
export default class extends Controller {
  static targets = ["typeInput", "typeButton", "category", "savingsSection", "amount", "allocation", "unallocated"]
  static values = { savingsCategoryId: String }

  connect() {
    this.syncCategories()
    this.recalculate()
  }

  selectType(event) {
    this.typeInputTarget.value = event.currentTarget.dataset.type
    this.syncTypeButtons()
    this.syncCategories()
  }

  // Expenses and income keep separate category lists, so the category options
  // are narrowed to the selected type and a stale selection is dropped.
  syncCategories() {
    const type = this.typeInputTarget.value
    const select = this.categoryTarget
    let selectionStillValid = false

    Array.from(select.options).forEach((option) => {
      if (!option.value) return

      const matches = option.dataset.categoryType === type
      option.hidden = !matches
      option.disabled = !matches
      if (matches && option.value === select.value) selectionStillValid = true
    })

    if (!selectionStillValid) {
      const firstMatch = Array.from(select.options).find((option) => option.value && !option.disabled)
      select.value = firstMatch ? firstMatch.value : ""
    }

    this.toggleSavings()
  }

  syncTypeButtons() {
    const selected = this.typeInputTarget.value
    this.typeButtonTargets.forEach((button) => {
      const active = button.dataset.type === selected
      button.classList.toggle("bg-green-800", active)
      button.classList.toggle("text-white", active)
      button.classList.toggle("text-gray-500", !active)
    })
  }

  toggleSavings() {
    if (!this.hasSavingsSectionTarget) return
    this.savingsSectionTarget.hidden = this.categoryTarget.value !== this.savingsCategoryIdValue
  }

  recalculate() {
    if (!this.hasUnallocatedTarget) return

    const remainder = this.centsOf(this.amountTarget) -
      this.allocationTargets.reduce((sum, input) => sum + this.centsOf(input), 0)

    this.unallocatedTarget.textContent = (remainder / 100).toLocaleString("en-US", { style: "currency", currency: "USD" })
    this.unallocatedTarget.classList.toggle("text-red-600", remainder < 0)
    this.unallocatedTarget.classList.toggle("text-green-800", remainder >= 0)
  }

  // Empty and unparseable inputs both read as zero.
  centsOf(input) {
    return Math.round((parseFloat(input.value) || 0) * 100)
  }
}
