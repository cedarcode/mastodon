# frozen_string_literal: true

module Admin
  class TwoFactorAuthenticationsController < BaseController
    before_action :set_target_user

    def destroy
      authorize @user, :disable_2fa?
      authorize @user, :disable_webauthn?
      @user.disable_two_factor!
      @user.disable_webauthn!
      log_action :disable_2fa, @user
      log_action :disable_webauthn, @user
      UserMailer.two_factor_disabled(@user).deliver_later!
      UserMailer.webauthn_disabled(@user).deliver_later!
      redirect_to admin_accounts_path
    end

    private

    def set_target_user
      @user = User.find(params[:user_id])
    end
  end
end
