# == Schema Information
#
# Table name: addresses
#
#  id           :bigint           not null, primary key
#  city         :string
#  country      :integer
#  email        :string
#  first_name   :string
#  import_token :uuid
#  last_name    :string
#  line_1       :string
#  line_2       :string
#  phone_number :string
#  postal_code  :string
#  state        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  batch_id     :bigint
#
# Indexes
#
#  index_addresses_on_batch_id      (batch_id)
#  index_addresses_on_import_token  (import_token) WHERE (import_token IS NOT NULL)
#
# Foreign Keys
#
#  fk_rails_...  (batch_id => batches.id)
#
FactoryBot.define do
  factory :address do
    first_name { "Test" }
    last_name { "Person" }
    line_1 { "123 Main St" }
    city { "Burlington" }
    state { "VT" }
    postal_code { "05401" }
    country { "US" }
  end
end
