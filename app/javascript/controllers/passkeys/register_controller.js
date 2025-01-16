import { Controller } from "@hotwired/stimulus"

import * as WebAuthnJSON from "@github/webauthn-json"
import { FetchRequest } from "@rails/request.js"

// Connects to data-controller="passkeys--register"
export default class extends Controller {
  static targets = ["nickname", "form"]
  static values = { callback: String }

  connect() {
    this.formTarget.addEventListener("submit", this.handleSubmit.bind(this))
  }

  async handleSubmit(event) {
    event.preventDefault()

    const request = new FetchRequest("post", this.formTarget.action, {
      responseKind: "json"
    })

    const response = await request.perform()
    if (response.ok) {
      const data = await response.json
      this.initiateWebAuthn(data)
    }
  }

  async initiateWebAuthn(data) {
    try {
      const credential = await WebAuthnJSON.create({ "publicKey": data })
      const request = new FetchRequest("post", this.callbackValue + `?nickname=${this.nicknameTarget.value}`, {
        body: JSON.stringify(credential)
      })
      const response = await request.perform()
      if (response.ok) {
        window.location.href = "/users/settings"
      }
    } catch (error) {
      console.log("There was a problem with the authentication request", error)
    }
  }

  error(event) {
    console.log("There was a problem with the authentication request", event)
  }
}