import { Controller } from "@hotwired/stimulus"

import * as WebAuthnJSON from "@github/webauthn-json"

// Connects to data-controller="passkeys--register"
export default class extends Controller {
  static targets = ["nickname"]
  static values = { callback: String }

  create(event) {
    const [data, status, xhr] = event.detail;
    const passkey_nickname = event.target.querySelector("input[name='passkey[nickname]']").value;
    const callback_url = `/passkeys/callback?passkey_nickname=${passkey_nickname}`

    WebAuthnJSON.create({ "publicKey": data }).then(function (passkey) {
      fetch(encodeURI(callback_url), {
        method: "POST",
        body: JSON.stringify(passkey),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').getAttribute("content")
        },
        credentials: 'same-origin'
      }).then(function (response) {
        if (response.ok) {
          window.location.replace("/")
        } else if (response.status < 500) {
          response.text();
        } else {
          showMessage("Sorry, something wrong happened.");
        }
      });
    }).catch(function (error) {
      showMessage(error);
    });

    console.log("Creating new public key credential...");

    WebAuthnJSON.create({ "publicKey": data }).then(async function (credential) {
      const request = fetch(_this.callbackValue)
    })
  }
}
