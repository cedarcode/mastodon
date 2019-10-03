import * as axios from 'axios';
import * as WebAuthnJSON from "@github/webauthn-json";
import * as WebAuthnHelper from "./webauthn";

const form = document.getElementById('new_webauthn_credential');
form.addEventListener('submit', function(event) {
  event.preventDefault();

  var nickname = event.target.querySelector("input[name='new_webauthn_credential[nickname]']");
  if (!nickname.value) {
    nickname.focus()
    return false
  }

  axios.get('/settings/two_factor_authentication/security_keys/options')
    .then(function(response) {
      const credentialOptions = response.data;

      WebAuthnJSON.create({ "publicKey": credentialOptions }).then(function(credential) {
        var params = { "credential": credential, "nickname": nickname.value }
        WebAuthnHelper.callback('/settings/two_factor_authentication/security_keys', params)
      }).catch(function(error) {
        console.log(error);
      });
    })
});
