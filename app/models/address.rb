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

  GREMLINS = [
    "\u200E", # LEFT-TO-RIGHT MARK
    "\u200B", # ZERO WIDTH SPACE
  ].join

  def self.strip_gremlins(str)
    str&.delete(GREMLINS)&.presence
  end

  validates_presence_of :first_name, :line_1, :city, :state, :postal_code, :country

  before_validation :strip_gremlins_from_fields

  def name_line
    [first_name, last_name].join(" ")
  end

  def us_format
    <<~EOA
      #{name_line}
      #{[line_1, line_2].compact_blank.join("\n")}
      #{city}, #{state} #{postal_code}
      #{country}
    EOA
  end

  def us?
    country == "US"
  end

  def snailify(origin = "US")
    SnailButNbsp.new(
      name: name_line,
      line_1:,
      line_2: line_2.presence,
      city:,
      region: state,
      postal_code:,
      country: country,
      origin: origin,
    ).to_s
  end

  private

  def strip_gremlins_from_fields
    self.first_name = Address.strip_gremlins(first_name)
    self.last_name = Address.strip_gremlins(last_name)
    self.line_1 = Address.strip_gremlins(line_1)
    self.line_2 = Address.strip_gremlins(line_2)
    self.city = Address.strip_gremlins(city)
    self.state = Address.strip_gremlins(state)
    self.postal_code = Address.strip_gremlins(postal_code)
  end
end
