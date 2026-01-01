import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "password",
    "confirmation",
    "submit",
    "confirmMessage",
    "ruleLength",
    "ruleUppercase",
    "ruleNumber",
    "ruleSpecial"
  ]

  connect() {
    this.validate()
  }

  validate() {
    const password = (this.passwordTarget?.value || "")
    const confirmation = (this.confirmationTarget?.value || "")

    const rules = {
      length: password.length >= 8,
      uppercase: /[A-Z]/.test(password),
      number: /[0-9]/.test(password),
      special: /[^A-Za-z0-9]/.test(password)
    }

    this.#setRule(this.ruleLengthTarget, rules.length)
    this.#setRule(this.ruleUppercaseTarget, rules.uppercase)
    this.#setRule(this.ruleNumberTarget, rules.number)
    this.#setRule(this.ruleSpecialTarget, rules.special)

    const allValid = Object.values(rules).every(Boolean)
    const confirmationOk = confirmation.length > 0 && password === confirmation

    // message confirmation
    if (confirmation.length === 0) {
      this.confirmMessageTarget?.classList.add("hidden")
    } else if (!confirmationOk) {
      this.confirmMessageTarget?.classList.remove("hidden")
      this.confirmMessageTarget?.classList.remove("text-emerald-600")
      this.confirmMessageTarget?.classList.add("text-red-600")
      this.confirmMessageTarget.textContent = "Les mots de passe ne correspondent pas"
    } else {
      this.confirmMessageTarget?.classList.remove("hidden")
      this.confirmMessageTarget?.classList.remove("text-red-600")
      this.confirmMessageTarget?.classList.add("text-emerald-600")
      this.confirmMessageTarget.textContent = "Mot de passe confirmé ✅"
    }

    // bouton
    const canSubmit = allValid && confirmationOk
    if (this.submitTarget) this.submitTarget.disabled = !canSubmit
  }

  #setRule(el, ok) {
    if (!el) return

    el.classList.remove("text-red-600", "text-emerald-600", "text-slate-700")
    el.classList.add(ok ? "text-emerald-600" : "text-red-600")
  }
}
