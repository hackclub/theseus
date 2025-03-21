Norairrecord.api_key = Rails.application.credentials.dig(:airtable, :pat)
Norairrecord.user_agent = "Theseus (#{Rails.env})"
Norairrecord.base_url = ENV["AIRTABLE_BASE_URL"]
