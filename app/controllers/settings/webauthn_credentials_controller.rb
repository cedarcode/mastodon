# frozen_string_literal: true

module Settings
  class WebauthnCredentialsController < BaseController
    layout 'admin'

    before_action :authenticate_user!

    def index
      @webauthn_credentials = current_user.webauthn_credentials
    end

    def destroy
      credential = current_user.webauthn_credentials.find_by(id: params[:id])
      if credential
        credential.destroy
        if credential.destroyed?
          flash[:success] = t(".success")
        else
          flash[:error] = t(".fail")
        end
      else
        flash[:error] = t(".not_found")
      end
      redirect_to webauthn_credentials_url
    end
  end
end
