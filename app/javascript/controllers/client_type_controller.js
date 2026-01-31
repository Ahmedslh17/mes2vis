import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["typeSelect", "sirenBlock", "sirenInput"]

  connect() {
    this.toggle()
  }

  toggle() {
    const type = this.typeSelectTarget.value
    const isPro = type === "professionnel"

    this.sirenBlockTarget.classList.toggle("hidden", !isPro)

    // optionnel mais propre : si on revient en particulier, on vide le champ
    if (!isPro) {
      this.sirenInputTarget.value = ""
    }
  }
}
