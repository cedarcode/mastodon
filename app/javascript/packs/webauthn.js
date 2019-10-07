import axios from 'axios';
import * as WebAuthnJSON from "@github/webauthn-json";
import ready from '../mastodon/ready';

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
    window.location.replace(response.data["redirect_path"]);
  }).catch(function(error) {
    window.location.reload();
    console.log(error);
  });
}

ready(() => {
  const registration_form = document.getElementById('new_webauthn_credential');
  if (registration_form) {
    registration_form.addEventListener('submit', (event) => {
      event.preventDefault();

      var nickname = event.target.querySelector("input[name='new_webauthn_credential[nickname]']");
      if (!nickname.value) {
        nickname.focus()
        return false
      }

      axios.get('/settings/two_factor_authentication/security_keys/options')
        .then((response) => {
          const credentialOptions = response.data;

          WebAuthnJSON.create({ "publicKey": credentialOptions }).then((credential) => {
            var params = { "credential": credential, "nickname": nickname.value }
            callback('/settings/two_factor_authentication/security_keys', params)
          }).catch((error) => {
            console.log(error);
          });
        })
    });
  }

  const authentication_form = document.getElementById('edit_user');
  if (authentication_form) {
    authentication_form.addEventListener('submit', (event) => {
      event.preventDefault();

      axios.get('sessions/security_key_options')
        .then((response) => {
          const credentialOptions = response.data;

          WebAuthnJSON.get({ "publicKey": credentialOptions }).then((credential) => {
            callback("sign_in", { "credential": credential });
          }).catch((error) => {
            console.log(error);
          });
        })
    });
  }
});
