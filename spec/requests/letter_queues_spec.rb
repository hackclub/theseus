# frozen_string_literal: true

require "rails_helper"

RSpec.describe "letter queues", type: :request do
  let(:owner) { create(:user) }
  let(:admin) { create_admin }

  FORM_ENCODED = { "CONTENT_TYPE" => "application/x-www-form-urlencoded" }.freeze

  def build_instant_queue(user, **attrs)
    Letter::InstantQueue.create!(
      {
        user: user, name: "Instant queue", tags: [ "smoke" ],
        template: "hackatime_template", postage_type: "stamps",
        letter_height: 1, letter_width: 1, letter_weight: 1,
        letter_processing_category: "letter",
        letter_mailer_id: user.home_mid,
        letter_return_address: user.home_return_address
      }.merge(attrs)
    )
  end

  # Rack keeps the last value for a repeated key, which is what makes the order
  # of the hidden field and the checkbox matter.
  def instant_queue_body(*pairs)
    base = [
      [ "name", "Instant queue" ],
      [ "tags[]", "smoke" ],
      [ "template", "hackatime_template" ],
      [ "postage_type", "stamps" ],
      [ "letter_height", "1" ],
      [ "letter_width", "1" ],
      [ "letter_weight", "1" ],
      [ "letter_processing_category", "letter" ]
    ]
    (base + pairs).map { |k, v| "letter_instant_queue[#{CGI.escape(k)}]=#{CGI.escape(v.to_s)}" }.join("&")
  end

  before { fake_hcb! }

  describe "the QR code checkbox" do
    let(:queue) { build_instant_queue(owner, include_qr_code: true) }

    before { sign_in_as(owner) }

    it "saves an unchecked box as off" do
      patch letter_instant_queue_path(queue),
            params: instant_queue_body([ "include_qr_code", "0" ]),
            headers: FORM_ENCODED

      expect(queue.reload.include_qr_code).to be false
    end

    it "saves a checked box as on even though the hidden field shares its name" do
      queue.update!(include_qr_code: false)

      patch letter_instant_queue_path(queue),
            params: instant_queue_body([ "include_qr_code", "0" ], [ "include_qr_code", "1" ]),
            headers: FORM_ENCODED

      expect(queue.reload.include_qr_code).to be true
    end

    it "renders the hidden field before the checkbox" do
      get edit_letter_instant_queue_path(queue)

      hidden = response.body.index(%(type="hidden" name="letter_instant_queue[include_qr_code]"))
      box = response.body.index(%(type="checkbox" name="letter_instant_queue[include_qr_code]"))

      expect(hidden).not_to be_nil
      expect(box).not_to be_nil
      expect(hidden).to be < box
    end
  end
end
