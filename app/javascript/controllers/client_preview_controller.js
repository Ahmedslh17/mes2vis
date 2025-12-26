// app/javascript/controllers/client_preview_controller.js
import { Controller } from "@hotwired/stimulus"

// Gère l'aperçu des infos client dans le formulaire de facture
export default class extends Controller {
  static values = { clients: Array }
  static targets = ["select", "details"]

  connect() {
    console.log("✅ client-preview connecté")
    console.log("clientsValue =", this.clientsValue)
    this.update()
  }

  change() {
    this.update()
  }

  update() {
    if (!this.hasSelectTarget || !this.hasDetailsTarget) return

    const clientId = this.selectTarget.value
    const client = this.clientsValue.find(c => String(c.id) === String(clientId))

    if (!client) {
      this.detailsTarget.innerHTML = `
        <p class="text-xs text-slate-400">
          Sélectionne un client à gauche pour afficher automatiquement son email et ses coordonnées ici.
        </p>
      `
      return
    }

    let lines = []
    lines.push(`
      <p class="text-xs font-medium uppercase tracking-wide text-slate-500 mb-1">
        Coordonnées du client
      </p>
    `)

    if (client.email) {
      lines.push(`
        <p>
          <span class="font-medium">Email :</span>
          ${this.escapeHtml(client.email)}
        </p>
      `)
    }

    const hasAddress =
      (client.address && client.address.length > 0) ||
      (client.zip_code && client.zip_code.length > 0) ||
      (client.city && client.city.length > 0)

    if (hasAddress) {
      let addr = client.address || ""
      let cityPart = ""
      if ((client.zip_code && client.zip_code.length > 0) || (client.city && client.city.length > 0)) {
        cityPart = ` — ${client.zip_code || ""} ${client.city || ""}`
      }

      lines.push(`
        <p>
          <span class="font-medium">Adresse :</span>
          ${this.escapeHtml(addr)}${this.escapeHtml(cityPart)}
        </p>
      `)
    }

    if (client.phone) {
      lines.push(`
        <p>
          <span class="font-medium">Téléphone :</span>
          ${this.escapeHtml(client.phone)}
        </p>
      `)
    }

    if (lines.length === 1) {
      lines.push(`
        <p class="text-xs text-slate-400">
          Aucune coordonnée enregistrée pour ce client pour l’instant.
        </p>
      `)
    }

    this.detailsTarget.innerHTML = lines.join("")
  }

  // Protection XSS simple
  escapeHtml(string) {
    if (!string) return ""
    return String(string)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;")
  }
}
