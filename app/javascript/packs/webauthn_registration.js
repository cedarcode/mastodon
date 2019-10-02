import * as axios from 'axios';
import * as WebAuthnJSON from "@github/webauthn-json";
import * as WebAuthnHelper from "./webauthn";

const form = document.getElementById('new_webauthn_credential');
form.addEventListener('submit', function(event) {
  event.preventDefault();

  axios.get('/api/webauthn_registration/options')
    .then(function(response) {
      const credentialOptions = response.data;

      WebAuthnJSON.create({ "publicKey": credentialOptions }).then(function(credential) {
        var nickname = event.target.querySelector("input[name='new_webauthn_credential[nickname]']").value;
        var params = {"credential": credential, "nickname": nickname}
        WebAuthnHelper.callback('/api/webauthn_registration', params)
      }).catch(function(error) {
        console.log(error);
      });
    })
});
