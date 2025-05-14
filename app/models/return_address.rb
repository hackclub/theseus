# == Schema Information
#
# Table name: return_addresses
#
#  id          :bigint           not null, primary key
#  city        :string
#  country     :integer
#  line_1      :string
#  line_2      :string
#  name        :string
#  postal_code :string
#  shared      :boolean
#  state       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :bigint
#
# Indexes
#
#  index_return_addresses_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class ReturnAddress < ApplicationRecord
  include CountryEnumable
  has_country_enum

  belongs_to :user, optional: true
  has_many :letters

  # Only validate if the record has at least some data (indicating user attempted to create one)
  with_options if: :partially_filled_out? do |address|
    address.validates_presence_of :name, :line_1, :city, :state, :postal_code, :country
  end

  scope :shared, -> { where(shared: true) }
  scope :owned_by, ->(user) { where(user: user) }

  # Add an attribute accessor for the from_letter parameter
  attr_accessor :from_letter

  def display_name
    "#{name} / #{line_1}"
  end

  def format_for_country(other_country)
    <<~EOA
      #{name}
      #{[line_1, line_2].compact_blank.join("\n")}
      #{city}, #{state} #{postal_code}
      #{country if country != other_country}
    EOA
      .strip
  end

  def location
    "#{city}, #{state} #{postal_code} #{country}"
  end

  def us?
    country == "US"
  end

  private

  # Return true if any fields have been filled out, indicating user's intent to create a return address
  def partially_filled_out?
    [name, line_1, city, state, postal_code].any?(&:present?)
  end
end
