import loadPolyfills from '../mastodon/load_polyfills';
import { start } from '../mastodon/common';
import React from 'react'
import axios from 'axios';
import * as WebAuthnJSON from "@github/webauthn-json"

start();

function loaded() {
  const ReactDOM          = require('react-dom');
  const mountNode         = document.getElementById('webauthn_form');

  if (mountNode !== null) {
    const props = JSON.parse(mountNode.getAttribute('data-props'));
    ReactDOM.render(<WebAuthnForm {...props} />, mountNode);
  }
}

function main() {
  const ready = require('../mastodon/ready').default;
  ready(loaded);
}

loadPolyfills().then(main).catch(error => {
  console.error(error);
});
main();

// ==============================================
function getCSRFToken() {
  var CSRFSelector = document.querySelector('meta[name="csrf-token"]')
  if (CSRFSelector) {
    return CSRFSelector.getAttribute("content")
  } else {
    return null
  }
}

function processCallback(url, options) {
  axios.post(
    url,
    JSON.stringify(options),
    { headers: {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "X-CSRF-Token": getCSRFToken()
    },
    credentials: 'same-origin'}
  ).then(function(response) {
    window.location.replace(response.data["redirect_path"]);
  })
}

class WebAuthnForm extends React.Component {
  constructor(props) {
    super(props);
    this.state = {nickname: ''};

    this.handleNicknameChange = this.handleNicknameChange.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
  }

  handleNicknameChange(event) {
    this.setState({nickname: event.target.value});
  }

  handleSubmit() {
    const nickname = this.state.nickname;
    const optionsUrl = this.props.optionsUrl;
    const callbackUrl = this.props.callbackUrl;

    axios.get(optionsUrl)
      .then(function(response) {
        const credentialOptions = response.data;

        WebAuthnJSON.create({ "publicKey": credentialOptions }).then(function(credential) {
          var params = {"credential": credential, "nickname": nickname}
          processCallback(callbackUrl, params)
        }).catch(function(error) {
          console.log(error);
        });
      })
  }

  render() {
    return(
      <form className="simple_form">
        <div className="input with_label string required credential_nickname">
          <div className="label_input">
            <label className="string required" htmlFor="credential_nickname">
                Nickname
              <abbr title="required">*</abbr>
            </label>
            <div className="label_input__wrapper">
              <input
                type="text"
                className="string required"
                name="credential[nickname]"
                id="credential_nickname"
                onChange={this.handleNicknameChange}
              />
              </div>
            </div>
          </div>
          <a className="block-button" onClick={this.handleSubmit}>
              Add security key
          </a>
        </form>
    );
  }
}
