import axios from 'axios';
import * as WebAuthnJSON from "@github/webauthn-json"

function getCSRFToken() {
  var CSRFSelector = document.querySelector('meta[name="csrf-token"]')
  if (CSRFSelector) {
    return CSRFSelector.getAttribute("content")
  } else {
    return null
  }
}

function callback(url, body) {
  axios.post(url, JSON.stringify(body), {
    headers: {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "X-CSRF-Token": getCSRFToken()
    },
    credentials: 'same-origin'
  }).then(function(response) {
    window.location.replace("/")
  });
}

const form = document.getElementById('edit_user');
form.addEventListener('submit', function(event) {
  event.preventDefault();

  axios.get('sessions/options').
    then(function(response) {
      const credentialOptions = response.data;

      WebAuthnJSON.get({ "publicKey": credentialOptions }).then(function(credential) {
        callback("sign_in", { "credential": credential });
      }).catch(function(error) {
        console.log(error);
      });
    })
});
