# frozen_string_literal: true

require "rails_helper"

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
