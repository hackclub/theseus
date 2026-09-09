# frozen_string_literal: true

require "rails_helper"

# == Schema Information
#
# Table name: letter_queues
#
#  id                         :bigint           not null, primary key
#  include_qr_code            :boolean          default(TRUE)
#  letter_height              :decimal(, )
#  letter_mailing_date        :date
#  letter_processing_category :integer
#  letter_return_address_name :string
#  letter_weight              :decimal(, )
#  letter_width               :decimal(, )
#  name                       :string
#  postage_type               :string
#  slug                       :string
#  tags                       :citext           default([]), is an Array
#  template                   :string
#  type                       :string
#  user_facing_title          :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  hcb_payment_account_id     :bigint
#  letter_mailer_id_id        :bigint
#  letter_return_address_id   :bigint
#  user_id                    :bigint           not null
#  usps_payment_account_id    :bigint
#
# Indexes
#
#  index_letter_queues_on_hcb_payment_account_id    (hcb_payment_account_id)
#  index_letter_queues_on_letter_mailer_id_id       (letter_mailer_id_id)
#  index_letter_queues_on_letter_return_address_id  (letter_return_address_id)
#  index_letter_queues_on_type                      (type)
#  index_letter_queues_on_user_id                   (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (hcb_payment_account_id => hcb_payment_accounts.id)
#  fk_rails_...  (letter_mailer_id_id => usps_mailer_ids.id)
#  fk_rails_...  (letter_return_address_id => return_addresses.id)
#  fk_rails_...  (user_id => users.id)
#  fk_rails_...  (usps_payment_account_id => usps_payment_accounts.id)
#
RSpec.describe Letter::InstantQueue do
  let(:mailer_id) { create(:usps_mailer_id) }
  let(:return_address) { create(:return_address) }
  let(:user) { create(:user, can_use_indicia: true, home_mid: mailer_id, home_return_address: return_address) }
  let(:usps_account) { create(:usps_payment_account, usps_mailer_id: mailer_id) }

  def build_queue(billing_profile:)
    described_class.new(
      user: user,
      name: "q",
      slug: "q-#{SecureRandom.hex(4)}",
      template: "x",
      postage_type: "indicia",
      letter_height: 4,
      letter_width: 6,
      letter_weight: 1,
      letter_processing_category: 0,
      tags: [ "t" ],
      letter_mailer_id: mailer_id,
      letter_return_address: return_address,
      usps_payment_account: usps_account,
      billing_profile: billing_profile,
    )
  end

  describe "billing profile ownership" do
    it "is valid when the billing profile belongs to the queue's user" do
      queue = build_queue(billing_profile: create(:billing_profile, user: user))

      expect(queue).to be_valid
    end

    it "is invalid when the billing profile belongs to someone else" do
      queue = build_queue(billing_profile: create(:billing_profile, user: create(:user)))

      expect(queue).not_to be_valid
      expect(queue.errors[:billing_profile]).to include("must belong to the queue's user")
    end
  end
end
