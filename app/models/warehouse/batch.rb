# == Schema Information
#
# Table name: batches
#
#  id                          :bigint           not null, primary key
#  aasm_state                  :string
#  address_count               :integer
#  field_mapping               :jsonb
#  letter_height               :decimal(, )
#  letter_weight               :decimal(, )
#  letter_width                :decimal(, )
#  type                        :string           not null
#  warehouse_user_facing_title :string
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  letter_mailer_id_id         :bigint
#  user_id                     :bigint           not null
#  warehouse_purpose_code_id   :bigint
#  warehouse_template_id       :bigint
#
# Indexes
#
#  index_batches_on_letter_mailer_id_id        (letter_mailer_id_id)
#  index_batches_on_type                       (type)
#  index_batches_on_user_id                    (user_id)
#  index_batches_on_warehouse_purpose_code_id  (warehouse_purpose_code_id)
#  index_batches_on_warehouse_template_id      (warehouse_template_id)
#
# Foreign Keys
#
#  fk_rails_...  (letter_mailer_id_id => usps_mailer_ids.id)
#  fk_rails_...  (user_id => users.id)
#  fk_rails_...  (warehouse_purpose_code_id => warehouse_purpose_codes.id)
#  fk_rails_...  (warehouse_template_id => warehouse_templates.id)
#
class Warehouse::Batch < Batch
  belongs_to :warehouse_template, class_name: 'Warehouse::Template'
  belongs_to :warehouse_purpose_code, class_name: 'Warehouse::PurposeCode'

  has_many :orders, :class_name => 'Warehouse::Order'

  def self.model_name
    Batch.model_name
  end

  def process!(options = {})
    addresses.each do |address|
      Warehouse::Order.from_template(
        warehouse_template,
        batch: self,
        recipient_email: address.email,
        address: address,
        user: user,
        idempotency_key: "batch_#{id}_address_#{address.id}",
        purpose_code: warehouse_purpose_code,
        user_facing_title: warehouse_user_facing_title
      ).save!
    end
    orders.each do |order|
      order.dispatch!
    end
    mark_processed!
  end

  def contents_cost
    warehouse_template.contents_actual_cost_to_hc * addresses.count
  end

  def labor_cost
    warehouse_template.labor_cost * addresses.count
  end

  def postage_cost
    0
  end

  def total_cost
    contents_cost + labor_cost + postage_cost
  end
end 
