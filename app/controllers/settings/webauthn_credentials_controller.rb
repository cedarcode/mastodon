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
          flash[:success] = "Your security key was successfully deleted"
        else
          flash[:error] = "There was a problem deleting you security key. Please try again"
        end
      else
        flash[:error] = "We couldn't find your security key"
      end
      redirect_to settings_webauthn_credentials_url
    end
  end
end
