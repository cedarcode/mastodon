import axios from 'axios';
import * as WebAuthnJSON from "@github/webauthn-json";
import * as WebAuthnHelper from "./webauthn";

const form = document.getElementById('edit_user');
form.addEventListener('submit', function(event) {
  event.preventDefault();

  axios.get('sessions/security_key_options')
    .then(function(response) {
      const credentialOptions = response.data;

      WebAuthnJSON.get({ "publicKey": credentialOptions }).then(function(credential) {
        WebAuthnHelper.callback("sign_in", { "credential": credential });
      }).catch(function(error) {
        console.log(error);
      });
    })
});
