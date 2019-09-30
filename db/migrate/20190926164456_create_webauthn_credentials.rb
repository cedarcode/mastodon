class CreateWebauthnCredentials < ActiveRecord::Migration[5.2]
  def change
    create_table :webauthn_credentials do |t|
      t.references :user, foreign_key: true
      t.string :external_id, null: false
      t.text :public_key, null: false
      t.string :nickname, null: false
      t.bigint :sign_count, default: 0, null: false
      t.datetime :last_used_on

      t.timestamps
    end
  end
end
