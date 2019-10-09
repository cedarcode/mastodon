# frozen_string_literal: true

require 'rails_helper'
require 'webauthn/fake_client'

describe Settings::TwoFactorAuthentication::WebauthnCredentialsController do
  render_views

  let(:user) { Fabricate(:user) }
  let(:fake_client) { WebAuthn::FakeClient.new('http://test.host') }
  let(:original_nickname) { 'Security key' }

  def add_webauthn_credential(user)
    public_key_credential = WebAuthn::Credential.from_create(fake_client.create)
    Fabricate(:webauthn_credential,
              user_id: user.id,
              external_id: public_key_credential.id,
              public_key: public_key_credential.public_key,
              nickname: original_nickname)
  end

  describe 'GET /options #options' do
    context 'when signed in' do
      before do
        sign_in user, scope: :user
      end

      context 'when user requires webauthn for login already' do
        before do
          user.update(otp_required_for_login: true, webauthn_handle: WebAuthn.generate_user_id)
          add_webauthn_credential(user)
        end

        it 'returns http success' do
          get :options
          expect(response).to have_http_status(200)
        end

        it 'stores the challenge on the session' do
          get :options
          expect(@controller.session[:webauthn_challenge]).to be_present
        end

        it 'does not change webauthn handle' do
          before = user.webauthn_handle
          get :options

          expect(user.reload.webauthn_handle).to eq(before)
        end

        it "doesn't allow to add an existing credential" do
          get :options
          credential_id = JSON.parse(response.body)['excludeCredentials'][0]['id']
          expect(user.webauthn_credentials.pluck(:external_id)).to include(credential_id)
        end
      end

      context 'when user does not require webauthn for login' do
        context 'when otp is required for login' do
          before do
            user.update(otp_required_for_login: true)
          end

          it 'returns http success' do
            get :options
            expect(response).to have_http_status(200)
          end

          it 'sets webauthn handle' do
            get :options
            expect(user.reload.webauthn_handle).to be_present
          end
        end

        context 'when otp is not required for login' do
          it 'requires otp enabled first' do
            get :options
            expect(response).to have_http_status(403)
            expect(flash[:error]).to be_present
          end
        end
      end
    end

    context 'when not signed in' do
      it 'redirects' do
        get :options
        expect(response).to redirect_to '/auth/sign_in'
      end
    end
  end

  describe 'POST #create' do
    let(:nickname) { 'SecurityKeyNickname' }
    let(:challenge) do
      WebAuthn::Credential.options_for_create(
        user: { id: user.id, name: user.account.username, display_name: user.account.display_name }
      ).challenge
    end
    let(:new_webauthn_credential) { fake_client.create(challenge: challenge) }

    context 'when signed in' do
      before do
        sign_in user, scope: :user
      end

      context 'when user requires webauthn for login already' do
        before do
          user.update(otp_required_for_login: true, webauthn_handle: WebAuthn.generate_user_id)
          add_webauthn_credential(user)
        end

        context 'when creation succeeds' do
          it 'returns http success' do
            @controller.session[:webauthn_challenge] = challenge
            post :create, params: { credential: new_webauthn_credential, nickname: nickname }
            expect(response).to have_http_status(200)
          end

          it 'adds a new credential' do
            @controller.session[:webauthn_challenge] = challenge
            post :create, params: { credential: new_webauthn_credential, nickname: nickname }
            expect(user.webauthn_credentials.count).to eq(2)
          end

          it 'does not change webauthn handle' do
            before = user.webauthn_handle
            @controller.session[:webauthn_challenge] = challenge
            post :create, params: { credential: new_webauthn_credential, nickname: nickname }

            expect(user.reload.webauthn_handle).to eq(before)
          end
        end

        context 'when the nickname is already used' do
          it 'fails' do
            @controller.session[:webauthn_challenge] = challenge
            post :create, params: { credential: new_webauthn_credential, nickname: original_nickname }
            expect(response).to have_http_status(500)
          end

          it 'sets flash error' do
            @controller.session[:webauthn_challenge] = challenge
            post :create, params: { credential: new_webauthn_credential, nickname: original_nickname }
            expect(flash[:error]).to be_present
          end
        end

        context 'when the credential already exists' do
          before do
            user2 = Fabricate(:user)
            public_key_credential = WebAuthn::Credential.from_create(new_webauthn_credential)
            Fabricate(:webauthn_credential,
                      user_id: user2.id,
                      external_id: public_key_credential.id,
                      public_key: public_key_credential.public_key)
          end

          it 'fails' do
            @controller.session[:webauthn_challenge] = challenge
            post :create, params: { credential: new_webauthn_credential, nickname: nickname }
            expect(response).to have_http_status(500)
          end

          it 'sets flash error' do
            @controller.session[:webauthn_challenge] = challenge
            post :create, params: { credential: new_webauthn_credential, nickname: original_nickname }
            expect(flash[:error]).to be_present
          end
        end
      end

      context 'when user does not require webauthn for login' do
        context 'when otp is required for login' do
          before do
            user.update(otp_required_for_login: true)
          end

          it 'creates a webauthn credential' do
            @controller.session[:webauthn_challenge] = challenge
            post :create, params: { credential: new_webauthn_credential, nickname: nickname }
            expect(user.webauthn_credentials.count).to eq(1)
          end

          it 'now requires webauthn for login' do
            @controller.session[:webauthn_challenge] = challenge
            post :create, params: { credential: new_webauthn_credential, nickname: nickname }
            expect(user.webauthn_required_for_login?).to be true
          end
        end

        context 'when otp is not required for login' do
          it 'requires otp enabled first' do
            post :create, params: { credential: new_webauthn_credential, nickname: nickname }
            expect(response).to have_http_status(403)
            expect(flash[:error]).to be_present
          end
        end
      end
    end

    context 'when not signed in' do
      it 'redirects' do
        post :create, params: { credential: new_webauthn_credential, nickname: nickname }
        expect(response).to redirect_to '/auth/sign_in'
      end
    end
  end

  describe 'DELETE #destroy' do
    before do
      user.update(webauthn_handle: WebAuthn.generate_user_id)
      add_webauthn_credential(user)
    end

    context 'when signed in' do
      before do
        sign_in user, scope: :user
      end

      context 'when user requires webauthn for login already' do
        before do
          user.update(otp_required_for_login: true)
        end

        context 'when deletion succeeds' do
          it 'returns http success' do
            delete :destroy, params: { id: user.webauthn_credentials.take.id }
            expect(response).to redirect_to(settings_two_factor_authentication_path)
            expect(flash[:success]).to be_present
          end

          it 'deletes the credential' do
            delete :destroy, params: { id: user.webauthn_credentials.take.id }
            expect(user.webauthn_credentials.count).to eq(0)
          end

          context 'when user only had one credential' do
            it 'stops requiring webauthn for login' do
              delete :destroy, params: { id: user.webauthn_credentials.take.id }
              expect(user.webauthn_required_for_login?).to be false
            end
          end
        end
      end

      context 'when user does not require webauthn for login' do
        it 'is forbidden' do
          delete :destroy, params: { id: user.webauthn_credentials.take.id }
          expect(response).to have_http_status(403)
          expect(flash[:error]).to be_present
        end
      end
    end

    context 'when not signed in' do
      it 'redirects' do
        delete :destroy, params: { id: user.webauthn_credentials.take.id }
        expect(response).to redirect_to '/auth/sign_in'
      end
    end
  end
end
