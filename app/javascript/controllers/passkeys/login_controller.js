import AuthController from "./auth_controller"

// Connects to data-controller="passkeys--login"
export default class extends AuthController {
  static targets = ["password", "default", "passkey"]
  static values = {
    callback: String,
    passkey: String
  }

  connect() {
    this.passkey = true
    this.defaultActionUrl = this.element.getAttribute("action")
  }

  toggle(event) {
    event.preventDefault()
    this.passwordTarget.classList.toggle("is-hidden")
    this.defaultTarget.classList.toggle("is-hidden")
    this.passkeyTarget.classList.toggle("is-hidden")

    if (this.passkey) {
      this.element.setAttribute("data-remote", true)
      this.element.setAttribute("data-turbo", false)
      this.element.setAttribute("action", this.passkeyValue)
      this.passkey = false
    } else {
      this.element.setAttribute("data-remote", false)
      this.element.setAttribute("data-turbo", true)
      this.element.setAttribute("action", this.defaultActionUrl)
      this.passkey = true
    }
  }
}
