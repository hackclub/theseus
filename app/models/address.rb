# == Schema Information
#
# Table name: addresses
#
#  id           :bigint           not null, primary key
#  city         :string
#  country      :integer
#  first_name   :string
#  last_name    :string
#  line_1       :string
#  line_2       :string
#  phone_number :string
#  postal_code  :string
#  state        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class Address < ApplicationRecord
  include CountryEnumable
  has_country_enum

  validates_presence_of :first_name, :line_1, :city, :state, :postal_code, :country

  def name_line
    [first_name, last_name].join(' ')
  end
end
