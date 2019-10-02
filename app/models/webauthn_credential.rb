# frozen_string_literal: true
# == Schema Information
#
# Table name: webauthn_credentials
#
#  id           :bigint(8)        not null, primary key
#  user_id      :bigint(8)
#  external_id  :string           not null
#  public_key   :text             not null
#  nickname     :string           not null
#  sign_count   :bigint(8)        default(0), not null
#  last_used_on :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class WebauthnCredential < ApplicationRecord
  validates :external_id, :public_key, :nickname, presence: true
  belongs_to :user
end
