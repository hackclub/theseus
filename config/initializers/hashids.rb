Hashid::Rails.configure do |config|
  # The salt to use for generating hashid. Prepended with pepper (table name).
  config.salt = Rails.application.credentials[:hashid_salt]

  # The minimum length of generated hashids
  config.min_hash_length = 6

  # The alphabet to use for generating hashids
  config.alphabet = "cdefhjkmnprtvwxy2345689"

  # Whether to override the `find` method
  config.override_find = true

  # Whether to override the `to_param` method
  config.override_to_param = true

  # Whether to sign hashids to prevent conflicts with regular IDs (see https://github.com/jcypret/hashid-rails/issues/30)
  config.sign_hashids = true
end
