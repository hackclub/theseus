# == Schema Information
#
# Table name: addresses
#
#  id           :bigint           not null, primary key
#  city         :string
#  country      :integer
#  email        :string
#  first_name   :string
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
#  index_addresses_on_batch_id  (batch_id)
#
# Foreign Keys
#
#  fk_rails_...  (batch_id => batches.id)
#
class Address < ApplicationRecord
  include CountryEnumable
  has_country_enum

  validates_presence_of :first_name, :line_1, :city, :state, :postal_code, :country

  def name_line
    [ first_name, last_name ].join(" ")
  end

  def us_format
  <<~EOA
  #{name_line}
  #{[ line_1, line_2 ].compact_blank.join("\n")}
  #{city}, #{state} #{postal_code}
  #{country}
  EOA
  end

  def us?
    country == "US"
  end

  def snailify
    Snail.new(
      name: name_line,
      line_1:,
      line_2:,
      city:,
      region: state,
      postal_code:,
      country: country
    )
  end
end
