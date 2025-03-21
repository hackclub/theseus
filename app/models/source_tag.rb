# == Schema Information
#
# Table name: source_tags
#
#  id         :bigint           not null, primary key
#  name       :string
#  owner      :string
#  slug       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class SourceTag < ApplicationRecord
  def self.web_tag
    @web_tag ||= find_by(slug: "theseus_web")
  end
  has_many :warehouse_orders, class_name: "Warehouse::Order"
end
