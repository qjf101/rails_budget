import { Controller } from "@hotwired/stimulus"

// Drives the dialog rendered into the layout's "modal" turbo frame.
export default class extends Controller {
  connect() {
    document.body.classList.add("overflow-hidden")
  }

  disconnect() {
    document.body.classList.remove("overflow-hidden")
  }

  // Emptying the frame *and* dropping its src matters: without clearing src,
  // clicking the same link again is a no-op navigation and the modal never reopens.
  close() {
    const frame = this.element.closest("turbo-frame")
    if (frame) {
      frame.removeAttribute("src")
      frame.innerHTML = ""
    } else {
      this.element.remove()
    }
  }

  closeOnBackdrop(event) {
    if (event.target === this.element) this.close()
  }

  closeOnEscape(event) {
    if (event.key === "Escape") this.close()
  }
}
