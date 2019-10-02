# frozen_string_literal: true

module Settings
  class WebauthnCredentialsController < BaseController
    layout 'admin'

    before_action :authenticate_user!

    def index
      @webauthn_credentials = current_user.webauthn_credentials
    end

    def create
      webauthn_credential = WebAuthn::Credential.from_create(params[:credential])

      if webauthn_credential.verify(session[:webauthn_challenge])
        user_credential = current_user.webauthn_credentials.build(
          external_id: webauthn_credential.id,
          public_key: webauthn_credential.public_key,
          nickname: params[:nickname],
          sign_count: webauthn_credential.sign_count
        )

        if user_credential.save
          flash[:success] = I18n.t('webauthn_credentials.create.success')
          status = :ok
        else
          flash[:error] = I18n.t("webauthn_credentials.create.error")
          status = :internal_server_error
        end
      else
        flash[:error] = t("webauthn_credentials.create.error")
        status = :unauthorized
      end

      render json: { redirect_path: settings_webauthn_credentials_path }, status: status
    end

    def destroy
      credential = current_user.webauthn_credentials.find_by(id: params[:id])
      if credential
        credential.destroy
        if credential.destroyed?
          flash[:success] = I18n.t('webauthn_credentials.destroy.success')
        else
          flash[:error] = I18n.t("webauthn_credentials.destroy.error")
        end
      else
        flash[:error] = I18n.t("webauthn_credentials.destroy.error")
      end
      redirect_to settings_webauthn_credentials_url
    end

    def options
      current_user.update(webauthn_handle: WebAuthn.generate_user_id) unless current_user.webauthn_handle

      options_for_create = WebAuthn::Credential.options_for_create(
        user: {
          name: current_user.account.username,
          display_name: current_user.account.username,
          id: current_user.webauthn_handle
        },
        exclude: current_user.webauthn_credentials.pluck(:external_id)
      )

      session[:webauthn_challenge] = options_for_create.challenge

      render json: options_for_create, status: :ok
    end
  end
end
