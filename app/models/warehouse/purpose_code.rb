# == Schema Information
#
# Table name: warehouse_purpose_codes
#
#  id              :bigint           not null, primary key
#  code            :string
#  description     :string
#  sequence_number :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_warehouse_purpose_codes_on_code  (code)
#
class Warehouse::PurposeCode < ApplicationRecord
  def display_name
    "#{code} (#{description})"
  end
end
