import { Controller } from "@hotwired/stimulus"

// Gère les lignes de facture (ajout / suppression)
export default class extends Controller {
  static targets = ["container", "template", "item"]

  add(event) {
    event.preventDefault()

    const time = new Date().getTime().toString()
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, time)

    this.containerTarget.insertAdjacentHTML("beforeend", content)
  }

  remove(event) {
    event.preventDefault()

    const row = event.target.closest("[data-invoice-items-target='item']")
    if (!row) return

    const isNew = row.dataset.newRecord === "true"

    if (isNew) {
      // Ligne ajoutée côté front seulement : on la supprime du DOM
      row.remove()
      return
    }

    // Ligne existante en base : on marque pour destruction
    const destroyInput = row.querySelector("input[name*='_destroy']")

    if (destroyInput) {
      destroyInput.value = "1"
      row.classList.add("opacity-50", "line-through")
    } else {
      row.remove()
    }
  }
}
