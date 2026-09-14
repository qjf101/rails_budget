import { Controller } from "@hotwired/stimulus"

// A grid of buttons that writes the chosen value into a sibling hidden field.
// Used for the category icon and color pickers.
export default class extends Controller {
  static targets = ["input", "option"]
  static values = { name: String }

  select(event) {
    const chosen = event.currentTarget
    this.inputTarget.value = chosen.dataset.value

    this.optionTargets.forEach((option) => {
      const active = option === chosen
      if (this.nameValue === "color") {
        option.classList.toggle("ring-2", active)
        option.classList.toggle("ring-offset-2", active)
        option.classList.toggle("ring-gray-900", active)
      } else {
        option.classList.toggle("border-green-600", active)
        option.classList.toggle("bg-green-50", active)
        option.classList.toggle("text-green-700", active)
        option.classList.toggle("border-gray-200", !active)
        option.classList.toggle("text-gray-500", !active)
      }
    })
  }
}
