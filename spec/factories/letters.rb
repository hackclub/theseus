# == Schema Information
#
# Table name: letters
#
#  id                  :bigint           not null, primary key
#  aasm_state          :string
#  body                :text
#  created_via         :integer          default("manual"), not null
#  height              :decimal(, )
#  idempotency_key     :string
#  imb_rollover_count  :integer
#  imb_serial_number   :integer
#  indicia_error       :string
#  indicia_state       :string
#  mailed_at           :datetime
#  mailing_date        :date
#  metadata            :jsonb
#  non_machinable      :boolean
#  postage             :decimal(, )
#  postage_type        :integer
#  printed_at          :datetime
#  processing_category :integer
#  received_at         :datetime
#  recipient_email     :string
#  return_address_name :string
#  rubber_stamps       :text
#  tags                :citext           default([]), is an Array
#  user_facing_title   :string
#  weight              :decimal(, )
#  width               :decimal(, )
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  address_id          :bigint           not null
#  batch_id            :bigint
#  letter_queue_id     :bigint
#  return_address_id   :bigint           not null
#  user_id             :bigint           not null
#  usps_mailer_id_id   :bigint           not null
#
# Indexes
#
#  index_letters_on_aasm_state         (aasm_state)
#  index_letters_on_address_id         (address_id)
#  index_letters_on_batch_id           (batch_id)
#  index_letters_on_created_via        (created_via)
#  index_letters_on_idempotency_key    (idempotency_key) UNIQUE
#  index_letters_on_imb_serial_number  (imb_serial_number)
#  index_letters_on_letter_queue_id    (letter_queue_id)
#  index_letters_on_return_address_id  (return_address_id)
#  index_letters_on_tags               (tags) USING gin
#  index_letters_on_user_id            (user_id)
#  index_letters_on_usps_mailer_id_id  (usps_mailer_id_id)
#
# Foreign Keys
#
#  fk_rails_...  (address_id => addresses.id)
#  fk_rails_...  (batch_id => batches.id)
#  fk_rails_...  (letter_queue_id => letter_queues.id)
#  fk_rails_...  (return_address_id => return_addresses.id)
#  fk_rails_...  (user_id => users.id)
#  fk_rails_...  (usps_mailer_id_id => usps_mailer_ids.id)
#
FactoryBot.define do
  factory :letter do
    association :batch, factory: :letter_batch
    association :address
    association :user
    association :usps_mailer_id, factory: :usps_mailer_id
    association :return_address
    height { 4.125 }
    width { 9.5 }
    weight { 1 }
    processing_category { "letter" }
    postage_type { "stamps" }
    mailing_date { 1.week.from_now.to_date }
  end
end
