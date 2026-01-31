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
    "ruleSpecial",
    "togglePassword",
    "toggleConfirmation",
    "eyeOpen",
    "eyeOff",
    "eyeOpenConfirmation",
    "eyeOffConfirmation"
  ]

  connect() {
    this.validate()
    this.#syncIcons()
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

    // ✅ Ne casse pas si les targets rules n'existent pas (ex: page login)
    this.#setRule(this.hasRuleLengthTarget ? this.ruleLengthTarget : null, rules.length)
    this.#setRule(this.hasRuleUppercaseTarget ? this.ruleUppercaseTarget : null, rules.uppercase)
    this.#setRule(this.hasRuleNumberTarget ? this.ruleNumberTarget : null, rules.number)
    this.#setRule(this.hasRuleSpecialTarget ? this.ruleSpecialTarget : null, rules.special)

    const allValid = Object.values(rules).every(Boolean)
    const confirmationOk = confirmation.length > 0 && password === confirmation

    // message confirmation (si présent)
    if (this.hasConfirmMessageTarget) {
      if (confirmation.length === 0) {
        this.confirmMessageTarget.classList.add("hidden")
      } else if (!confirmationOk) {
        this.confirmMessageTarget.classList.remove("hidden")
        this.confirmMessageTarget.classList.remove("text-emerald-600")
        this.confirmMessageTarget.classList.add("text-red-600")
        this.confirmMessageTarget.textContent = "Les mots de passe ne correspondent pas"
      } else {
        this.confirmMessageTarget.classList.remove("hidden")
        this.confirmMessageTarget.classList.remove("text-red-600")
        this.confirmMessageTarget.classList.add("text-emerald-600")
        this.confirmMessageTarget.textContent = "Mot de passe confirmé ✅"
      }
    }

    // bouton submit (si présent)
    const canSubmit = allValid && confirmationOk
    if (this.hasSubmitTarget) this.submitTarget.disabled = !canSubmit
  }

  togglePassword() {
    if (!this.hasPasswordTarget) return
    this.passwordTarget.type = this.passwordTarget.type === "password" ? "text" : "password"
    if (this.hasTogglePasswordTarget) {
      this.togglePasswordTarget.setAttribute(
        "aria-label",
        this.passwordTarget.type === "password" ? "Afficher le mot de passe" : "Masquer le mot de passe"
      )
    }
    this.#syncIcons()
  }

  toggleConfirmation() {
    if (!this.hasConfirmationTarget) return
    this.confirmationTarget.type = this.confirmationTarget.type === "password" ? "text" : "password"
    if (this.hasToggleConfirmationTarget) {
      this.toggleConfirmationTarget.setAttribute(
        "aria-label",
        this.confirmationTarget.type === "password" ? "Afficher le mot de passe" : "Masquer le mot de passe"
      )
    }
    this.#syncIcons()
  }

  #syncIcons() {
    // Password
    if (this.hasPasswordTarget) {
      const visible = this.passwordTarget.type === "text"
      if (this.hasEyeOpenTarget) this.eyeOpenTarget.classList.toggle("hidden", visible)
      if (this.hasEyeOffTarget) this.eyeOffTarget.classList.toggle("hidden", !visible)
    }

    // Confirmation
    if (this.hasConfirmationTarget) {
      const visibleC = this.confirmationTarget.type === "text"
      if (this.hasEyeOpenConfirmationTarget) this.eyeOpenConfirmationTarget.classList.toggle("hidden", visibleC)
      if (this.hasEyeOffConfirmationTarget) this.eyeOffConfirmationTarget.classList.toggle("hidden", !visibleC)
    }
  }

  #setRule(el, ok) {
    if (!el) return
    el.classList.remove("text-red-600", "text-emerald-600", "text-slate-700")
    el.classList.add(ok ? "text-emerald-600" : "text-red-600")
  }
}
