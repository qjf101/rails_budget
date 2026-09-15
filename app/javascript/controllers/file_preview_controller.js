import { Controller } from "@hotwired/stimulus"

// Shows the picked image in place of the current avatar before the form is saved.
export default class extends Controller {
  static targets = ["input", "container", "filename"]

  preview() {
    const file = this.inputTarget.files[0]
    if (!file) return

    if (this.hasFilenameTarget) this.filenameTarget.textContent = file.name

    const url = URL.createObjectURL(file)
    const image = document.createElement("img")
    image.src = url
    image.className = "w-full h-full object-cover"
    image.alt = file.name
    // Revoke once decoded, so the blob doesn't leak if several files are tried.
    image.onload = () => URL.revokeObjectURL(url)

    this.containerTarget.replaceChildren(image)
  }
}
