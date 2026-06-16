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
