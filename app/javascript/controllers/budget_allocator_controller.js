import { Controller } from "@hotwired/stimulus"

// Keeps the Budget screen's totals, per-category percentages and summary legend in
// step with what's typed, before anything is saved.
export default class extends Controller {
  static targets = [
    "income", "allocation",
    "allocatedTotal", "remainingTotal", "allocatedPercent", "allocatedBar",
    "statusMessage", "statusPanel",
  ]

  connect() {
    // Snapshot for Reset — the saved state, not whatever gets typed next.
    this.savedValues = this.allocationTargets.map((input) => input.value)
    this.savedIncome = this.incomeTarget.value
    this.recalculate()
  }

  applyPlan() {
    this.allocationTargets.forEach((input) => {
      input.value = input.dataset.suggested
    })
    this.recalculate()
  }

  reset() {
    this.incomeTarget.value = this.savedIncome
    this.allocationTargets.forEach((input, i) => {
      input.value = this.savedValues[i]
    })
    this.recalculate()
  }

  recalculate() {
    const income = this.centsOf(this.incomeTarget)
    let allocated = 0

    this.allocationTargets.forEach((input) => {
      const cents = this.centsOf(input)
      allocated += cents
      const percent = income > 0 ? Math.round((cents / income) * 100) : 0
      const card = input.closest("[data-allocation-card]")

      card.querySelector("[data-percent]").textContent = `${percent}% of income`
      card.querySelector("[data-bar]").style.width = `${Math.min(percent, 100)}%`

      const legend = this.element.querySelector(`[data-legend-amount="${input.dataset.categoryId}"]`)
      if (legend) legend.textContent = `${this.money(cents)} (${percent}%)`
    })

    const remaining = income - allocated
    const percent = income > 0 ? Math.round((allocated / income) * 100) : 0

    this.allocatedTotalTargets.forEach((el) => { el.textContent = this.money(allocated) })
    this.remainingTotalTargets.forEach((el) => { el.textContent = this.money(remaining) })
    this.allocatedPercentTargets.forEach((el) => { el.textContent = `${percent}%` })
    this.allocatedBarTargets.forEach((el) => { el.style.width = `${Math.min(percent, 100)}%` })

    this.renderStatus(percent, remaining)
  }

  renderStatus(percent, remaining) {
    if (!this.hasStatusMessageTarget) return

    const over = remaining < 0
    this.statusMessageTarget.textContent = over
      ? `You've allocated ${percent}% of your income — ${this.money(Math.abs(remaining))} more than you take home.`
      : `You've allocated ${percent}% of your income. ${this.money(remaining)} left to reach 100%.`

    this.statusPanelTarget.classList.toggle("bg-red-50", over)
    this.statusPanelTarget.classList.toggle("border-red-200", over)
    this.statusPanelTarget.classList.toggle("bg-green-50", !over)
    this.statusPanelTarget.classList.toggle("border-green-100", !over)
  }

  // Empty and unparseable inputs both read as zero.
  centsOf(input) {
    return Math.round((parseFloat(input.value) || 0) * 100)
  }

  money(cents) {
    return (cents / 100).toLocaleString("en-US", {
      style: "currency", currency: "USD", maximumFractionDigits: 0,
    })
  }
}
