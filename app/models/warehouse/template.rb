# == Schema Information
#
# Table name: warehouse_templates
#
#  id            :bigint           not null, primary key
#  name          :string
#  public        :boolean
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  source_tag_id :bigint           not null
#  user_id       :bigint           not null
#
# Indexes
#
#  index_warehouse_templates_on_source_tag_id  (source_tag_id)
#  index_warehouse_templates_on_user_id        (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (source_tag_id => source_tags.id)
#  fk_rails_...  (user_id => users.id)
#
class Warehouse::Template < ApplicationRecord
  include HasWarehouseLineItems
  scope :shared, -> { where(public: true) }

  belongs_to :user
  belongs_to :source_tag
end
