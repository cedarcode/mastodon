Fabricator(:webauthn_credential) do
  user_id
  external_id
  public_key
  nickname 'Security key'
  sign_count 0
  last_used_on nil
end
