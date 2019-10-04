# frozen_string_literal: true

module Settings
  module TwoFactorAuthentication
    class WebauthnCredentialsController < BaseController
      layout 'admin'

      before_action :authenticate_user!
      before_action :require_otp_enabled
      before_action :require_webauthn_enabled, only: :destroy

      def new
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
            flash[:error] = I18n.t('webauthn_credentials.create.error')
            status = :internal_server_error
          end
        else
          flash[:error] = t('webauthn_credentials.create.error')
          status = :unauthorized
        end

        render json: { redirect_path: settings_two_factor_authentication_path }, status: status
      end

      def destroy
        credential = current_user.webauthn_credentials.find_by(id: params[:id])
        if credential
          credential.destroy
          if credential.destroyed?
            flash[:success] = I18n.t('webauthn_credentials.destroy.success')
          else
            flash[:error] = I18n.t('webauthn_credentials.destroy.error')
          end
        else
          flash[:error] = I18n.t('webauthn_credentials.destroy.error')
        end
        redirect_to settings_two_factor_authentication_path
      end

      def options
        current_user.update(webauthn_handle: WebAuthn.generate_user_id) unless current_user.webauthn_handle

        options_for_create = WebAuthn::Credential.options_for_create(
          user: {
            name: current_user.account.username,
            display_name: current_user.account.username,
            id: current_user.webauthn_handle,
          },
          exclude: current_user.webauthn_credentials.pluck(:external_id)
        )

        session[:webauthn_challenge] = options_for_create.challenge

        render json: options_for_create, status: :ok
      end

      private

      def require_otp_enabled
        if not current_user.otp_required_for_login
          flash[:error] = t('webauthn_credentials.otp_required')
          render json: { redirect_path: settings_two_factor_authentication_path }, status: :forbidden
        end
      end

      def require_webauthn_enabled
        if not current_user.webauthn_required_for_login?
          flash[:error] = t('webauthn_credentials.destroy.webatuhn_required')
          render json: { redirect_path: settings_two_factor_authentication_path }, status: :forbidden
        end
      end
    end
  end
end
